require 'rubygems'
Gem::Specification.new do |s|
  s.name        = 'jira-wsdl'
  s.version     = '0.0.3'
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = 'jira-wsdl'
  s.description = 'working with wsdl of JIRA'
  s.authors     =
  s.email       = 'tiago.l.nobre@gmail.com'
  s.files       = Dir.glob("{lib}/**/*") + %w(README.md Rakefile)
  s.has_rdoc    = false
  s.add_dependency('savon', '~> 2.12.0')
end
