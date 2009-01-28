require File.join(File.dirname(__FILE__), 'test_helper.rb')

class Foos < Exegesis::Design; end

class ExegesisDesignSyncronizationTest < Test::Unit::TestCase
  
  context "syncronizing with server" do
    before do
      reset_db "design_doc_sync"
      Foos.push_design!(@db)
      @get_design = lambda { @db.get('_design/foos') }
      @design = @get_design.call rescue nil
    end
    
    expect { @get_design.wont raise_error }
    expect { @design.has_key?('_rev').will be(true) }
    expect { @design.has_key?('language').will be(true) }
    expect { @design['language'].will == 'javascript' }
    expect { @design.has_key?('views').will be(true) }
    expect { @design['views'].has_key?('by_bar').will be(true) }
  end
  
  context "composing design docs from local sources" do
    before do
      Exegesis.set_designs_directory(fixtures_path('designs'))
      @design = Foos.compose_design
      @file = File.read(fixtures_path('designs/foos.js'))
      @jsdoc = Johnson.evaluate("v=#{@file}")
    end
    
    expect { @design.has_key?('_id').will be(true) }
    expect { @design['_id'].will == '_design/foos' }
    
    expect { @design.has_key?('views').will be(true) }
    expect { @design['views'].has_key?('by_bar').will be(true) }
    expect { @design['views']['by_bar'].has_key?('map').will be(true) }
    expect { @design['views']['by_bar']['map'].should == @jsdoc['views']['by_bar']['map'].toString }
  end
end