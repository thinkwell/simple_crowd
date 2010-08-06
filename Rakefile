require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "simple_crowd"
    gem.summary = "Simple Atlassian Crowd client using REST and SOAP APIs where needed."
    gem.description = %Q{Simple Atlassian Crowd client using REST and SOAP APIs where needed.
                         Doesn't do any fancy object mapping, etc.}
    gem.email = "paul@thestrongfamily.org"
    gem.homepage = "http://github.com/lapluviosilla/simple_crowd"
    gem.authors = ["Paul Strong"]
    gem.add_development_dependency "shoulda"
    gem.add_development_dependency "fcoury-matchy"
    gem.add_development_dependency "webmock"
    gem.add_development_dependency "rr"
    gem.add_dependency 'savon'
    gem.add_dependency 'hashie'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "simple_crowd #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
