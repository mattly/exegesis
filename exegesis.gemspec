# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{exegesis}
  s.version = "0.2.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Lyon"]
  s.date = %q{2009-05-03}
  s.description = %q{A Document <> Object Mapper for CouchDB Documents}
  s.email = %q{matt@flowerpowered.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION.yml",
    "lib/exegesis.rb",
    "lib/exegesis/database.rb",
    "lib/exegesis/design.rb",
    "lib/exegesis/document.rb",
    "lib/exegesis/document/attachment.rb",
    "lib/exegesis/document/attachments.rb",
    "lib/exegesis/document/collection.rb",
    "lib/exegesis/document/generic_document.rb",
    "lib/exegesis/model.rb",
    "lib/exegesis/server.rb",
    "lib/exegesis/utils/http.rb",
    "lib/monkeypatches/time.rb",
    "test/attachments_test.rb",
    "test/database_test.rb",
    "test/design_test.rb",
    "test/document_collection_test.rb",
    "test/document_test.rb",
    "test/fixtures/attachments/flavakitten.jpg",
    "test/fixtures/designs/things/views/by_name/map.js",
    "test/fixtures/designs/things/views/by_tag/map.js",
    "test/fixtures/designs/things/views/by_tag/reduce.js",
    "test/fixtures/designs/things/views/for_path/map.js",
    "test/http_test.rb",
    "test/model_test.rb",
    "test/server_test.rb",
    "test/test_helper.rb",
    "test/view_option_parsing_test.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/mattly/exegesis}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.2}
  s.summary = %q{A Document <> Object Mapper for CouchDB Documents}
  s.test_files = [
    "test/attachments_test.rb",
    "test/database_test.rb",
    "test/design_test.rb",
    "test/document_collection_test.rb",
    "test/document_test.rb",
    "test/http_test.rb",
    "test/model_test.rb",
    "test/server_test.rb",
    "test/test_helper.rb",
    "test/view_option_parsing_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 0.9"])
    else
      s.add_dependency(%q<rest-client>, [">= 0.9"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 0.9"])
  end
end
