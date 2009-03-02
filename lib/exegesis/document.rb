module Exegesis
  class Document < CouchRest::Document
    
    def self.inherited subklass
      Exegesis.document_classes[subklass.name] = subklass
    end
    
    def self.instantiate hash={}
      Exegesis.document_classes[hash['.kind']].new(hash)
    end
    
    def self.expose *attrs
      opts = if attrs.last.is_a?(Hash)
        attrs.pop
      else
        {}
      end
      
      [attrs].flatten.each do |attrib|
        attrib = "#{attrib}"
        if opts.has_key?(:writer)
          if opts[:writer]
            define_method("#{attrib}=") {|val| self[attrib] = opts[:writer].call(val) }
          end
        else
          define_method("#{attrib}=") {|val| self[attrib] = val }
        end
        if opts[:as]
          define_method(attrib) do
            self[attrib] = if self[attrib].is_a?(Array)
              self[attrib].map {|val| cast opts[:as], val }.compact
            else
              cast opts[:as], self[attrib]
            end
          end
        else
          define_method(attrib) { self[attrib] }
        end
      end
    end
    
    def self.default hash=nil
      if hash
        @default = hash
      else
        @default ||= superclass.respond_to?(:default) ? superclass.default : {}
      end
    end
    
    def self.timestamps!
      define_method :set_timestamps do
        self['updated_at'] = Time.now
        self['created_at'] ||= Time.now
      end
      expose 'updated_at', :as => Time, :writer => false
      expose 'created_at', :as => Time, :writer => false
    end
    
    def self.unique_id meth
      define_method :set_unique_id do
        self['_id'] = self.send(meth)
      end
    end
    
    alias :_rev :rev
    alias_method :document_save, :save
    
    def save
      set_timestamps if respond_to?(:set_timestamps)
      if respond_to?(:set_unique_id) && id.nil?
        @unique_id_attempt = 0
        begin
          self['_id'] = set_unique_id
          document_save
        rescue RestClient::RequestFailed => e
          @unique_id_attempt += 1
          retry
        end
      else
        document_save
      end
    end
    
    def initialize keys={}
      apply_default
      super keys
      self['.kind'] ||= self.class.to_s
    end
    
    def update_attributes attrs={}
      raise ArgumentError, 'must include a matching _rev attribute' unless rev == attrs.delete('_rev')
      attrs.each_pair do |key, value| 
        self.send("#{key}=", value) rescue nil
        attrs.delete(key)
      end
      save
    end
    
    private
    
    def apply_default
      self.class.default.each do |key, value|
        self[key] = value
      end
    end
    
    def cast as, value
      return nil if value.nil?
      klassname = value.is_a?(Hash) ? value['.kind'] : as
      klass = if klassname.is_a?(Class)
        klassname
      else
        Exegesis.document_classes[klassname]
      end
      with = klass == Time ? :parse : :new
      casted = klass.send with, value
      casted
    end
    
  end
end

# $:.unshift File.dirname(__FILE__)
# require 'document/annotated_reference'
# require 'document/referencing'