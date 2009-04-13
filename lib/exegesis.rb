require 'time'
require 'pathname'
require 'restclient'
require 'json'

$:.unshift File.dirname(__FILE__) unless $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'monkeypatches/time'

module Exegesis
  autoload :Http,               'exegesis/utils/http'
                                
  autoload :Server,             'exegesis/server'
  autoload :Database,           'exegesis/database'
                                
  autoload :Model,              'exegesis/model'
  autoload :Document,           'exegesis/document'
  autoload :GenericDocument,    'exegesis/document/generic_document'
  
  autoload :Design,             'exegesis/design'
  autoload :DocumentCollection, 'exegesis/document/collection'
    
  extend self
  
  def model_classes
    @model_classes ||= {}
  end
  
  # extracted from Extlib
  #
  # Constantize tries to find a declared constant with the name specified
  # in the string. It raises a NameError when the name is not in CamelCase
  # or is not initialized.
  #
  # @example
  # "Module".constantize #=> Module
  # "Class".constantize #=> Class
  def constantize(camel_cased_word)
    return Exegesis::GenericDocument if camel_cased_word.nil?
    unless /\A(?:::)?([A-Z]\w*(?:::[A-Z]\w*)*)\z/ =~ camel_cased_word
      raise NameError, "#{camel_cased_word.inspect} is not a valid constant name!"
    end

    Object.module_eval("::#{$1}", __FILE__, __LINE__)
  end
  
  def instantiate(doc, database)
    doc = constantize(doc['class']).new(doc)
    doc.database = database if doc.respond_to?(:database=)
    doc
  end
  
end