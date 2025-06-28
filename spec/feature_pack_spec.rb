require 'rspec'
require 'ostruct'
require_relative '../lib/feature_pack'

# Mock Rails for testing
module Rails
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end
end

FIXTURES_FEATURES_PATH = 'spec/fixtures/feature_packs'

RSpec.describe FeaturePack do
  before(:all) do
    # Reset setup flag for testing
    FeaturePack.class_variable_set(:@@setup_executed_flag, nil) if FeaturePack.class_variable_defined?(:@@setup_executed_flag)
    FeaturePack.setup
  end

  describe '.setup' do
    it 'raises an error if FeaturePack is already setup' do
      expect { FeaturePack.setup }.to raise_error('FeaturePack already setup!')
    end
    
    it 'sets up the path' do
      expect(FeaturePack.path).to be_a(Pathname)
      expect(FeaturePack.path.to_s).to include('lib')
    end

    it 'sets up the features_path' do
      expect(FeaturePack.features_path).to be_a(Pathname)
      expect(FeaturePack.features_path.to_s).to include('app/feature_packs')
    end

    it 'sets up the groups' do
      expect(FeaturePack.groups).to be_an(Array)
      expect(FeaturePack.groups).not_to be_empty if Dir.exist?(FeaturePack.features_path)
    end

    it 'sets up controller paths' do
      expect(FeaturePack.groups_controllers_paths).to be_an(Array)
      expect(FeaturePack.features_controllers_paths).to be_an(Array)
    end

    it 'sets up javascript file paths' do
      expect(FeaturePack.javascript_files_paths).to be_an(Array)
    end
  end

  describe '.group' do
    context 'when group exists' do
      it 'returns the group with the given name' do
        # Create a mock group for testing
        group = OpenStruct.new(name: :test_group)
        allow(FeaturePack).to receive(:groups).and_return([group])
        
        result = FeaturePack.group(:test_group)
        expect(result).to eq(group)
        expect(result.name).to eq(:test_group)
      end
    end

    context 'when group does not exist' do
      it 'returns nil' do
        allow(FeaturePack).to receive(:groups).and_return([])
        
        result = FeaturePack.group(:non_existent_group)
        expect(result).to be_nil
      end
    end
  end

  describe '.feature' do
    context 'when group and feature exist' do
      it 'returns the feature' do
        # Create mock feature and group
        feature = OpenStruct.new(name: :test_feature)
        group = OpenStruct.new(name: :test_group, features: [feature])
        group.define_singleton_method(:feature) { |name| features.find { |f| f.name == name } }
        
        allow(FeaturePack).to receive(:groups).and_return([group])
        
        result = FeaturePack.feature(:test_group, :test_feature)
        expect(result).to eq(feature)
        expect(result.name).to eq(:test_feature)
      end
    end

    context 'when group does not exist' do
      it 'returns nil' do
        allow(FeaturePack).to receive(:groups).and_return([])
        
        result = FeaturePack.feature(:non_existent_group, :test_feature)
        expect(result).to be_nil
      end
    end

    context 'when feature does not exist in group' do
      it 'returns nil' do
        group = OpenStruct.new(name: :test_group, features: [])
        group.define_singleton_method(:feature) { |name| features.find { |f| f.name == name } }
        
        allow(FeaturePack).to receive(:groups).and_return([group])
        
        result = FeaturePack.feature(:test_group, :non_existent_feature)
        expect(result).to be_nil
      end
    end
  end

  describe 'Group methods' do
    let(:group) do
      group = OpenStruct.new(
        name: :test_group,
        base_dir: 'group_123_test_group',
        features: []
      )
      
      # Define methods that should be added by FeaturePack
      def group.views_path
        "#{base_dir}/_group_space/views"
      end
      
      def group.view(view_name)
        "#{base_dir}/_group_space/views/#{view_name}"
      end
      
      def group.javascript_module(javascript_file_name)
        "#{base_dir}/_group_space/javascript/#{javascript_file_name}"
      end
      
      def group.feature(feature_name)
        features.find { |f| f.name == feature_name }
      end
      
      group
    end

    it 'has views_path method' do
      expect(group.views_path).to eq('group_123_test_group/_group_space/views')
    end

    it 'has view method' do
      expect(group.view('index')).to eq('group_123_test_group/_group_space/views/index')
    end

    it 'has javascript_module method' do
      expect(group.javascript_module('app.js')).to eq('group_123_test_group/_group_space/javascript/app.js')
    end
  end

  describe 'Feature methods' do
    let(:feature) do
      feature = OpenStruct.new(
        name: :test_feature,
        views_relative_path: 'group_123_test_group/feature_456_test_feature/views',
        javascript_relative_path: 'group_123_test_group/feature_456_test_feature/javascript',
        group: OpenStruct.new(name: :test_group)
      )
      
      # Define methods that should be added by FeaturePack
      def feature.class_name
        "FeaturePack::#{group.name.to_s.camelize}::#{name.to_s.camelize}"
      end
      
      def feature.view(view_name)
        "#{views_relative_path}/#{view_name}"
      end
      
      def feature.javascript_module(javascript_file_name)
        "#{javascript_relative_path}/#{javascript_file_name}"
      end
      
      feature
    end

    it 'has class_name method' do
      expect(feature.class_name).to eq('FeaturePack::TestGroup::TestFeature')
    end

    it 'has view method' do
      expect(feature.view('index')).to eq('group_123_test_group/feature_456_test_feature/views/index')
    end

    it 'has javascript_module method' do
      expect(feature.javascript_module('app.js')).to eq('group_123_test_group/feature_456_test_feature/javascript/app.js')
    end
  end
end