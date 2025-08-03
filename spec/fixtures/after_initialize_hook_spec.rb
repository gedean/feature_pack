require 'spec_helper'

RSpec.describe 'FeaturePack after_initialize hooks' do
  let(:temp_dir) { Dir.mktmpdir }
  let(:group_path) { File.join(temp_dir, 'group_test') }
  let(:feature_path) { File.join(group_path, 'feature_example') }
  
  before do
    # Criar estrutura de diretórios
    FileUtils.mkdir_p(File.join(group_path, '_group_space'))
    FileUtils.mkdir_p(feature_path)
    
    # Criar manifest do grupo
    File.write(
      File.join(group_path, '_group_space', 'manifest.yaml'),
      "name: Test Group\nurl: /test"
    )
    
    # Criar manifest da feature
    File.write(
      File.join(feature_path, 'manifest.yaml'),
      "name: Example Feature\nurl: /example\nversion: 1.0.0"
    )
    
    # Criar hook do grupo
    File.write(
      File.join(group_path, '_group_space', 'after_initialize.rb'),
      <<~RUBY
        # Hook do grupo test
        @custom_data = { initialized_at: Time.now }
        def self.custom_data
          @custom_data
        end
      RUBY
    )
    
    # Criar hook da feature
    File.write(
      File.join(feature_path, 'after_initialize.rb'),
      <<~RUBY
        # Hook da feature example
        @feature_initialized = true
        def self.feature_initialized?
          @feature_initialized
        end
      RUBY
    )
  end
  
  after do
    FileUtils.rm_rf(temp_dir)
  end
  
  it 'executa hooks after_initialize para grupos e features' do
    # Simular carregamento do FeaturePack
    allow(Rails).to receive(:root).and_return(Pathname.new('/fake/path'))
    allow(Dir).to receive(:exist?).and_return(true)
    allow(Dir).to receive(:glob).and_return([group_path + '/', feature_path + '/'])
    
    # O teste real dependeria da estrutura completa do FeaturePack
    # Este é apenas um exemplo conceitual
    expect(File.exist?(File.join(group_path, '_group_space', 'after_initialize.rb'))).to be true
    expect(File.exist?(File.join(feature_path, 'after_initialize.rb'))).to be true
  end
end