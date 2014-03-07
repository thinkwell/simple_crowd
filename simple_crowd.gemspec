# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'simple_crowd/version'

Gem::Specification.new do |s|
  s.name        = %q{simple_crowd}
  s.version     = SimpleCrowd::VERSION.dup
  s.authors     = ["Paul Strong"]
  s.email       = %q{paul@thestrongfamily.org}
  s.homepage    = %q{http://github.com/thinkwell/simple_crowd}
  s.summary     = %q{Simple Atlassian Crowd client using REST and SOAP APIs where needed.}
  s.description = %q{Simple Atlassian Crowd client using REST and SOAP APIs where needed.  Doesn't do any fancy object mapping, etc.}

  s.rubyforge_project = "simple_crowd"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency(%q<savon>, ["~>1.2.0"])

  s.add_development_dependency(%q<bundler>, [">= 1.0.21"])
  s.add_development_dependency(%q<rake>, [">= 0"])
end

