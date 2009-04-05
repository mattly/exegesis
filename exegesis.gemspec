# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{exegesis}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Lyon"]
  s.date = %q{2009-04-04}
  s.description = %q{A Document <> Object Mapper for CouchDB Documents}
  s.email = %q{matt@flowerpowered.com}
  s.extra_rdoc_files = ["README.rdoc", "LICENSE"]
  s.files = ["README.rdoc", "VERSION.yml", "lib/exegesis", "lib/exegesis/database.rb", "lib/exegesis/design.rb", "lib/exegesis/document.rb", "lib/exegesis/model.rb", "lib/exegesis/server.rb", "lib/exegesis/utils", "lib/exegesis/utils/http.rb", "lib/exegesis.rb", "lib/monkeypatches", "lib/monkeypatches/time.rb", "test/database_test.rb", "test/design_test.rb", "test/document_test.rb", "test/fixtures", "test/fixtures/designs", "test/fixtures/designs/foos.js", "test/fixtures/designs/tags", "test/fixtures/designs/tags/views", "test/fixtures/designs/tags/views/by_tag", "test/fixtures/designs/tags/views/by_tag/map.js", "test/fixtures/designs/tags/views/by_tag/reduce.js", "test/http_test.rb", "test/model_test.rb", "test/server_test.rb", "test/test_helper.rb", "LICENSE"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/mattly/exegesis}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{TODO}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 0.12.6"])
    else
      s.add_dependency(%q<rest-client>, [">= 0.12.6"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 0.12.6"])
  end
end
