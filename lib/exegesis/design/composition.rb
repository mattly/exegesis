require 'johnson'

module Exegesis
  class Design
    module Composition
      
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        
        def compose_design
          js_doc = Johnson.evaluate("v = #{Exegesis.design_file(design_doc + '.js')}");
          views = js_doc['views'].entries.inject({}) do |memo, (name, mapreduce)|
            memo[name] = mapreduce.entries.inject({}) do |view, (name, func)|
              view[name] = func.toString
              view
            end
            memo
          end
          {'views' => views}
        end
        
      end
      
    end
  end
end