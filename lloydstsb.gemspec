require File.expand_path('../lib/lloydstsb/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name = 'lloydstsb'
  gem.version = LloydsTSB::VERSION.dup
  gem.authors = ['Tim Rogers']
  gem.email = ['tim@tim-rogers.co.uk']
  gem.summary = 'A library for accessing data from Lloyds TSB\'s online banking'
  gem.homepage = 'https://github.com/timrogers/lloydstsb'

  gem.add_dependency 'mechanize', '~> 2.5.1'

  gem.files = `git ls-files`.split("\n")
end