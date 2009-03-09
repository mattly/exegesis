# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{exegesis}
  s.version = "0.0.10"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Lyon"]
  s.date = %q{2009-03-08}
  s.description = %q{TODO}
  s.email = %q{matt@flowerpowered.com}
  s.files = ["README.rdoc", "VERSION.yml", "lib/exegesis", "lib/exegesis/design", "lib/exegesis/design/design_docs.rb", "lib/exegesis/design.rb", "lib/exegesis/document.rb", "lib/exegesis.rb", "test/design_doc_test.rb", "test/design_test.rb", "test/document_class_definitions_test.rb", "test/document_instance_methods_test.rb", "test/exegesis_test.rb", "test/fixtures", "test/fixtures/designs", "test/fixtures/designs/foos.js", "test/test_helper.rb"]
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
      s.add_runtime_dependency(%q<jchris-couchrest>, [">= 0.12.6"])
    else
      s.add_dependency(%q<jchris-couchrest>, [">= 0.12.6"])
    end
  else
    s.add_dependency(%q<jchris-couchrest>, [">= 0.12.6"])
  end
end
