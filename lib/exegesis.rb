require 'time'
require 'pathname'
require 'restclient'
require 'json'

$:.unshift File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'monkeypatches/time'

module Exegesis
  autoload :Http,         'exegesis/utils/http'

  autoload :Server,       'exegesis/server'
  autoload :Database,     'exegesis/database'

  autoload :Model,        'exegesis/model'
  autoload :Document,     'exegesis/document'
  
  autoload :Designs,      'exegesis/designs'
  autoload :Design,       'exegesis/design'
  
  extend self
  
  def model_classes
    @model_classes ||= {}
  end
  
  def instantiate hash, database=nil
    return nil if hash.nil?
    klass = model_classes[hash['class']]
    obj = klass.nil? ? hash : klass.new(hash)
    obj.database = database if obj.respond_to?(:database=)
    obj
  end
  
end