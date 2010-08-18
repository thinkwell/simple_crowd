require 'helper'

class TestUser < Test::Unit::TestCase
  context 'A User' do
    setup do
      @user = Factory.build(:user)
    end
    should "track dirty properties" do
      @user.dirty_properties.should_not be nil
      @user.dirty_properties.empty?.should be true
      @user.dirty?.should be false
      oldname = @user.first_name
      @user.first_name = "Changed"
      @user.email = @user.email
      @user.dirty_properties.length.should == 1
      @user.dirty_properties.include?(:first_name).should be true
      @user.dirty?.should be true
      @user.property_dirty?(:first_name).should be true
      @user.property_dirty?(:last_name).should be false
      @user.property_dirty?(:email).should be false
    end

    should "test attributes" do
      @user.first_name = "Blah"
      @user.givenName.should == "Blah"
    end

    should "update with" do
      @user.dirty?.should be false
      @user.update_with(@user.merge({:first_name => @user.first_name, :last_name => "Updated"}))
      @user.dirty?.should be true
      @user.dirty_properties.length.should == 1
      @user.property_dirty?(:last_name).should be true
      @user.property_dirty?(:first_name).should be false
    end

    should "map to soap" do
      soap_user = @user.map_to :soap
      soap_user.should_not be nil
      soap_user[:attributes].key?('int:SOAPAttribute').should be true
      soap_user[:attributes]['int:SOAPAttribute'].length.should == @user.attributes.length
      soap_user[:name].should == @user.username
      soap_user[:attributes]['int:SOAPAttribute'].select{|a|a['int:name'] == :mail}[0]['int:values']['wsdl:string'].should == @user.email
      # Convert back and test equality
      obj_user = SimpleCrowd::User.parse_from :soap, soap_user
      obj_user.should == @user
      obj_user.dirty?.should be false
    end
  end
end