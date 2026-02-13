class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user

  def session=(value)
    super(value)
    self.user = value&.user
  end
end
