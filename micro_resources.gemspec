Gem::Specification.new do |s|
  s.name          = 'micro_resources'
  s.version       = '0.0.4'
  s.date          = '2024-04-15'
  s.summary       = 'New way to organize app resources in Rails.'
  s.description   = 'Organizes and sets up the architecture of micro-applications within a Rails application, enabling the segregation of code, management, and isolation of functionalities, which can be developed, tested, and maintained independently of each other.'
  s.authors       = ['Gedean Dias']
  s.email         = 'gedean.dias@gmail.com'
  s.files         = Dir['README.md', 'lib/**/*']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3'
  s.homepage      = 'https://github.com/gedean/micro_resources'
  s.license       = 'MIT'
  s.add_dependency 'activesupport'
end
