require 'rubygems'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

$CROWD_CONFIG_PATH = File.join(File.dirname(__FILE__), 'crowd_config.yml')

require 'simple_crowd'
require 'test/unit'
require 'shoulda'
require 'matchy'
require 'webmock/test_unit'
require 'rr'
require 'factory_girl'
require 'forgery'

# Load factories
require File.dirname(__FILE__) + "/factories"

WebMock.allow_net_connect!

class Test::Unit::TestCase
  include WebMock
  include RR::Adapters::TestUnit
  def setup
    WebMock.allow_net_connect!
  end
end
