$:.unshift File.dirname(__FILE__)
require 'design/syncronization'

module Exegesis
  class Design
    
    include Exegesis::Design::Syncronization
    
    attr_accessor :database
    
    def initialize(db)
      @database = db
    end
    
    def self.design_doc
      ActiveSupport::Inflector.pluralize(name.to_s.sub(/(Design)$/,'').downcase)
    end
    
    def design_doc
      self.class.design_doc
    end
    
    def get(id)
      Exegesis::Document.instantiate database.get(id)
    end
    
    def docs(view, opts={})
      if opts.kind_of?(Hash) && opts.has_key?(:starts_with)
        base = opts.delete(:starts_with)
        opts.update({:key => base.."#{base}\u9999"})
      elsif ! opts.kind_of?(Hash) || ([:key, :keys, :startkey, :endkey] & opts.keys).empty?
        opts = {:key => opts}
      end
      
      if opts[:key].is_a?(Range)
        range = opts.delete(:key)
        opts.update({:startkey => range.first, :endkey => range.last})
      end
      
      response = database.view view, opts.update({:include_docs => true})
      response['rows'].map {|doc| Exegesis::Document.instantiate doc['doc'] }
    end
  end
end