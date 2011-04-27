$:.push File.expand_path("../lib",__FILE__)
require 'simple_crowd/version'

Gem::Specification.new do |s|
  s.name = %q{simple_crowd}
  s.version = SimpleCrowd::VERSION.dup
  s.platform = Gem::Platform::RUBY
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Paul Strong"]
  s.description = %q{Simple Atlassian Crowd client using REST and SOAP APIs where needed.
                         Doesn't do any fancy object mapping, etc.}
  s.email = %q{paul@thestrongfamily.org}
  s.files = %w(
    .gitignore
    Gemfile
    README.md
    Rakefile
    lib/simple_crowd.rb
    lib/simple_crowd/client.rb
    lib/simple_crowd/crowd_entity.rb
    lib/simple_crowd/crowd_error.rb
    lib/simple_crowd/group.rb
    lib/simple_crowd/mappers/soap_attributes.rb
    lib/simple_crowd/mock_client.rb
    lib/simple_crowd/user.rb
    lib/simple_crowd/version.rb
    simple_crowd.gemspec
    test/crowd_config.yml.example
    test/factories.rb
    test/helper.rb
    test/test_client.rb
    test/test_simple_crowd.rb
    test/test_user.rb
  )
  s.test_files = %w(
    test/crowd_config.yml.example
    test/factories.rb
    test/helper.rb
    test/test_client.rb
    test/test_simple_crowd.rb
    test/test_user.rb
  )
  s.homepage = %q{http://github.com/lapluviosilla/simple_crowd}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.5.0}
  s.summary = %q{Simple Atlassian Crowd client using REST and SOAP APIs where needed.}

  s.add_development_dependency(%q<shoulda>, [">= 0"])
  s.add_development_dependency(%q<fcoury-matchy>, [">= 0"])
  s.add_development_dependency(%q<factory_girl>, [">= 0"])
  s.add_development_dependency(%q<forgery>, [">= 0"])
  s.add_development_dependency(%q<webmock>, [">= 0"])
  s.add_development_dependency(%q<rr>, [">= 0"])
  s.add_runtime_dependency(%q<savon>, ["= 0.7.9"])
  s.add_runtime_dependency(%q<hashie>, ["= 1.0.0"])
end

