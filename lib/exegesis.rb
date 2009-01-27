require 'time'
require 'pathname'

require 'couchrest'
require 'active_support/inflector'

$:.unshift File.dirname(__FILE__)
require 'exegesis/document'
require 'exegesis/design'

module Exegesis
  
  def self.set_designs_directory dir
    @design_directory = Pathname.new(dir)
  end
  
  def self.design_file name
    @design_directory ||= Pathname.new(ENV["PWD"])
    File.read(@design_directory + name)
  end
  
end