# Eventable - 모델 액션을 Event 레코드로 추적하는 Concern
#
# 이 Concern을 include한 모델은 중요한 동작이 발생할 때 track_event를 호출해
# Event 레코드를 생성할 수 있다. 생성된 Event는 활동 타임라인, 웹훅, 알림의
# 트리거로 활용된다.
#
# 사전 조건: Event 모델이 필요하다
#   - belongs_to :eventable, polymorphic: true
#   - belongs_to :creator  (사용자 모델)
#   - belongs_to :board    (워크스페이스 역할을 하는 모델)
#   - string  :action
#   - jsonb   :particulars  (또는 JSON 직렬화 text)
#
# 사용 예시:
#   class Post < ApplicationRecord
#     include Eventable
#
#     def publish!
#       update!(published_at: Time.current)
#       track_event("published")
#       # → Event.action = "post_published"
#     end
#   end
#
# 참고: Fizzy의 app/models/concerns/eventable.rb
module Eventable
  extend ActiveSupport::Concern

  included do
    # Event 레코드와 폴리모픽 연관을 맺는다.
    # 레코드가 삭제되면 관련 Event도 함께 삭제된다.
    has_many :events, as: :eventable, dependent: :destroy
  end

  # 이 레코드에 대한 Event를 생성한다.
  #
  # @param action [String] 발생한 동작 이름 (예: "published", "assigned")
  #   최종 Event.action은 "#{모델명}_#{action}" 형태가 된다 (예: "post_published")
  # @param creator [User] 동작을 수행한 사용자. 기본값: Current.user
  # @param board   [Board] 이 Event가 속하는 워크스페이스. 기본값: self.board
  # @param particulars [Hash] 동작에 대한 추가 데이터 (JSON으로 저장)
  #
  # 예시:
  #   track_event("assigned", assignee_id: user.id, assignee_name: user.name)
  def track_event(action, creator: Current.user, board: self.board, **particulars)
    if should_track_event?
      board.events.create!(
        action: "#{eventable_prefix}_#{action}",
        creator:,
        board:,
        eventable: self,
        particulars:
      )
    end
  end

  # Event 생성 후 호출되는 훅 메서드.
  # 필요 시 서브클래스(또는 Concern을 include한 모델)에서 오버라이드해 활용한다.
  def event_was_created(event)
  end

  private
    # 이벤트 추적 여부를 결정한다.
    # 특정 조건에서 이벤트를 억제하려면 including 모델에서 오버라이드한다.
    #
    # 예시:
    #   def should_track_event?
    #     published?  # 게시된 경우에만 이벤트 추적
    #   end
    def should_track_event?
      true
    end

    # Event.action에 사용할 모델 이름 접두사를 반환한다.
    # 네임스페이스를 제거하고 snake_case로 변환한다.
    # 예: "Cards::Comment" → "comment"
    def eventable_prefix
      self.class.name.demodulize.underscore
    end
end
