module Exegesis
  module Document
    
    def self.included base
      base.send :include, Exegesis::Model
      base.extend ClassMethods
      base.send :include, InstanceMethods
      base.send :attr_accessor, :database
    end

    module ClassMethods
      def timestamps!
        define_method :set_timestamps do
          @attributes['updated_at'] = Time.now
          @attributes['created_at'] ||= Time.now
        end
        expose 'updated_at', :as => Time, :writer => false
        expose 'created_at', :as => Time, :writer => false
      end
    
      def unique_id meth=nil, &block
        if block
          @unique_id_method = block
        elsif meth
          @unique_id_method = meth
        else
          @unique_id_method ||= nil
        end
      end
    end
    
    module InstanceMethods
      def initialize hash={}, db=nil
        super hash
        @database = db
      end
      
      def == other
        self.id == other.id
      end
      
      def id
        @attributes['_id']
      end
      
      def rev
        @attributes['_rev']
      end
      
      def save
        set_timestamps if respond_to?(:set_timestamps)
        if self.class.unique_id && id.nil?
          save_with_custom_unique_id
        else
          save_document
        end
      end
      
      def update_attributes attrs={}
        raise ArgumentError, 'must include a matching _rev attribute' unless (rev || '') == (attrs.delete('_rev') || '')
        super attrs
        save
      end
      
      private
      
      def save_document
        raise ArgumentError, "canont save without a database" unless database
        database.save self.attributes
      end
      
      def save_with_custom_unique_id
        attempt = 0
        value = ''
        begin
          @attributes['_id'] = if self.class.unique_id.is_a?(Proc)
            self.class.unique_id.call(self, attempt)
          else
            self.send(self.class.unique_id, attempt)
          end
          save_document
        rescue RestClient::RequestFailed => e
          oldvalue = value
          value = @attributes['_id']
          raise RestClient::RequestFailed if oldvalue == value || attempt > 100
          attempt += 1
          retry
        end
      end
    end
    
  end
end