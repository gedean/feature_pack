require 'rspec'
require_relative '../lib/feature_pack'

RSpec.describe FeaturePack do
  before(:all) do
    FeaturePack.setup('./fixtures/feature_packs')
  end

  describe '.setup' do
    it 'should raise an error if FeaturePack is already setup' do
      expect { FeaturePack.setup }.to raise_error('FeaturePack already setup!')
    end

    
    it 'should set up the core_path' do
      expect(FeaturePack.core_path).to be_a(Pathname)
    end

    it 'should set up the groups' do
      expect(FeaturePack.groups).to be_an(Array)
      expect(FeaturePack.groups.first).to be_an(OpenStruct)
    end
  end

  describe '.group' do
    it 'should return the group with the given name' do
      group = FeaturePack.group(:my_group)
      expect(group).to be_an(OpenStruct)
      expect(group.name).to eq(:my_group)
    end

    it 'should return nil if the group does not exist' do
      group = FeaturePack.group(:non_existent_group)
      expect(group).to be_nil
    end
  end

  describe '.feature' do
    it 'should return the feature with the given group and feature name' do
      feature = FeaturePack.feature(:my_group, :my_feature)
      expect(feature).to be_an(OpenStruct)
      expect(feature.group.name).to eq(:my_group)
      expect(feature.name).to eq(:my_feature)
    end

    it 'should return nil if the feature or group does not exist' do
      feature = FeaturePack.feature(:non_existent_group, :non_existent_feature)
      expect(feature).to be_nil
    end
  end
end