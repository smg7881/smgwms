require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "belongs to user" do
    session = Session.new(user: users(:one))
    assert_equal users(:one), session.user
  end

  test "generates token on create" do
    session = users(:one).sessions.create!
    assert_not_nil session.token
    assert session.token.length > 20
  end

  test "each session gets a unique token" do
    s1 = users(:one).sessions.create!
    s2 = users(:one).sessions.create!
    assert_not_equal s1.token, s2.token
  end

  test "token uniqueness is validated" do
    s1 = users(:one).sessions.create!
    s2 = Session.new(user: users(:one), token: s1.token)
    assert_not s2.valid?
    assert_includes s2.errors[:token], "has already been taken"
  end
end
