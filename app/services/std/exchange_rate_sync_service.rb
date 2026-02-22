# app/services/std/exchange_rate_sync_service.rb
require "net/http"
require "uri"
require "json"
require "openssl"

module Std
  class ExchangeRateSyncService
    # 한국수출입은행 환율 오픈API 주소
    API_URL = "https://www.koreaexim.go.kr/site/program/financial/exchangeJSON"

    # KEXIM API 키
    # TODO: ENV['EXCHANGE_API_KEY'] 등으로 분리 권장 (여기서는 환경변수 미제공 시 테스트용 값을 쓰거나 에러처리)
    API_KEY = ENV.fetch("EXCHANGE_API_KEY", "YOUR_AUTH_KEY")

    def initialize(target_date = Date.current)
      @target_date = target_date.is_a?(String) ? Date.parse(target_date) : target_date
    end

    def call
      fetch_and_save_rates(@target_date)
    end

    private

    def fetch_and_save_rates(date, retry_count = 0)
      return if retry_count > 7 # 최대 7일 전(이전 영업일)까지만 스캔

      formatted_date = date.strftime("%Y%m%d")

      Rails.logger.info "[ExchangeRateSyncService] 수집 요청 시작 (일자: #{formatted_date})"

      response = call_api(formatted_date)

      # 비영업일(주말, 공휴일)에는 빈 배열이나 결과코드 에러가 반환될 수 있음
      if response.blank? || response.is_a?(Hash) # 에러 응답인 경우
        Rails.logger.info "[ExchangeRateSyncService] 수집 실패 또는 비영업일 (일자: #{formatted_date}). 이전 영업일 재탐색(#{retry_count + 1})..."
        return fetch_and_save_rates(date - 1.day, retry_count + 1)
      end

      # 응답 결과코드(result)가 1(성공)인 데이터만 필터링
      # (수출입은행 API 배열에서 각 객체 내 result 키 확인)
      valid_rates = response.select { |item| item["result"] == 1 }

      if valid_rates.empty?
        Rails.logger.info "[ExchangeRateSyncService] 정상 데이터 없음 (일자: #{formatted_date}). 이전 영업일 재탐색(#{retry_count + 1})..."
        return fetch_and_save_rates(date - 1.day, retry_count + 1)
      end

      # 데이터를 찾은 경우, 현재 @target_date를 기준으로 해당 환율정보를 저장(Upsert)
      saved_count = 0
      valid_rates.each do |rate_data|
        saved = upsert_rate_data(@target_date.strftime("%Y%m%d"), rate_data)
        saved_count += 1 if saved
      end

      Rails.logger.info "[ExchangeRateSyncService] 수집 및 저장 완료 (기준일자: #{@target_date.strftime("%Y%m%d")}, 스캔일자: #{formatted_date}, 저장건수: #{saved_count})"

      true
    rescue StandardError => e
      Rails.logger.error "[ExchangeRateSyncService] 예외 발생: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      false
    end

    def call_api(searchdate)
      # 개발/테스트 중 API KET가 없는 경우 더미(Dummy) 데이터를 반환
      if API_KEY == "YOUR_AUTH_KEY" || API_KEY.blank?
        Rails.logger.info "[ExchangeRateSyncService] API 키 미등록 상태 - 테스트용 더미(Dummy) 응답을 반환합니다."
        return dummy_api_response
      end

      uri = URI("#{API_URL}?authkey=#{API_KEY}&searchdate=#{searchdate}&data=AP01")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri)
      res = http.request(request)

      return nil unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
    rescue JSON::ParserError
      nil
    end

    def dummy_api_response
      [
        {
          "result" => 1,
          "cur_unit" => "USD",
          "cur_nm" => "미국 달러",
          "ttb" => "1,390.5",
          "tts" => "1,410.5",
          "deal_bas_r" => "1,400.5",
          "bkpr" => "1,400"
        },
        {
          "result" => 1,
          "cur_unit" => "EUR",
          "cur_nm" => "유로",
          "ttb" => "1,490.5",
          "tts" => "1,510.5",
          "deal_bas_r" => "1,500.5",
          "bkpr" => "1,500"
        },
        {
          "result" => 1,
          "cur_unit" => "JPY(100)",
          "cur_nm" => "일본 옌",
          "ttb" => "890.5",
          "tts" => "910.5",
          "deal_bas_r" => "900.5",
          "bkpr" => "900"
        }
      ]
    end

    def upsert_rate_data(std_ymd, data)
      # PK/UK 조합으로 데이터 검색 또는 초기화
      exchange_rate = StdExchangeRate.find_or_initialize_by(
        ctry_cd: "KR",                    # 기본 기준국가 한국
        fnc_or_cd: "KEXIM",               # 금융기관 한국수출입은행
        std_ymd: std_ymd,                 # 조회 당일(target_date)
        anno_dgrcnt: "FIRST",             # 1차(FIRST) 공시회차
        mon_cd: data["cur_unit"]          # 통화코드 (예: USD)
      )

      # API 응답 데이터를 매핑 (숫자의 콤마 제거 후 변환)
      exchange_rate.assign_attributes(
        sendmoney_sndg: parse_decimal(data["tts"]),
        sendmoney_rcvng: parse_decimal(data["ttb"]),
        tradg_std_rt: parse_decimal(data["deal_bas_r"]),
        convmoney_rt: parse_decimal(data["bkpr"]),
        if_yn_cd: "Y",
        use_yn_cd: "Y"
      )

      exchange_rate.save!
    end

    def parse_decimal(value)
      return nil if value.blank?

      value.to_s.gsub(",", "").to_f
    end
  end
end
