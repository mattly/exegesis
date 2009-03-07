module Exegesis
  class Model
    module Validation
      
      def self.included base
        base.class_eval do
          include ValidationInstanceMethods
          
        end
      end
      
      module InstanceMethods
        def validate key, value, opts={}
          if opts.has_key?(:as)
            
          else
            error "must be present" if value.nil?
          end
        end
        
        def error message
          raise ArgumentError, message
        end
      end
    end
  end
end