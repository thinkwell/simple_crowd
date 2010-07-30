require 'helper'

class TestClient < Test::Unit::TestCase
  context "A Client" do
    setup do
      @service_url = "http://idp.thinkwell.com:8095/crowd/services/SecurityServer"
      @client = SimpleCrowd::Client.new({:service_url => @service_url, :app_name => "giraffe", :app_password => "test"})
      reset_webmock
    end
    should "initialize" do
      @client.should_not be nil
      assert_instance_of SimpleCrowd::Client, @client
    end
    should "get app token" do
      token = @client.app_token
      token.should_not be nil
      token.length.should == 24
      
      assert_requested :post, @service_url
    end
    should "get cookie info" do
      info = @client.get_cookie_info
      info.should_not be nil
      info[:domain].should_not be nil
      info[:domain].length.should > 0
      info[:secure].should_not be nil
      assert_requested :post, @service_url, :times => 2
    end
    should "authenticate user" do
      token = @client.authenticate_user "test", "test"
      token.should_not be nil
      token.length.should == 24

      assert_requested :post, @service_url, :times => 2
    end
    should "authenticate user with validation factors" do
      token = @client.authenticate_user "test", "test", {:test_factor => "test1234"}
      token.should_not be nil
      token.length.should == 24

      assert_requested :post, @service_url, :times => 2
    end
    should "create user token without password" do
      token = @client.create_user_token "test"
      token.should_not be nil
      token.length.should == 24

      assert_requested :post, @service_url, :times => 2
    end
    should "return same user token with or without password" do
      token_with_pass = @client.authenticate_user "test", "test"
      token_with_pass.should_not be nil
      token_with_pass.length.should == 24
      token_without_pass = @client.create_user_token "test"
      token_without_pass.should_not be nil
      token_with_pass.length.should == 24

      token_with_pass.should == token_without_pass

      assert_requested :post, @service_url, :times => 3
    end
    should "validate user token" do
      token = @client.authenticate_user "test", "test"
      valid = @client.is_valid_user_token? token
      valid.should be true
      invalid = @client.is_valid_user_token?(token + "void")
      invalid.should be false
      assert_requested :post, @service_url, :times => 4
    end
    should "validate user token with factors" do
      token = @client.authenticate_user "test", "test", {"Random-Number" => 6375}
      @client.is_valid_user_token?(token).should be false
      @client.is_valid_user_token?(token, {"Random-Number" => 6375}).should be true
      token2 = @client.authenticate_user "test", "test"
      @client.is_valid_user_token?(token2, {"Random-Number" => 48289}).should be false
      assert_requested :post, @service_url, :times => 6
    end
    should "invalidate user token (logout)" do
      token = @client.authenticate_user "test", "test"
      @client.is_valid_user_token?(token).should be true

      # Invalidate nonexistant token
      @client.invalidate_user_token(token + "void").should be true
      @client.is_valid_user_token?(token).should be true

      # Invalidate token
      @client.invalidate_user_token(token).should be true
      @client.is_valid_user_token?(token).should be false
      
      assert_requested :post, @service_url, :times => 7
    end
    should "reset user password" do
      # Get real app token before mocking reset call
      @client.app_token
      WebMock.disable_net_connect!

      response = %Q{<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
          xmlns:xsd="http://www.w3.org/2001/XMLSchema"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <soap:Body><ns1:resetPrincipalCredentialResponse xmlns:ns1="urn:SecurityServer" />
          </soap:Body></soap:Envelope>
      }
      stub_request(:post, @service_url).to_return(:body => response, :status => 200)
      
      @client.reset_user_password("test").should be true
    end
    should "find user by name" do
      user = @client.find_user_by_name "test"
      user.should_not be nil

      assert_requested :post, @service_url, :times => 2
    end
    should "find user by token" do
      token = @client.authenticate_user "test", "test"
      user = @client.find_user_by_token token
      user.should_not be nil
      user[:attributes][:soap_attribute].select {|v| v[:name] == "givenName"}.first[:values][:string].downcase.should == "test"

      assert_requested :post, @service_url, :times => 3
    end
    should "find user name by token" do
      token = @client.authenticate_user "test", "test"
      user = @client.find_user_name_by_token token
      user.should_not be nil
      user.length.should > 0
      user.downcase.should == "test"

      assert_requested :post, @service_url, :times => 3
    end
    should "check if cache enabled" do
      enabled = @client.is_cache_enabled?
      is_true = enabled.class == TrueClass
      is_false = enabled.class == FalseClass
      (is_true || is_false).should be true
    end
    should "get granted authorities" do
      granted = @client.get_granted_authorities
      (granted.nil? || (granted.is_a?(Array) && !granted.empty? && granted[0].is_a?(String))).should be true 

      assert_requested :post, @service_url, :times => 2
    end
    should "add/remove user from group" do
      @client.add_user_to_group("test", "Testing").should be true
      @client.is_group_member?("Testing", "test").should be true
      @client.remove_user_from_group("test", "Testing").should be true
      @client.is_group_member?("Testing", "test").should be false
      assert_requested :post, @service_url, :times => 5
    end
    should "check if user is group member" do
      @client.add_user_to_group("test", "Testing").should be true
      @client.is_group_member?("Testing", "test").should be true
      @client.is_group_member?("nonexistantgroup", "test").should be false
      assert_requested :post, @service_url, :times => 4
    end
    should "accept cached app token" do
      @client.app_token = "cachedtoken"
      @client.app_token.should == "cachedtoken"
      assert_not_requested :post, @service_url
    end
  end
end