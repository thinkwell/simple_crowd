require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'matchy'
require 'webmock/test_unit'
require 'rr'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'simple_crowd'

WebMock.allow_net_connect!

class Test::Unit::TestCase
  include WebMock
  include RR::Adapters::TestUnit
  def setup
    WebMock.allow_net_connect!
  end
end
