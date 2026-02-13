# Notifiable - 레코드 생성 후 알림을 발송하는 Concern
#
# 이 Concern을 include한 모델은 생성 후 자동으로 관련 수신자에게 알림을 보낸다.
# 실제 발송은 NotifyRecipientsJob이 비동기로 처리한다.
#
# 사전 조건:
#   1. Notification 모델
#      - belongs_to :source, polymorphic: true
#   2. NotifyRecipientsJob
#      - def perform(notifiable) = notifiable.notify_recipients_now
#   3. Notifier 클래스 (또는 notify_recipients_now 직접 구현)
#      - Notifier.for(notifiable)&.notify
#
# 사용 예시:
#   class Comment < ApplicationRecord
#     include Notifiable
#     # 생성 후 자동으로 notify_recipients_later 호출됨
#   end
#
# 참고: Fizzy의 app/models/concerns/notifiable.rb
module Notifiable
  extend ActiveSupport::Concern

  included do
    # 알림 레코드와 폴리모픽 연관을 맺는다.
    # 레코드가 삭제되면 관련 Notification도 함께 삭제된다.
    has_many :notifications, as: :source, dependent: :destroy

    # 레코드 생성 후 트랜잭션이 커밋되면 알림 잡을 비동기로 실행한다.
    # after_create_commit을 사용해 DB에 실제로 저장된 후에만 잡이 큐에 추가된다.
    after_create_commit :notify_recipients_later
  end

  # 알림 발송 동기 버전.
  # NotifyRecipientsJob에서 직접 호출하거나, 테스트/디버깅 시 직접 호출한다.
  #
  # TODO: Notifier 클래스를 구현한 후 아래 주석을 해제하고 raise를 제거한다
  # 예시: Notifier.for(self)&.notify
  def notify_recipients_now
    raise NotImplementedError, "#{self.class.name}에서 notify_recipients_now를 구현하거나 Notifier 클래스를 제공하세요"
  end

  # 알림 링크가 가리킬 대상 객체를 반환한다.
  # 기본값은 self이며, 다른 객체로 이동해야 할 때 오버라이드한다.
  #
  # 예시 (댓글 알림을 카드 페이지로 이동):
  #   def notifiable_target
  #     card
  #   end
  def notifiable_target
    self
  end

  private
    # 알림 발송을 백그라운드 잡으로 비동기 처리한다.
    # 잡은 트랜잭션 커밋 후 실행되므로 레코드가 DB에 확실히 존재한다.
    def notify_recipients_later
      NotifyRecipientsJob.perform_later(self)
    end
end
