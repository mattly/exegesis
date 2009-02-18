require File.join(File.dirname(__FILE__), '..', 'test_helper.rb')

class FooDesign < Exegesis::Design; end

class ComposingDesignDocTest < Test::Unit::TestCase
  before do
    Exegesis.designs_directory = fixtures_path('designs')
  end
  
  context "setting a custom designs directory" do
    before do
      @custom_design_dir = File.join(File.dirname(__FILE__), 'fixtures')
      FooDesign.designs_directory = @custom_design_dir
    end
    
    expect { FooDesign.designs_directory.to_s.will == @custom_design_dir }
  end
  
  context "composing design docs from local sources" do
    before do
      @design = FooDesign.design_doc
      @file = File.read(fixtures_path('designs/foos.js'))
      @jsdoc = Johnson.evaluate("v=#{@file}")
    end
  
    expect { @design.has_key?('_id').will be(true) }
    expect { @design['_id'].will == '_design/foos' }
    expect { @design['views']['by_bar'].has_key?('map').will be(true) }
    expect { @design['views']['by_bar']['map'].should == @jsdoc['views']['by_bar']['map'].toString }
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