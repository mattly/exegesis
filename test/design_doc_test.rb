require File.join(File.dirname(__FILE__), 'test_helper.rb')

class FooDesign < Exegesis::Design
  view_by :foo
  view_by :foo, :bar
end
class CustomDesignDirDesign < Exegesis::Design
  designs_directory File.join(File.dirname(__FILE__), 'fixtures')
end


class ComposingDesignDocTest < Test::Unit::TestCase
  before(:all) { Exegesis.designs_directory = fixtures_path('designs') }
  
  context "setting a custom designs directory" do
    before do
      @custom_design_dir = File.join(File.dirname(__FILE__), 'fixtures')
    end
    
    expect { CustomDesignDirDesign.designs_directory.to_s.will == @custom_design_dir }
    
  end
  
  context "composing design docs from local sources" do
    before do
      @design = FooDesign.design_doc
      @file = File.read(fixtures_path('designs/foos.js'))
      @jsdoc = Johnson.evaluate("v=#{@file}")
    end
  
    expect { @design.has_key?('_id').will be(true) }
    expect { @design['_id'].will == '_design/foos' }
    expect { @design['views']['by_bar']['map'].will == @jsdoc['views']['by_bar']['map'].toString }
  end
  
  context "composing a design doc from view_by declarations" do
    before do
      @design = FooDesign.design_doc
      @by_foo = @design['views']['by_foo']['map']
      @by_foo_and_bar = @design['views']['by_foo_and_bar']['map']
    end
    
    expect { @by_foo.will include("if (doc['.kind'] == 'Foo' && doc['foo'])") }
    expect { @by_foo.will include("emit(doc['foo'], null);") }
    
    expect { @by_foo_and_bar.will include("if (doc['.kind'] == 'Foo' && doc['foo'] && doc['bar'])") }
    expect { @by_foo_and_bar.will include("emit([doc['foo'], doc['bar']], null)") }
  end
  
  context "building a hash a design doc" do
    before do
      @design = {
        'views' => {
          'a' => {'map' => 'some value', 'reduce' => 'some value'},
          'b' => {'map' => 'some value'}
        }
      }
      funcs = @design['views'].map{|name, view| "//view/#{name}/#{view['map']}/#{view['reduce']}" }.sort
      @hashed = Digest::MD5.hexdigest(funcs.join)
    end
    expect { FooDesign.hash_for_design(@design).will == @hashed }
  end

  context "syncronising with a databae" do
    before do
      reset_db
    end
    
    context "pushing design doc when it doesn't exist yet" do
      before do
        foo = FooDesign.new(@db)
        foo.push_design!
        @get_design = lambda { @db.get('_design/foos') }
        @design = @get_design.call rescue nil
      end

      expect { @get_design.wont raise_error }
      expect { @design['_rev'].will =~ /^[0-9]+$/ }
      expect { @design['language'].will == 'javascript' }
      expect { @design['views'].has_key?('by_bar').will be(true) }
    end

    context "reading the existing design document" do
      before do
        @db.save_doc(FooDesign.design_doc)
        @foo = FooDesign.new(@db)
      end

      expect { lambda {@foo.design_doc}.wont raise_error }
      expect { @foo.design_doc['_rev'].will =~ /^[0-9]+$/ }
      expect { @foo.design_doc['views'].keys.will == FooDesign.design_doc['views'].keys }
    end

    context "updating an existing doc" do

      context "when it hasn't changed" do
        before do
          @db.save_doc(FooDesign.design_doc)
          @foo = FooDesign.new(@db)
        end
        
        expect { lambda { @foo.push_design! }.wont change { @db.get('_design/foos')['_rev'] } }
      end

      context "when it has chagned" do
        before do
          @db.save_doc({'_id' => '_design/foos', 
            'views' => {'a' => {'map' => 'function(doc) { emit(true, null)}'}}
          })
          @foo = FooDesign.new(@db)
          @pushing = lambda{ @foo.push_design! }
        end

        expect { @pushing.will change { @db.get('_design/foos')['_rev'] } }
        expect { @pushing.call; @foo.design_doc_hash.will == FooDesign.design_doc_hash }
      end
    end
    
  end
end