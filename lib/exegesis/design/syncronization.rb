require 'johnson'

module Exegesis
  class Design
    module Syncronization
      
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        
        def compose_design
          js_doc = Johnson.evaluate("v = #{Exegesis.design_file(design_doc + '.js')}");
          views = js_doc['views'].entries.inject({}) do |memo, (name, mapreduce)|
            memo[name] = mapreduce.entries.inject({}) do |view, (role, func)|
              view.update role => func.toString
            end
            memo
          end
          { '_id' => "_design/#{design_doc}",
            'language' => 'javascript',
            'views' => views
          }
        end
        
        def push_design!(db)
          doc = CouchRest::Document.new
          doc.database = db
          doc.update compose_design
          doc.save
        end
        
      end
      
    end
  end
end