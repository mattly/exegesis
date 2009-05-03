module Exegesis
  module Model
    
    JSON_PRIMITIVES = [Array, String, Hash, Fixnum, Float]
    
    def self.included base
      base.extend ClassMethods
      base.send :include, InstanceMethods
      base.send :attr_accessor, :attributes, :references, :parent
    end
    
    module ClassMethods
      def expose *attrs
        opts = attrs.last.is_a?(Hash) ? attrs.pop : {}
        raise ArgumentError, "casted keys cannot have defined writers" if opts[:as] && opts[:writer]
        [attrs].flatten.each do |attrib|
          attrib = attrib.to_s
          if opts[:writer]
            define_writer(attrib) {|val| @attributes[attrib] = opts[:writer].call(val) }
          elsif !opts.has_key?(:writer)
            define_writer(attrib) {|val| @attributes[attrib] = val }
          end
          if opts[:as] == :reference
            define_reference attrib
            define_reference_writer attrib unless opts[:writer] == false
          elsif opts[:as]
            define_caster attrib, opts[:as]
            define_caster_writer attrib, opts[:as] unless opts[:writer] == false
          else
            define_method(attrib) { @attributes[attrib] }
          end
        end
      end
      
      # sets a default hash object for the attributes of the instances of the class if an argument given,
      # else retrieves the default
      def default hash=nil
        if hash
          @default || default
          hash.each {|key, value| @default[key.to_s] = value }
        else
          @default ||= superclass.respond_to?(:default) ? superclass.default.dup : {}
        end
      end
      
      private
      def define_writer attrib, &block
        define_method("#{attrib}=", block)
      end
      
      def define_reference attrib
        define_method(attrib) do |*reload|
          reload = false if reload.empty?
          @references ||= {}
          @references[attrib] = nil if reload
          @references[attrib] ||= load_reference(@attributes[attrib])
        end
      end
      
      def define_reference_writer attrib
        define_writer(attrib) do |val|
          if val.is_a?(String)
            @attributes[attrib] = val
          elsif val.is_a?(Exegesis::Document)
            if val.rev && val.id
              @attributes[attrib] = val.id
            else
              raise ArgumentError, "cannot reference unsaved documents"
            end
          else
            raise ArgumentError, "was not a document or document id"
          end
        end
      end
      
      def define_caster attrib, as
        define_method(attrib) do
          @attributes[attrib] = if @attributes[attrib].is_a?(Array)
            @attributes[attrib].map {|val| cast as, val }.compact
          else
            cast as, @attributes[attrib]
          end
        end
      end
      
      def define_caster_writer attrib, as
        define_writer(attrib) do |val|
          @attributes[attrib] = if JSON_PRIMITIVES.include?(val.class)
            if val.is_a?(Array)
              val.map {|v| cast(as, v) }
            else
              cast(as, val)
            end
          else
            val
          end
        end
      end
    end
    
    module InstanceMethods
      def initialize hash={}
        apply_default
        hash.each {|key, value| @attributes[key.to_s] = value }
        @attributes['class'] = self.class.name
      end
      
      # works like Hash#update on the attributes hash, bypassing any writers
      def update hash={}
        hash.each {|key, value| @attributes[key.to_s] = value }
      end
      
      # update the attributes in the model using writers. If no writer is defined for a given
      # key it will raise NoMethodError
      def update_attributes hash={}
        hash.each do |key, value| 
          self.send("#{key}=", value)
        end
      end
      
      # retrieves the attribte
      def [] key
        @attributes[key]
      end
      
      # directly sets the attribute, avoiding any writers or lack thereof.
      def []= key, value
        @attributes[key] = value
      end
      
      # returns the instance's database, or its parents database if it has a parent.
      # If neither, returns false.
      # This is overwritten in classes including Exegesis::Document by an attr_accessor.
      def database
        parent && parent.database
      end
      
      private
      def apply_default
        @attributes = self.class.default.dup
      end
      
      def cast as, value
        return nil if value.nil?
        return value unless JSON_PRIMITIVES.include?(value.class)
        klass = if as == :given && value.is_a?(Hash)
          Exegesis.constantize(value['class'])
        elsif as.is_a?(Class)
          as
        else
          nil
        end
        
        casted = if klass.nil?
          value # if no class, just return the value
        elsif klass == Time # Time is a special case; the ONLY special case.
          value.empty? ? nil : Time.parse(value)
        else
          klass.new value
        end
        casted.parent = self if casted.respond_to?(:parent)
        casted
      end
      
      def load_reference ids
        raise ArgumentError, "a database is required for loading a reference" unless database
        if ids.is_a?(Array)
          ids.map {|val| database.get(val) }
        else
          database.get(ids)
        end
      end
    end
    
  end
end