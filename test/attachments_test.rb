require File.join(File.dirname(__FILE__), 'test_helper.rb')

class AttachmentsDocumentTest
  include Exegesis::Document
end

class ExegesisAttachmentsTest < Test::Unit::TestCase
  before do
    reset_db
    @doc = AttachmentsDocumentTest.new({}, @db)
  end
  
  context "document methods" do
    expect { @doc.attachments.kind_of?(Exegesis::Document::Attachments).will == true }
    expect { @doc.attachments.size.will == 0 }
  end
  
  context "reading existing attachments" do
    before do
      @doc.save
      @text = "this is a file"
      RestClient.put("#{@db.uri}/#{@doc['_id']}/file.txt?rev=#{@doc['_rev']}", @text, {'Content-Type'=>'text/plain'})
      @doc = @db.get(@doc['_id'])
    end
    
    expect { @doc.attachments.size.will == 1 }
    expect { @doc.attachments.keys.will == %w(file.txt) }
    expect { @doc.attachments['file.txt'].content_type.will == 'text/plain' }
    expect { @doc.attachments['file.txt'].length.will == @text.length }
    expect { @doc.attachments['file.txt'].stub?.will == true }
    expect { @doc.attachments['file.txt'].file.will == @text }
  end
  
  context "writing attachments" do
    before do
      @doc.save
    end
    context "directly using attachments put" do
      context "with the file's contents as a string" do
        before do
          @contents = "this is the contents of a text file"
          @type = 'text/plain'
          @putting = lambda {|name, contents, type| @doc.attachments.put(name, contents, type) }
          @putting.call 'f.txt', @contents, @type
        end

        context "when they don't exist yet" do
          expect { RestClient.get("#{@doc.uri}/f.txt").will == @contents }
          expect { @doc.attachments['f.txt'].file.will == @contents }
          expect { @doc.rev.will == @db.raw_get(@doc.id)['_rev'] }
        end
      
        context "when they do exist" do
          before do
            @putting.call 'f.txt', "foo", @type
          end
          expect { @doc.attachments['f.txt'].file.will == "foo" }
        end
      end
      
      # it turns out rest-client doesn't actually support streaming uploads/downloads yet
      # context "streaming the file as a block given" do
      #   before do
      #     @file = File.open(fixtures_path('attachments/flavakitten.jpg'))
      #     @type = 'image/jpeg'
      #     @doc.attachments.put('kitten.jpg', @type) { @file.read }
      #   end
      #   
      #   expect { @doc.will satisfy(lambda{|e| e.attachments['kitten.jpg'].file == @file.read })}
      # end
    end
    
    context "indirectly, saved with the document" do
      before do
        @content = "this is an example file"
        @doc.attachments['file.txt'] = @content, 'text/plain'
      end
      
      expect { @doc.attachments['file.txt'].content_type.will == 'text/plain' }
      expect { @doc.attachments['file.txt'].metadata['data'].will == Base64.encode64(@content).gsub(/\s/,'') }
      expect { @doc.attachments['file.txt'].length.will == @content.length }
      expect { @doc.attachments.dirty?.will == true }
      
      context "when saving" do
        before do
          @doc.save
        end
        
        expect { @doc.attachments['file.txt'].file.will == @content }
        expect { @doc.attachments['file.txt'].stub?.will == true }
        expect { @doc.attachments['file.txt'].metadata.has_key?('data').will == false }
        expect { @doc.attachments.dirty?.will == false }
      end
    end
  end
  
  context "removing attachments" do
    context "from the document" do
      
    end
    
    context "directly from the database" do
      
    end
  end
end
