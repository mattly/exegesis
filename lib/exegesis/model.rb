module Exegesis
  module Model
    
    def self.included base
      base.extend ClassMethods
      base.send :include, InstanceMethods
      Exegesis.model_classes[base.name] = base
      base.send :attr_accessor, :attributes, :references, :parent
    end
    
    module ClassMethods
      def expose *attrs
        opts = attrs.last.is_a?(Hash) ? attrs.pop : {}
        [attrs].flatten.each do |attrib|
          attrib = attrib.to_s
          if opts[:writer]
            define_writer(attrib) {|val| @attributes[attrib] = opts[:writer].call(val) }
          elsif !opts.has_key?(:writer)
            define_writer(attrib) {|val| @attributes[attrib] = val }
          end
          if opts[:as] == :reference
            define_reference attrib
          elsif opts[:as]
            define_caster attrib, opts[:as]
          else
            define_method(attrib) { @attributes[attrib] }
          end
        end
      end
      
      # sets a default hash object for the attributes of the instances of the class if an argument given,
      # else retrieves the default
      def default hash=nil
        if hash
          @default = {}
          hash.each {|key, value| @default[key.to_s] = value }
        else
          @default ||= {}
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
      
      def define_caster attrib, as
        define_method(attrib) do
          @attributes[attrib] = if @attributes[attrib].is_a?(Array)
            @attributes[attrib].map {|val| cast as, val }.compact
          else
            cast as, @attributes[attrib]
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
        klass = if as == :given && value.is_a?(Hash)
          Exegesis.model_classes[value['class']]
        elsif as.is_a?(Class)
          as
        else
          nil
        end
        
        casted = if klass.nil?
          value # if no class, just return the value
        elsif klass == Time # Time is a special case; the ONLY special case.
          Time.parse value
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