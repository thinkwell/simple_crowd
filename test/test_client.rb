require 'helper'

class TestClient < Test::Unit::TestCase
  CROWD_CONFIG = YAML.load_file($CROWD_CONFIG_PATH)['crowd']
  context "A Client" do
    setup do
      @client = SimpleCrowd::Client.new({:service_url => CROWD_CONFIG['service_url'],
                                         :app_name => CROWD_CONFIG['app_name'],
                                         :app_password => CROWD_CONFIG['app_password']})
      @service_url = SimpleCrowd.soap_options({:service_url => CROWD_CONFIG['service_url']})[:service_url]
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
    should "refresh app token if invalid" do
      # Get initial valid token
      token = @client.app_token
      info = @client.get_cookie_info
      info.should_not be nil
      @client.app_token = token + "invalid"
      @client.app_token.should == token + "invalid"
      # making the token invalid should cause the client to refresh it
      # and get the cookie info successfully
      @client.get_cookie_info.should == info
      # Validate refreshed token is same as original token
      @client.app_token.should == token
      assert_requested :post, @service_url, :times => 5
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
    should "find all user names" do
      names = @client.find_all_user_names
      names.should_not be nil
      names.is_a?(Array).should be true
      names.empty?.should be false
      names.include?("test").should be true
    end
    should "find user by name" do
      user = @client.find_user_by_name "test"
      user.should_not be nil
      [:id, :username, :description, :active, :directory_id, :first_name, :last_name, :email].each {|v| user.key?(v).should be true}
      [:id, :username, :active, :directory_id].each {|v| user[v].should_not be nil}
      assert_requested :post, @service_url, :times => 2
    end
    should "find user by token" do
      token = @client.authenticate_user "test", "test"
      user = @client.find_user_by_token token
      user.should_not be nil
      user.first_name.should == "Test"

      assert_requested :post, @service_url, :times => 3
    end
    should "find username by token" do
      token = @client.authenticate_user "test", "test"
      user = @client.find_username_by_token token
      user.should_not be nil
      user.length.should > 0
      user.should == "test"

      assert_requested :post, @service_url, :times => 3
    end
    should "find user by email" do
      user = @client.find_user_by_email "test@testing.com"
      user.should_not be nil
      user.first_name.should == "Test"
      user.last_name.should == "User"

      # partial searches should return nothing
      user = @client.find_user_by_email "test"
      user.should be nil

      assert_requested :post, @service_url, :times => 3
    end
    should "search for users by email" do
      users = @client.search_users_by_email "test"
      users.empty?.should_not be true
      users.all?{|u| u.email =~ /test/ }.should be true

      assert_requested :post, @service_url, :times => 2
    end
    should "search users" do
      users = @client.search_users({'principal.email' => "test@testing.com"})
      users.should_not be nil
      users.empty?.should_not be true
      users.all?{|u| u.email == "test@testing.com" }.should be true

      users = @client.search_users({'principal.fullname' => "Test"})
      users.should_not be nil
      users.empty?.should_not be true
      users.all?{|u| u.first_name == "Test" }.should be true

      assert_requested :post, @service_url, :times => 3
    end
    should "return nil for nonexistant user" do
      user = @client.find_user_by_name "nonexistant"
      user.should be nil
      assert_requested :post, @service_url, :times => 2
    end
    should "update user credential" do
      @client.authenticate_user("test", "test").should_not be nil
      @client.update_user_credential("test", "testupdate").should be true
      lambda {@client.authenticate_user("test", "test")}.should raise_error
      @client.authenticate_user("test", "testupdate").should_not be nil
      @client.update_user_credential("test", "test").should be true
    end
    should "add/remove user" do
      localuser = Factory.build(:user)
      user = @client.add_user(localuser, "newuserpass")
      user.should_not be nil
      user.username.should == localuser.username
      user.first_name.should == localuser.first_name
      user.last_name.should == localuser.last_name
      @client.authenticate_user(localuser.username, "newuserpass").should_not be nil
      @client.remove_user(localuser.username).should be true
      lambda {@client.authenticate_user(localuser.username, "newuserpass")}.should raise_error

      assert_requested :post, @service_url, :times => 5
    end

    should "update user attribute" do
      username = "test_update"
      localuser = Factory.build(:user, :username => username)
      remoteuser = @client.add_user(localuser, "updatepass")
      @client.update_user_attribute(username, 'givenName', 'UpdatedFirst').should be true
      updateduser = @client.find_user_by_name(username)
      updateduser.last_name.should == localuser.last_name
      updateduser.first_name.should == 'UpdatedFirst'
      @client.remove_user "test_update"
    end
    should "update user custom attribute" do
      username = "test_update"
      localuser = Factory.build(:user, :username => username)
      remoteuser = @client.add_user(localuser, "updatepass")
      @client.update_user_attribute(username, 'customAttr', 'customVal').should be true
      remoteuser = @client.find_user_with_attributes_by_name username
      remoteuser.last_name.should == localuser.last_name

      remoteuser[:customAttr].should == 'customVal'
      @client.remove_user "test_update"
    end
    should "update user attribute array" do
      username = "test_update"
      localuser = Factory.build(:user, :username => username)
      remoteuser = @client.add_user(localuser, "updatepass")
      test_array = ["one", "two", "4"]
      @client.update_user_attribute(username, 'arrayTest', test_array).should be true
      remoteuser = @client.find_user_with_attributes_by_name username
      remoteuser.last_name.should == localuser.last_name
      remoteuser[:arrayTest].sort.should == test_array.sort
      test_array.delete "two"
      @client.update_user_attribute(username, 'arrayTest', test_array).should be true
      remoteuser = @client.find_user_with_attributes_by_name username
      remoteuser[:arrayTest].sort.should == test_array.sort
      remoteuser[:arrayTest].include?("two").should be false
      @client.remove_user "test_update"
    end
    should "update user" do
      username = "test_update"
      localuser = Factory.build(:user, :username => username)
      remoteuser = @client.add_user(localuser, "updatepass")
      remoteuser.should_not be nil
      remoteuser.username.should == localuser.username
      remoteuser.first_name.should == localuser.first_name
      remoteuser.last_name.should == localuser.last_name

      remoteuser.dirty?.should be false
      # Should be ignored
      remoteuser.active = false
      remoteuser.first_name = "UpdatedFirst"
      remoteuser.last_name = "UpdatedLast"
      remoteuser.dirty?.should be true

      remoteuser.dirty_attributes.should == [:first_name, :last_name]

      @client.update_user(remoteuser)

      remoteuser = @client.find_user_with_attributes_by_name username
      remoteuser.first_name.should == "UpdatedFirst"
      remoteuser.last_name.should == "UpdatedLast"
      remoteuser.email.should == localuser.email
      @client.remove_user "test_update"
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
    should "find group by name" do
      group = @client.find_group_by_name("Testing")
      group.should_not be nil
      assert_requested :post, @service_url, :times => 2
    end
    should "find all group names" do
      names = @client.find_all_group_names
      names.should_not be nil
      names.is_a?(Array).should be true
      names.empty?.should be false
      names.include?("Testing").should be true
    end
    should "add/remove user from group" do
      @client.add_user_to_group("test", "Testing").should be true
      @client.is_group_member?("Testing", "test").should be true
      @client.remove_user_from_group("test", "Testing").should be true
      @client.is_group_member?("Testing", "test").should be false
      assert_requested :post, @service_url, :times => 5
    end
#    should "add/remove attribute from group" do
#      @client.add_attribute_to_group("test", "tmpattribute", "Hello World").should be true
#      @client.remove_attribute_from_group("test", "tmpattribute").should be true
#    end
    should "update group" do
      @client.find_group_by_name("Testing").active.should be true
      @client.update_group("Testing", "Test Description", false).should be true
      updated_group = @client.find_group_by_name("Testing")
      updated_group.active.should be false
      updated_group.description.should == "Test Description"
      @client.update_group("Testing", "", true).should be true
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