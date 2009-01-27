require 'rubygems'
require 'test/unit'

require 'rr'
require 'context'
require 'matchy'
require 'zebra'

require 'ruby-debug'
Debugger.start

$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'lib/exegesis'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
  
  def fixtures_path fixtures
    File.join(File.dirname(__FILE__), 'fixtures', fixtures)
  end
end