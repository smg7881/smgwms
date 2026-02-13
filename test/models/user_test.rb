require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user can be created" do
    user = User.new(email_address: "new@example.com", password: "password", password_confirmation: "password")
    assert user.valid?
  end

  test "email_address is required" do
    user = User.new(password: "password", password_confirmation: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "password is required" do
    user = User.new(email_address: "new@example.com")
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "duplicate email_address is rejected" do
    User.create!(email_address: "dup@example.com", password: "password", password_confirmation: "password")
    duplicate = User.new(email_address: "dup@example.com", password: "password", password_confirmation: "password")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "email_address is normalized to lowercase" do
    user = User.new(email_address: "  Admin@Example.COM  ", password: "password", password_confirmation: "password")
    user.validate
    assert_equal "admin@example.com", user.email_address
  end

  test "invalid email_address format is rejected" do
    user = User.new(email_address: "not-an-email", password: "password", password_confirmation: "password")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "is invalid"
  end
end
