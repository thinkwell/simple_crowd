require 'helper'

class TestUser < Test::Unit::TestCase
  context 'A User' do
    setup do
      @user = FactoryGirl.build(:user)
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
    end

    should "update with" do
      @user.dirty?.should be false
      @user.first_name = @user.first_name
      @user.dirty?.should be false
      @user.last_name = "Updated"
      @user.dirty?.should be true
      @user.dirty_properties.length.should == 1
      @user.dirty?(:last_name).should be true
      @user.dirty?(:first_name).should be false
    end

    should "map to soap" do
      soap_user = @user.to_soap
      soap_user.should_not be nil
      soap_user[:attributes].key?(:SOAPAttribute).should be true
      soap_user[:attributes][:SOAPAttribute].length.should == @user.class.attributes.length
      soap_user[:name].should == @user.username
      soap_user[:attributes][:SOAPAttribute].select{|a|a[:name] == :mail}[0][:values][:string].should == @user.email
    end
    should "parse from soap" do
      soap_user = {
        :id=>"-1",
        :active=>true,
        :attributes=>{
          :soap_attribute=>[
            {:name=>"givenName", :values=>{:string=>"parsefirstname"}},
            {:name=>"sn", :values=>{:string=>"parselastname"}},
            {:name=>"displayName", :values=>{:string=>"parsedisplayname"}},
            {:name=>"mail", :values=>{:string=>"test@thinkwell.com"}},
            {:name=>"customAttr", :values=>{:string => ["custom1", "custom2"]}}
          ],
          :@xmlns=>"http://soap.integration.crowd.atlassian.com"
        },
        :description=>{:@xmlns=>"http://soap.integration.crowd.atlassian.com"},
        :directory_id=>"32769",
        :name=>"testparse"
      }

      obj_user = SimpleCrowd::User.from_soap soap_user
      obj_user.should_not be_nil
      obj_user.active.should == true
      obj_user.first_name.should == "parsefirstname"
      obj_user.last_name.should == "parselastname"
      obj_user.display_name.should == "parsedisplayname"
      obj_user.email.should == "test@thinkwell.com"
      obj_user.description.should be_nil
      #obj_user.customAttr.should == ["custom1", "custom2"]
      #(obj_user.attributes_keys - [:first_name, :last_name, :display_name, :customAttr, :email]).empty?.should be true
    end

  end
end
