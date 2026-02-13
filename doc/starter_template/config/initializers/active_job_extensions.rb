# frozen_string_literal: true

# AppActiveJobExtensions - 백그라운드 잡에 Account 컨텍스트를 자동 복원하는 확장
#
# Fizzy의 FizzyActiveJobExtensions 패턴을 기반으로 한다.
#
# 동작 방식:
#   1. 잡이 큐에 추가될 때 (initialize): Current.account를 @account에 캡처
#   2. 직렬화 시 (serialize): @account를 GlobalID로 직렬화해 잡 데이터에 포함
#   3. 역직렬화 시 (deserialize): GlobalID로 Account 레코드를 다시 로드
#   4. 실행 시 (perform_now): Current.with_account(account) 안에서 super 호출
#
# 이를 통해 잡 코드 어디서나 Current.account, Current.user를 안전하게 사용할 수 있다.
# 모든 잡에 account_id를 수동으로 전달하지 않아도 된다.
#
# TODO: AppActiveJobExtensions를 앱 이름에 맞게 변경한다
#   예: MyAppActiveJobExtensions, AcmeActiveJobExtensions
#
# 참고: Fizzy의 config/initializers/active_job.rb
module AppActiveJobExtensions
  extend ActiveSupport::Concern

  prepended do
    # account를 읽기 전용으로 외부에 노출 (직렬화/디버깅용)
    attr_reader :account

    # DB 트랜잭션이 커밋된 후에만 잡을 실행한다.
    # after_create_commit 콜백에서 잡을 큐에 추가할 때 경쟁 조건을 방지한다.
    # (트리거 레코드가 아직 보이지 않는 상태에서 잡이 실행되는 문제 방지)
    self.enqueue_after_transaction_commit = true
  end

  # 잡 인스턴스 생성 시 현재 요청의 account를 캡처한다.
  # 잡이 perform_later로 큐에 추가되는 시점의 컨텍스트를 보존한다.
  def initialize(...)
    super
    @account = Current.account
  end

  # 잡 데이터를 직렬화할 때 account를 GlobalID 형태로 포함한다.
  # GlobalID는 "gid://app/Account/uuid" 형태의 문자열로, DB에 저장 가능하다.
  def serialize
    super.merge({ "account" => @account&.to_gid })
  end

  # 잡 데이터에서 account GlobalID를 읽어 Account 레코드를 복원한다.
  # 레코드가 삭제된 경우 GlobalID::Locator.locate는 nil을 반환한다.
  def deserialize(job_data)
    super
    if _account = job_data.fetch("account", nil)
      @account = GlobalID::Locator.locate(_account)
    end
  end

  # 잡 실행 시 account 컨텍스트를 Current에 복원한 상태로 실행한다.
  # account가 없으면 (글로벌 잡) 컨텍스트 없이 그냥 실행한다.
  def perform_now
    if account.present?
      Current.with_account(account) { super }
    else
      super
    end
  end
end

# ActiveJob 로드 후 모든 잡 클래스에 확장을 prepend한다.
# prepend를 사용하므로 기존 perform_now, serialize 등을 오버라이드할 수 있다.
ActiveSupport.on_load(:active_job) do
  prepend AppActiveJobExtensions
end
