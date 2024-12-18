Gem::Specification.new do |s|
  s.name          = 'feature_pack'
  s.version       = '0.6.1'
  s.date          = '2024-11-18'
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'New way to organize app features in Rails.'
  s.description   = 'Organizes and sets up the architecture of micro-applications within a Rails application, enabling the segregation of code, management, and isolation of functionalities, which can be developed, tested, and maintained independently of each other.'
  s.authors       = ['Gedean Dias']
  s.email         = 'gedean.dias@gmail.com'
  s.files         = Dir['README.md', 'lib/**/*', 'doc/**/*']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3'
  s.homepage      = 'https://github.com/gedean/feature_pack'
  s.license       = 'MIT'
  s.add_dependency 'activesupport', '>= 7.0', '< 9.0'
  s.post_install_message = %q{Please check readme file for use instructions.}
end
