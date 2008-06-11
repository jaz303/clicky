require 'rubygems'
require 'hoe'

spec = Gem::Specification.new do |s| 
  s.name = "clicky"
  s.version = "0.5.0"
  s.author = "Jason Frame"
  s.email = "jason@onehackoranother.com"
  s.homepage = "rubyforge.org/projects/clicky/"
  s.platform = Gem::Platform::RUBY
  s.summary = "A Ruby API client for Clicky, the popular web analytics service."
  s.files = FileList["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  s.rubyforge_project = "clicky"
end
 
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_tar = true 
end