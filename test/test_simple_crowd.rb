require 'helper'

class TestSimpleCrowd < Test::Unit::TestCase
  should "return options" do
    options = SimpleCrowd.options
    options.should_not be nil
    options.empty?.should be false
    [:service_url, :service_ns, :service_namespaces, :app_name, :app_password].map{|s|options[s]}.each {|v| v.should_not be nil}
  end
end
