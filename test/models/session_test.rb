require "test_helper"

class SessionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @session = Session.new(user: @user)
  end

  test "should be valid with user" do
    assert @session.valid?
  end

  test "should require a user" do
    session = Session.new
    assert_not session.valid?
    assert_includes session.errors[:user], "must exist"
  end

  test "should allow valid ip addresses" do
    valid_ips = ["192.168.1.1", "10.0.0.1", "172.16.0.1", "2001:0db8:85a3:0000:0000:8a2e:0370:7334"]
    
    valid_ips.each do |ip|
      @session.ip_address = ip
      assert @session.valid?, "#{ip} should be a valid IP address"
    end
  end

  test "should reject invalid ip addresses" do
    invalid_ips = ["not-an-ip", "999.999.999.999", "::incorrect", "192.168.1"]
    
    invalid_ips.each do |ip|
      @session.ip_address = ip
      assert_not @session.valid?, "#{ip} should not be a valid IP address"
      assert_includes @session.errors[:ip_address], "must be a valid IPv4 or IPv6 address"
    end
  end

  test "should allow blank ip address" do
    @session.ip_address = ""
    assert @session.valid?
    
    @session.ip_address = nil
    assert @session.valid?
  end

  test "user_agent should not exceed maximum length" do
    @session.user_agent = "a" * 256
    assert_not @session.valid?
    assert_includes @session.errors[:user_agent], "is too long (maximum is 255 characters)"
    
    @session.user_agent = "a" * 255
    assert @session.valid?
  end
end
