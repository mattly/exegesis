require 'johnson'
require 'digest/md5'

module Exegesis
  class Design
    module Syncronization
      
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        def designs_directory dir=nil
          if dir
            @designs_directory = Pathname.new(dir)
          else
            @designs_directory || Exegesis.designs_directory
          end
        end
        
        def design_doc_path
          designs_directory + "#{design_doc_name}.js"
        end
        
        def design_doc
          js_doc = Johnson.evaluate("v = #{File.read(design_doc_path)}");
          views = js_doc['views'].entries.inject({}) do |memo, (name, mapreduce)|
            memo[name] = mapreduce.entries.inject({}) do |view, (role, func)|
              view.update role => func.toString
            end
            memo
          end
          { '_id' => "_design/#{design_doc_name}",
            'language' => 'javascript',
            'views' => views
          }
        end
        
        def design_doc_hash
          hash_for_design design_doc
        end
        
        def hash_for_design design
          funcs = design['views'].map do |name, view|
            "view/#{name}/#{view['map']}/#{view['reduce']}"
          end
          Digest::MD5.hexdigest(funcs.sort.join)
        end
        
      end
      
      def design_doc_hash
        design_doc.nil? ? '' : self.class.hash_for_design(design_doc)
      end
      
      def design_doc reload=false
        @design_doc = nil if reload
        @design_doc ||= database.get "_design/#{design_doc_name}" rescue nil
      end
      
      def push_design!
        return if design_doc_hash == self.class.design_doc_hash
        if design_doc
          design_doc.update(self.class.design_doc)
          design_doc.save
        else
          database.save_doc(self.class.design_doc)
        end
      end
    end
  end
end