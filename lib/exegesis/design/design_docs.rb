require 'johnson'
require 'digest/md5'

module Exegesis
  class Design
    module DesignDocs
      
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
          composite_views = declared_views.dup.update(views)
          { '_id' => "_design/#{design_doc_name}",
            'language' => 'javascript',
            'views' => composite_views
          }
        end
        
        def declared_views
          @declared_views ||= {}
        end
        
        def view_by *keys
          view_name = "by_#{keys.join('_and_')}"
          doc_keys = keys.map {|k| "doc['#{k}']" }
          declared_views[view_name] = {
            'map' => %|function(doc) {
              if (doc['.kind'] == '#{name.sub(/Design$/,'')}' && #{doc_keys.join(' && ')}) {
                emit(#{keys.length == 1 ? doc_keys.first : "[#{doc_keys.join(', ')}]" }, null);
              }
            }|
          }
          define_method view_name do |*args|
            docs_for view_name, *args
          end
        end
        
        def design_doc_hash
          hash_for_design design_doc
        end
        
        def hash_for_design design
          funcs = design['views'].map do |name, view|
            "//view/#{name}/#{view['map']}/#{view['reduce']}"
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