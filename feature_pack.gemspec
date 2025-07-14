Gem::Specification.new do |spec|
  spec.name          = 'feature_pack'
  spec.version       = '0.9.1'
  spec.date          = '2025-07-14'
  spec.platform      = Gem::Platform::RUBY
  spec.summary       = 'A different approach to organizing Rails app features.'
  spec.description   = <<~DESC
    Organizes and sets up the architecture of micro-applications within a Rails application,
    enabling segregation, management, and isolation of functionalities, thereby supporting
    independent development, testing, and maintenance.
  DESC
  spec.authors       = ['Gedean Dias']
  spec.email         = 'gedean.dias@gmail.com'
  spec.files         = Dir.glob('README.md') + Dir.glob('lib/**/*') + Dir.glob('doc/**/*')
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 3'
  spec.homepage      = 'https://github.com/gedean/feature_pack'
  spec.license       = 'MIT'
  spec.add_dependency 'activesupport', '>= 7.0', '< 9.0'
  spec.post_install_message = 'Please check the README file for use instructions.'
  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/gedean/feature_pack/issues',
    'source_code_uri' => 'https://github.com/gedean/feature_pack',
    'changelog_uri' => 'https://github.com/gedean/feature_pack/blob/main/CHANGELOG.MD'
  }
end
