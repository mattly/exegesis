module Exegesis
  class Document < CouchRest::Document
    
    def self.instantiate hash={}
      ActiveSupport::Inflector.constantize(hash['.kind'] || 'Exegesis::Document').new(hash)
    end
    
    def self.cast field, opts={}
      unless opts.kind_of?(Hash) 
        raise ArgumentError
      end
      casts
      opts[:with] = :parse if opts[:as] == 'Time'
      opts[:with] ||= :new
      @casts[field.to_s] = opts
    end
    
    def self.casts
      @casts ||= superclass.respond_to?(:casts) ? superclass.casts : {}
    end
    
    def self.default hash=nil
      if hash
        @default = hash
      else
        @default ||= superclass.respond_to?(:default) ? superclass.default : {}
      end
    end
    
    def self.expose *attrs
      show attrs
      [attrs].flatten.each do |attrib|
        define_method("#{attrib}=") {|val| self["#{attrib}"] = val }
      end
    end
    
    def self.show *attrs
      [attrs].flatten.each do |attrib|
        define_method(attrib) { self["#{attrib}"] }
      end
    end
    
    def self.timestamps!
      define_method :set_timestamps do
        self['updated_at'] = Time.now
        self['created_at'] ||= Time.now
      end
      cast 'updated_at', :as => 'Time'
      cast 'created_at', :as => 'Time'
    end
    
    def self.unique_id meth
      define_method :set_unique_id do
        self['_id'] = self.send(meth)
      end
    end
    
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
      cast_keys
      self['.kind'] ||= self.class.to_s
    end
    
    def to_param
      self['_id']
    end
    
    private
    
    def apply_default
      self.class.default.each do |key, value|
        self[key] = value
      end
    end
    
    def cast_keys
      return unless self.class.casts
      self.class.casts.each do |key, pattern|
        next unless self[key]
        self[key] = if self[key].is_a?(Array)
          self[key].map {|val| class_for(pattern[:as], val['.kind']).send(pattern[:with], val) }
        else
          class_for(pattern[:as], self[key]['.kind']).send pattern[:with], self[key]
        end
      end
    end
    
    def class_for(as, kind)
      ActiveSupport::Inflector.constantize(as || kind || 'Exegesis::Document')
    end
    
  end
end