require File.join(File.dirname(__FILE__), 'test_helper.rb')

class ExegesisTest < Test::Unit::TestCase
  
  context "designs directory" do
    context "defaults" do
      expect { Exegesis.designs_directory.will == ENV["PWD"] }
    end
    
    context "setting custom" do
      before do
        @custom_design_dir = File.join(File.dirname(__FILE__), 'fixtures', 'designs')
        Exegesis.designs_directory = @custom_design_dir
      end
      
      expect { Exegesis.designs_directory.will == @custom_design_dir }
    end
    
    
  end
  
  context "database template" do
    before do
      @template_string = "http://localhost:5984/appname-%s"
      @account = "foo"
      Exegesis.database_template = @template_string
    end
    
    expect { Exegesis.database_for(@account).will == @template_string % @account }
  end
  
end