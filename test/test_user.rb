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
      @user.dirty?(:first_name).should be true
      @user.dirty?(:last_name).should be false
      @user.dirty?(:email).should be false
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
      @user.dirty?(:last_name).should be true
      @user.dirty?(:first_name).should be false
    end

    should "map to soap" do
      soap_user = @user.map_to :soap
      soap_user.should_not be nil
      soap_user[:attributes].key?('int:SOAPAttribute').should be true
      soap_user[:attributes]['int:SOAPAttribute'].length.should == @user.attributes.length
      soap_user[:name].should == @user.username
      soap_user[:attributes]['int:SOAPAttribute'].select{|a|a['int:name'] == :mail}[0]['int:values']['wsdl:string'].should == @user.email
    end
    should "parse from soap" do
      soap_user = {:name => "testparse", :active => true, :attributes => {:soap_attribute => [
        {:name => "givenName", :values => {:string => "parsefirstname"}},
        {:name => "sn", :values => {:string => "parselastname"}},
        {:name => "displayName", :values => {:string => "parsedisplayname"}},
        {:name => "customAttr", :values => {:string => ["custom1", "custom2"]}}
      ]}}
      obj_user = SimpleCrowd::User.parse_from :soap, soap_user
      obj_user.should_not be_nil
      obj_user.active.should == true
      obj_user.first_name.should == "parsefirstname"
      obj_user.last_name.should == "parselastname"
      obj_user.display_name.should == "parsedisplayname"
      obj_user.customAttr.should == ["custom1", "custom2"]
      (obj_user.attributes_keys - [:first_name, :last_name, :display_name, :customAttr, :email]).empty?.should be true
    end

    should "mark new props as atttributes" do
      curr_attributes = @user.attributes_keys
      @user[:new_prop] = "new value"
      (@user.attributes_keys - curr_attributes).should == [:new_prop]
    end

  end
end