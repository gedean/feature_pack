require 'rspec'
require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'rails'
require_relative '../lib/feature_pack'

module Rails
  class << self
    attr_accessor :feature_pack_test_root

    def root
      feature_pack_test_root || Pathname.new(File.expand_path('..', __dir__))
    end
  end
end

