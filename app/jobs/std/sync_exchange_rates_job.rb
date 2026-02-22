# app/jobs/std/sync_exchange_rates_job.rb
module Std
  class SyncExchangeRatesJob < ApplicationJob
    queue_as :default

    # 주기적 스케줄링(Whenever, Sidekiq-Cron)으로 호출되거나
    # 특정 컨트롤러/화면에서 수동 배치 실행 버튼으로 트리거됨.
    def perform(target_date = Date.current.strftime("%Y%m%d"))
      Rails.logger.info "[SyncExchangeRatesJob] 환율 정보 배치 작업 시작 - #{Time.current}"

      service = Std::ExchangeRateSyncService.new(target_date)
      success = service.call

      if success
        Rails.logger.info "[SyncExchangeRatesJob] 환율 정보 배치 작업 성공 - #{Time.current}"
      else
        Rails.logger.error "[SyncExchangeRatesJob] 환율 정보 배치 작업 실패 - #{Time.current}"
      end
    end
  end
end
