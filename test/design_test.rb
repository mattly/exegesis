require File.join(File.dirname(__FILE__), 'test_helper.rb')

class Foos < Exegesis::Design; end
class FooDesign < Exegesis::Design; end

class TestForDesign < CouchRest::Document; end

class ExegesisDesignTest < Test::Unit::TestCase
  
  before do
    @db = Object.new
    @doc = Foos.new(@db)
  end
  
  expect { @doc.database.will == @db }
  expect { @doc.design_doc.will == "foos" }
  expect { FooDesign.new(@db).design_doc.will == "foos" }
  
  context "retrieving documents" do
    before do
      mock(@db).get('foo') { {'_id' => 'foo', "_rev" => '123', 'foo' => 'bar', '.kind' => 'TestForDesign'} }
      @obj = @doc.get('foo')
    end
    
    expect { @obj.will be_kind_of(TestForDesign) }
    expect { @obj['foo'].will == 'bar' }
  end
  
  context "retreiving views" do
    context "with docs" do
      
      before do
        @docs = [{'doc'=>{'.kind'=>'TestForDesign','foo' => 'bar'}}, {'doc'=>{'.kind'=>'TestForDesign','foo'=>'baz'}}]
      end

      context "for a simple key" do
        before do
          stub(@db).view(:bar, {:include_docs => true, :key => 'foo'}) { {'rows' => @docs} }
          @response = @doc.docs(:bar, 'foo')
        end
      
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 2 }
        expect { @response.each {|d| d.will be_kind_of(TestForDesign) }}
        expect { @response.each_with_index {|d, i| d['foo'].will == @docs[i]['doc']['foo'] }}
      end
      
      context "for an array key" do
        before do
          stub(@db).view(:bar, {:include_docs => true, :key => ['foo','ba']}) { {'rows' => @docs} }
          @response = @doc.docs(:bar, ['foo','ba'])
        end
      
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 2 }
        expect { @response.each {|d| d.will be_kind_of(TestForDesign) }}
        expect { @response.each_with_index {|d, i| d['foo'].will == @docs[i]['doc']['foo'] }}
      end
      
      context "for a hash key" do
        before do
          stub(@db).view(:bar, {:include_docs => true, :key => {'foo' => 'ba'}}) { {'rows' => @docs} }
          @response = @doc.docs(:bar, {'foo' => 'ba'})
        end
      
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 2 }
        expect { @response.each {|d| d.will be_kind_of(TestForDesign) }}
        expect { @response.each_with_index {|d, i| d['foo'].will == @docs[i]['doc']['foo'] }}
      end

      context "for a range" do
        before do
          stub(@db).view(:bar, {:include_docs => true, :startkey => 'bar', :endkey => 'baz'}) {{'rows' => @docs}}
          @response = @doc.docs(:bar, 'bar'..'baz')
        end
        
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 2 }
        expect { @response.each {|d| d.will be_kind_of(TestForDesign) }}
        expect { @response.each_with_index {|d, i| d['foo'].will == @docs[i]['doc']['foo'] }}
      end
      
      context "for a range with 'starts_with'" do
        before do
          stub(@db).view(:bar, {:include_docs => true, :startkey => 'bar', :endkey => "bar\u9999"}) {{'rows' => @docs}}
          @response = @doc.docs(:bar, :starts_with => 'bar')
        end
        
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 2 }
        expect { @response.each {|d| d.will be_kind_of(TestForDesign) }}
        expect { @response.each_with_index {|d, i| d['foo'].will == @docs[i]['doc']['foo'] }}
      end
      
    end
  end
  
  context "managing design docs" do
    context "retrieving design docs from server" do
      
    end
    
    
    context "syncronising with server" do
      
    end
  end
  
end