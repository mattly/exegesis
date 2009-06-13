module Exegesis
  module Document
    autoload :Attachments,  'exegesis/document/attachments'
    autoload :Attachment,   'exegesis/document/attachment'
    
    class MissingDatabaseError < StandardError; end
    class NewDocumentError < StandardError; end
    
    def self.included base
      base.send :include, Exegesis::Model
      base.extend ClassMethods
      base.send :include, InstanceMethods
      base.send :attr_accessor, :database
    end

    module ClassMethods
      def database(db=nil)
        if db 
          if db.is_a?(Exegesis::Database::Singleton) || db.is_a?(Exegesis::Database)
            @database = db
          else
            raise ArgumentError, "please supply either an Exegesis::Database or Exegesis::Database::Singleton"
          end
        else
          @database
        end
      end
      
      def timestamps!
        define_method :set_timestamps do
          @attributes['updated_at'] = Time.now
          @attributes['created_at'] ||= Time.now
        end
        expose 'updated_at', :as => Time
        expose 'created_at', :as => Time
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
        @database = db || self.class.database
      end
      
      def uri
        raise MissingDatabaseError if database.nil?
        raise NewDocumentError if rev.nil? || id.nil?
        "#{database.uri}/#{id}"
      end
      
      def reload
        raise NewDocumentError if rev.nil? || id.nil?
        raise MissingDatabaseError if database.nil?
        @attachments = nil
        @references = nil
        @attributes = database.raw_get(id)
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
        @attachments.clean! if @attachments && @attachments.dirty?
      end
      
      def update_attributes attrs={}
        raise ArgumentError, 'must include a matching _rev attribute' unless (rev || '') == (attrs.delete('_rev') || '')
        super attrs
        save
      end
      
      def attachments
        @attachments ||= Exegesis::Document::Attachments.new(self)
      end
      
      def _attachments= val
        @attributes['_attachments'] = val
      end
      
      def to_json
        @attributes.merge({'_attachments' => @attachments}).to_json
      end
      
      private
      
      def save_document
        raise ArgumentError, "canont save without a database" unless database
        database.save self
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