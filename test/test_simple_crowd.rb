require 'helper'

class TestSimpleCrowd < Test::Unit::TestCase
  context "with default keys" do
    setup do
      @default_keys = [:service_url, :service_ns, :service_namespaces, :app_name, :app_password]
    end
    should "return options" do
      options = SimpleCrowd.options
      options.should_not be nil
      options.empty?.should be false
      @default_keys.map{|s|options[s]}.each {|v| v.should_not be nil}
    end

    should "only have default options" do
      options = SimpleCrowd.options
      options.should_not be nil
      (options.keys - @default_keys).length.should == 0 
    end
  end
end
