require File.join(File.dirname(__FILE__), 'test_helper.rb')

class AttachmentsDocumentTest
  include Exegesis::Document
end

describe Exegesis::Document::Attachments do
  before do
    reset_db
    @doc = AttachmentsDocumentTest.new({}, @db)
  end
  
  describe "document methods" do
    expect { @doc.attachments.must_be_kind_of Exegesis::Document::Attachments }
    expect { @doc.attachments.size.must_equal 0 }
  end
  
  describe "reading existing attachments" do
    before do
      @doc.save
      @text = "this is a file"
      RestClient.put("#{@db.uri}/#{@doc['_id']}/file.txt?rev=#{@doc['_rev']}", @text, {'Content-Type'=>'text/plain'})
      @doc = @db.get(@doc['_id'])
    end
    
    expect { @doc.attachments.size.must_equal 1 }
    expect { @doc.attachments.keys.must_equal %w(file.txt) }
    expect { @doc.attachments['file.txt'].content_type.must_equal 'text/plain' }
    expect { @doc.attachments['file.txt'].length.must_equal @text.length }
    expect { assert @doc.attachments['file.txt'].stub? }
    expect { @doc.attachments['file.txt'].file.must_equal @text }
  end
  
  describe "writing attachments" do
    before do
      @doc.save
    end
    describe "directly using attachments put" do
      describe "with the file's contents as a string" do
        before do
          @contents = "this is the contents of a text file"
          @type = 'text/plain'
          @putting = lambda {|name, contents, type| @doc.attachments.put(name, contents, type) }
          @putting.call 'f.txt', @contents, @type
        end

        describe "when they don't exist yet" do
          expect { RestClient.get("#{@doc.uri}/f.txt").must_equal @contents }
          expect { @doc.attachments['f.txt'].file.must_equal @contents }
          expect { @doc.rev.must_equal @db.raw_get(@doc.id)['_rev'] }
        end
      
        describe "when they do exist" do
          before do
            @putting.call 'f.txt', "foo", @type
          end
          expect { @doc.attachments['f.txt'].file.must_equal "foo" }
        end
      end
      
      # it turns out rest-client doesn't actually support streaming uploads/downloads yet
      # describe "streaming the file as a block given" do
      #   before do
      #     @file = File.open(fixtures_path('attachments/flavakitten.jpg'))
      #     @type = 'image/jpeg'
      #     @doc.attachments.put('kitten.jpg', @type) { @file.read }
      #   end
      #   
      #   expect { lambda{|e| e.attachments['kitten.jpg'].file == @file.read }.must_be true }
      # end
    end
    
    describe "indirectly, saved with the document" do
      before do
        @content = "this is an example file"
        @doc.attachments['file.txt'] = @content, 'text/plain'
      end
      
      expect { @doc.attachments['file.txt'].content_type.must_equal 'text/plain' }
      expect { @doc.attachments['file.txt'].metadata['data'].must_equal Base64.encode64(@content).strip }
      expect { @doc.attachments['file.txt'].length.must_equal @content.length }
      expect { assert @doc.attachments.dirty? }
      
      describe "when saving" do
        before do
          @doc.save
        end
        
        expect { @doc.attachments['file.txt'].file.must_equal @content }
        expect { assert @doc.attachments['file.txt'].stub? }
        expect { refute @doc.attachments['file.txt'].metadata.has_key?('data') }
        expect { refute @doc.attachments.dirty? }
      end
    end
  end
  
  describe "removing attachments" do
    describe "from the document" do
      
    end
    
    describe "directly from the database" do
      
    end
  end
end
