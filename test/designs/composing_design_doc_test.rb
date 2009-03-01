require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

class FooDesign < Exegesis::Design
  view_by :foo
  view_by :foo_and_bar
end
class CustomDesignDirDesign < Exegesis::Design
  designs_directory File.join(File.dirname(__FILE__), 'fixtures')
end

class ComposingDesignDocTest < Test::Unit::TestCase
  before do
    Exegesis.designs_directory = fixtures_path('designs')
  end
  
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
    
    expect { @by_foo.will =~ "if (doc['.kind'] == 'Foo' && doc['foo'])" }
    expect { @by_foo.will =~ "emit(doc.foo, null);" }
    
    expect { @by_foo_and_bar.will =~ "if (doc['.kind'] == 'Foo' && doc['foo'] && doc['bar'])" }
    expect { @by_foo_and_bar.will =~ "emit([doc.foo, doc.bar], null)" }
  end
  
  context "building a hash a design doc" do
    before do
      @design = {
        'views' => {
          'a' => {'map' => 'some value', 'reduce' => 'some value'},
          'b' => {'map' => 'some value'}
        }
      }
      funcs = @design['views'].map{|name, view| "view/#{name}/#{view['map']}/#{view['reduce']}" }.sort
      @hashed = Digest::MD5.hexdigest(funcs.join)
    end
    expect { FooDesign.hash_for_design(@design).will == @hashed }
  end
end