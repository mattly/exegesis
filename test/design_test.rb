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
  
  context "retrieving documents with #get" do
    before do
      reset_db('design-views')
      @doc = Foos.new(@db)
      @db.save '_id' => 'foo', 'foo' => 'bar', '.kind' => 'TestForDesign'
      @obj = @doc.get('foo')
    end
    
    expect { @obj.will be_kind_of(TestForDesign) }
    expect { @obj['foo'].will == 'bar' }
  end
  
  context "retreiving views" do
    before do
      reset_db('design-views')
      @doc = Foos.new(@db)
      @raw_docs = [
        {'_id' => 'foo', 'foo' => 'bar', 'bar' => 'bee', '.kind' => 'TestForDesign'},
        {'_id' => 'bar', 'foo' => 'baz', 'bar' => 'bee', '.kind' => 'TestForDesign'},
        {'_id' => 'baz', 'foo' => 'foo', 'bar' => 'bee', '.kind' => 'TestForDesign'}
      ]
      @db.bulk_save @raw_docs
      @db.save({
        '_id' => '_design/foos',
        'views' => {
          'string' => { 'map'=>'function(doc) {emit(doc.foo, doc.bar);}' },
          'array' => {'map' => 'function(doc) {emit([doc.bar, doc.foo], doc.bar)}'},
          'hash' => {'map' => 'function(doc) {emit({foo: doc.foo}, doc.bar)}'}
        }
      })
    end
    
    context "with docs" do
      context "for a simple key" do
        before do
          @response = @doc.docs(:string, 'foo')
        end
      
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 1 }
        expect { @response.first.will be_kind_of(TestForDesign) }
        expect { @response.first['foo'].will == 'foo' }
      end
      
      context "for an array key" do
        before do
          @response = @doc.docs(:array, ['bee','foo'])
        end
      
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 1 }
        expect { @response.first.will be_kind_of(TestForDesign) }
        expect { @response.first['foo'].will == 'foo'}
      end
      
      context "for a hash key" do
        before do
          @response = @doc.docs(:hash, {'foo' => 'foo'})
        end
      
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 1 }
        expect { @response.first.will be_kind_of(TestForDesign) }
        expect { @response.first['foo'].will == 'foo' }
      end

      context "for a range" do
        before do
          @response = @doc.docs(:string, 'bar'..'baz')
        end
        
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 2 }
        expect { @response.each {|d| d.will be_kind_of(TestForDesign) }}
        expect { @response.first['foo'].will == 'bar' }
        expect { @response.last['foo'].will == 'baz' }
      end
      
      context "for a range with :starts_with" do
        before do
          @response = @doc.docs(:string, :starts_with => 'ba')
        end
        
        expect { @response.will be_kind_of(Array) }
        expect { @response.size.will == 2 }
        expect { @response.first.will be_kind_of(TestForDesign) }
        expect { @response.first['foo'].will == 'bar' }
        expect { @response.last['foo'].will == 'baz' }
      end
      
    end
    
    context "for the view's data" do
      before do
        # @docs = 
      end
    end 
  end
  
end