require_relative 'spec_helper'

RSpec.describe FeaturePack do
  around(:example) do |example|
    tmp_root = Pathname.new(Dir.mktmpdir('feature_pack_spec'))
    build_feature_pack_tree!(tmp_root)
    Rails.feature_pack_test_root = tmp_root
    reset_feature_pack_state!
    FeaturePack.setup
    example.run
  ensure
    Rails.feature_pack_test_root = nil
    reset_feature_pack_state!
    FileUtils.rm_rf(tmp_root) if tmp_root
  end

  describe '.setup' do
    it 'raises an error if FeaturePack is already setup' do
      groups = FeaturePack.groups
      expect { FeaturePack.setup }.to raise_error('FeaturePack already setup!')
      expect(FeaturePack).to be_initialized
      expect(FeaturePack.groups).to equal(groups)
      expect(FeaturePack.feature(:finance, :reports)).to equal(groups.first.features.first)
    end

    it 'fails by default when the features directory is missing' do
      reset_feature_pack_state!
      FileUtils.rm_rf(Rails.root.join('app'))

      expect { FeaturePack.setup }.to raise_error(/does not exist/)
      expect(FeaturePack).not_to be_initialized
    end

    it 'boots an empty application when the features directory is optional' do
      reset_feature_pack_state!
      FileUtils.rm_rf(Rails.root.join('app'))

      expect { FeaturePack.setup(require_features_path: false) }.to output(/does not exist/).to_stderr

      expect(FeaturePack).to be_initialized
      expect(FeaturePack.groups).to eq([])
      expect(FeaturePack.features_path).not_to exist
    end

    it 'rejects a file in place of the feature directory' do
      reset_feature_pack_state!
      path = Rails.root.join('app/feature_packs')
      FileUtils.rm_rf(path)
      File.write(path, 'not a directory')

      expect { FeaturePack.setup }.to raise_error(/not a directory/)
      expect(FeaturePack).not_to be_initialized
    end

    it 'rolls back a failed discovery and permits retry after repair' do
      manifest = FeaturePack.feature(:finance, :reports).absolute_path.join('manifest.yaml')
      original = File.read(manifest)
      reset_feature_pack_state!
      File.write(manifest, '[invalid YAML')

      expect { FeaturePack.setup }.to raise_error(/Failed to load manifest/)
      expect(FeaturePack).not_to be_initialized
      expect { FeaturePack.groups }.to raise_error(FeaturePack::NotInitializedError)
      expect { FeaturePack.group(:finance) }.to raise_error(FeaturePack::NotInitializedError)

      File.write(manifest, original)
      FeaturePack.setup

      expect(FeaturePack).to be_initialized
      expect(FeaturePack.groups.length).to eq(1)
      expect(FeaturePack.group(:finance).features.map(&:name)).to eq([:reports])
    end

    it 'rolls back when a dependency fails to load' do
      reset_feature_pack_state!
      allow(FeaturePack).to receive(:load_dependencies).and_raise(LoadError, 'boom')

      expect { FeaturePack.setup }.to raise_error(LoadError, 'boom')
      expect(FeaturePack).not_to be_initialized
      expect { FeaturePack.features_path }.to raise_error(FeaturePack::NotInitializedError)
    end

    it 'allows groups without a controller' do
      reset_feature_pack_state!
      FileUtils.rm_f(Rails.root.join('app/feature_packs/group_001_finance/_group_space/controller.rb'))

      FeaturePack.setup

      expect(FeaturePack.group(:finance)).not_to be_nil
      expect(FeaturePack.groups_controllers_paths).to eq([])
    end

    it 'keeps legacy hook files away from Zeitwerk' do
      ignored = FeaturePack.ignored_paths.map(&:to_s)
      expect(ignored.any? { |path| path.end_with?('_group_space/__after_initialize.rb') }).to be(true)
      expect(ignored.any? { |path| path.end_with?('feature_001_reports/__after_initialize.rb') }).to be(true)
    end

    it 'sets up the path' do
      expect(FeaturePack.path).to be_a(Pathname)
      expect(FeaturePack.path.to_s).to include('lib')
    end

    it 'sets up the features_path' do
      expect(FeaturePack.features_path).to eq(Rails.root.join('app/feature_packs'))
    end

    it 'discovers groups' do
      expect(FeaturePack.groups).to be_an(Array)
      expect(FeaturePack.groups.size).to eq(1)
      expect(FeaturePack.groups.first.name).to eq(:finance)
    end

    it 'sets up controller paths' do
      group_paths = FeaturePack.groups_controllers_paths.map(&:to_s)
      feature_paths = FeaturePack.features_controllers_paths.map(&:to_s)

      expect(group_paths.any? { |path| path.end_with?('group_001_finance/_group_space/controller.rb') }).to be(true)
      expect(feature_paths.any? { |path| path.end_with?('group_001_finance/feature_001_reports/controller.rb') }).to be(true)
    end

    it 'sets up javascript file paths' do
      expect(FeaturePack.javascript_files_paths).to include('group_001_finance/feature_001_reports/javascript/app.js')
    end
  end

  describe '.group' do
    it 'returns the group with the given name' do
      result = FeaturePack.group(:finance)
      expect(result).not_to be_nil
      expect(result.name).to eq(:finance)
    end

    it 'returns nil when group does not exist' do
      expect(FeaturePack.group(:non_existent_group)).to be_nil
    end
  end

  describe '.feature' do
    it 'returns the feature when group and feature exist' do
      result = FeaturePack.feature(:finance, :reports)
      expect(result).not_to be_nil
      expect(result.name).to eq(:reports)
    end

    it 'returns nil when group does not exist' do
      expect(FeaturePack.feature(:non_existent_group, :reports)).to be_nil
    end

    it 'returns nil when feature does not exist in group' do
      expect(FeaturePack.feature(:finance, :non_existent_feature)).to be_nil
    end
  end

  describe 'Group methods' do
    let(:group) { FeaturePack.group(:finance) }

    it 'has views_path method' do
      expect(group.views_path).to eq('group_001_finance/_group_space/views')
    end

    it 'has view method' do
      expect(group.view('index')).to eq('group_001_finance/_group_space/views/index')
    end

    it 'has javascript_module method' do
      expect(group.javascript_module('app.js')).to eq('group_001_finance/_group_space/javascript/app.js')
    end
  end

  describe 'Feature methods' do
    let(:feature) { FeaturePack.feature(:finance, :reports) }

    it 'has class_name method' do
      expect(feature.class_name).to eq('FeaturePack::Finance::Reports')
    end

    it 'has view method' do
      expect(feature.view('index')).to eq('group_001_finance/feature_001_reports/views/index')
    end

    it 'has javascript_module method' do
      expect(feature.javascript_module('app.js')).to eq('group_001_finance/feature_001_reports/javascript/app.js')
    end
  end

  def build_feature_pack_tree!(root)
    group_path = root.join('app/feature_packs/group_001_finance')
    group_space_path = group_path.join('_group_space')
    feature_path = group_path.join('feature_001_reports')
    feature_javascript_path = feature_path.join('javascript')

    FileUtils.mkdir_p(group_space_path)
    FileUtils.mkdir_p(feature_path.join('views'))
    FileUtils.mkdir_p(feature_javascript_path)

    File.write(group_space_path.join('manifest.yaml'), { name: 'Finance', const_aliases: [] }.to_yaml)
    File.write(group_space_path.join('controller.rb'), "module FinanceGroupController; end\n")
    File.write(group_space_path.join('routes.rb'), "Rails.application.routes.draw do\nend\n")

    File.write(feature_path.join('manifest.yaml'), { name: 'Reports', const_aliases: [] }.to_yaml)
    File.write(feature_path.join('controller.rb'), "module ReportsFeatureController; end\n")
    File.write(feature_path.join('routes.rb'), "Rails.application.routes.draw do\nend\n")
    File.write(feature_javascript_path.join('app.js'), "console.log('reports');\n")
  end

  def reset_feature_pack_state!
    FeaturePack.send(:reset_state!)
  end
end
