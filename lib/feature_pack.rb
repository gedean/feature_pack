require 'active_support/all'
require 'ostruct'

# FeaturePack module provides a way to organize Rails applications into
# groups and features, enabling better code organization and isolation
module FeaturePack
  @initialized = false

  # Raised when registry data is requested before `setup` succeeded
  class NotInitializedError < StandardError; end

  # Pattern constants for identifying groups and features
  GROUP_ID_PATTERN = /^group_.*?_/.freeze
  FEATURE_ID_PATTERN = /^feature_.*?_/.freeze
  
  # Directory and file name constants
  GROUP_SPACE_DIRECTORY = '_group_space'.freeze
  MANIFEST_FILE_NAME = 'manifest.yaml'.freeze
  CONTROLLER_FILE_NAME = 'controller.rb'.freeze
  # Hook file from 0.10.x; no longer loaded but still kept away from Zeitwerk
  LEGACY_HOOK_FILE_NAME = '__after_initialize.rb'.freeze

  # Registry attributes populated by `setup`
  ATTR_READERS = %i[
    path
    features_path
    ignored_paths
    groups
    groups_controllers_paths
    features_controllers_paths
    javascript_files_paths
  ].freeze

  class << self
    # Sets up the FeaturePack system
    # This method should be called once during Rails initialization
    # @param require_features_path [Boolean] when true (default), a missing
    #   app/feature_packs directory aborts the boot; pass false to boot with no
    #   groups (e.g. before generating the first group).
    def setup(require_features_path: true)
      raise 'FeaturePack already setup!' if @initialized

      begin
        initialize_paths(require_features_path)
        load_dependencies
        discover_groups
        discover_features
        finalize_setup
        @initialized = true
      rescue StandardError, ScriptError
        # ScriptError covers LoadError/SyntaxError raised while loading files.
        reset_state!
        raise
      end
    end

    def initialized? = @initialized

    ATTR_READERS.each do |attr|
      define_method(attr) do
        ensure_initialized!
        instance_variable_get("@#{attr}")
      end
    end

    # Finds a group by name
    # @param group_name [Symbol] The name of the group
    # @return [OpenStruct, nil] The group object or nil if not found
    def group(group_name) = groups.find { |group| group.name.eql?(group_name) }

    # Finds a feature within a group
    # @param group_name [Symbol] The name of the group
    # @param feature_name [Symbol] The name of the feature
    # @return [OpenStruct, nil] The feature object or nil if not found
    def feature(group_name, feature_name)
      requested_group = group(group_name)
      return nil if requested_group.nil?

      requested_group.feature(feature_name)
    end

    private

    def ensure_initialized!
      return if @initialized

      raise NotInitializedError, 'FeaturePack is not set up. Call FeaturePack.setup first.'
    end

    def initialize_paths(require_features_path)
      @path = Pathname.new(__dir__)
      @features_path = Pathname.new(Rails.root.join('app/feature_packs'))

      validate_features_path!(require_features_path)

      @groups_controllers_paths = []
      @features_controllers_paths = []
      # Every entry under features_path is ignored by Zeitwerk; controllers and
      # routes are loaded explicitly (see SETUP.md), and feature modules are
      # registered through push_dir by the host application.
      @ignored_paths = Dir.glob("#{@features_path}/*/")
      @javascript_files_paths = discover_javascript_files
    end

    def load_dependencies = load(@path.join('feature_pack/error.rb'))

    def validate_features_path!(require_features_path)
      if @features_path.exist?
        raise "Features path is not a directory: '#{@features_path}'" unless @features_path.directory?
        return
      end

      message = "Features path '#{@features_path}' does not exist"
      if require_features_path
        raise "#{message}. Create app/feature_packs or call FeaturePack.setup(require_features_path: false)"
      end

      log_warning("[FeaturePack] #{message}. No groups or features will be loaded.")
    end

    def log_warning(message)
      logger = Rails.respond_to?(:logger) ? Rails.logger : nil
      logger ? logger.warn(message) : warn(message)
    end

    def discover_javascript_files
      prefix = "#{@features_path}/"
      Dir.glob("#{prefix}[!_]*/**/*.js").map { |js_path| js_path.delete_prefix(prefix) }
    end

    def finalize_setup = @ignored_paths << @path.join('feature_pack/feature_pack_routes.rb')

    # Clears every registry attribute so a failed or repeated setup starts clean
    def reset_state!
      @initialized = false
      ATTR_READERS.each { |attr| remove_instance_variable("@#{attr}") if instance_variable_defined?("@#{attr}") }
    end

    def discover_groups = @groups = Dir.glob("#{@features_path}/[!_]*/").map { |group_path| build_group(group_path) }

    def build_group(group_path)
      relative_path = Pathname.new(group_path)
      base_path = File.basename(group_path, File::SEPARATOR)
      
      validate_group_id!(base_path)
      
      routes_file = find_group_routes_file(group_path, base_path)
      register_group_controller(group_path)
      
      group = create_group_struct(base_path, group_path, relative_path, routes_file)
      setup_group_aliases(group)
      define_group_methods(group)
      
      group
    end

    def validate_group_id!(base_path)
      if base_path.scan(GROUP_ID_PATTERN).empty?
        raise "Group '#{base_path}' does not have a valid ID. Expected format: group_<id>_<name>"
      end
    end

    # Groups without a controller are allowed (namespace-only groups);
    # add_feature validates the controller when a feature needs to inherit it.
    def register_group_controller(group_path)
      controller_path = File.join(group_path, GROUP_SPACE_DIRECTORY, CONTROLLER_FILE_NAME)
      @groups_controllers_paths << controller_path if File.exist?(controller_path)
      @ignored_paths << File.join(group_path, GROUP_SPACE_DIRECTORY, LEGACY_HOOK_FILE_NAME)
    end

    def find_group_routes_file(group_path, base_path)
      routes_path = File.join(group_path, GROUP_SPACE_DIRECTORY, 'routes.rb')
      File.exist?(routes_path) ? File.join(base_path, GROUP_SPACE_DIRECTORY, 'routes') : nil
    end

    def create_group_struct(base_path, group_path, relative_path, routes_file)
      manifest_path = File.join(group_path, GROUP_SPACE_DIRECTORY, MANIFEST_FILE_NAME)
      
      unless File.exist?(manifest_path)
        raise "Manifest file not found for group '#{base_path}' at #{manifest_path}"
      end
      
      OpenStruct.new(
        id: base_path.scan(GROUP_ID_PATTERN).first.delete_suffix('_'),
        name: base_path.gsub(GROUP_ID_PATTERN, '').to_sym,
        metadata_path: @features_path.join(group_path, GROUP_SPACE_DIRECTORY),
        relative_path: relative_path,
        base_dir: File.basename(relative_path, File::SEPARATOR),
        routes_file: routes_file,
        features: [],
        manifest: load_manifest(manifest_path)
      )
    end

    def load_manifest(manifest_path)
      YAML.load_file(manifest_path).deep_symbolize_keys
    rescue => e
      raise "Failed to load manifest at #{manifest_path}: #{e.message}"
    end

    def setup_group_aliases(group)
      group.manifest.fetch(:const_aliases, []).each do |const_alias|
        alias_method_name, alias_const_name = const_alias.first
        group.define_singleton_method(alias_method_name) do
          "FeaturePack::#{group.name.to_s.camelize}::#{alias_const_name}".constantize
        end
      end
    end

    def define_group_methods(group)
      def group.feature(feature_name) = features.find { |feature| feature.name.eql?(feature_name) }
      def group.views_path = "#{base_dir}/#{GROUP_SPACE_DIRECTORY}/views"
      def group.view(view_name) = "#{base_dir}/#{GROUP_SPACE_DIRECTORY}/views/#{view_name}"     
      def group.javascript_module(javascript_file_name) = "#{base_dir}/#{GROUP_SPACE_DIRECTORY}/javascript/#{javascript_file_name}"
    end

    def discover_features
      @groups.each do |group|
        Dir.glob("#{group.relative_path}[!_]*/").each do |feature_path|
          build_feature(group, feature_path)
        end
      end
    end

    def build_feature(group, feature_path)
      absolute_path = @features_path.join(feature_path)
      relative_path = Pathname.new(feature_path)
      base_path = File.basename(feature_path, File::SEPARATOR)
      
      validate_feature_id!(base_path, relative_path)
      
      feature_name = base_path.gsub(FEATURE_ID_PATTERN, '').to_sym
      routes_file_path = relative_path.join('routes.rb')
      
      setup_feature_paths(relative_path, routes_file_path)
      
      feature = create_feature_struct(
        base_path, feature_name, group, absolute_path, 
        relative_path, routes_file_path, feature_path
      )
      
      define_feature_methods(feature)
      setup_feature_aliases(feature)
      
      group.features << feature
    end

    def validate_feature_id!(base_path, relative_path)
      if base_path.scan(FEATURE_ID_PATTERN).empty?
        raise "Feature '#{relative_path}' does not have a valid ID. Expected format: feature_<id>_<name>"
      end
    end

    def setup_feature_paths(relative_path, routes_file_path)
      # Custom routes file loads before Rails default routes
      @ignored_paths << routes_file_path
      
      # Controllers have special load process due to Zeitwerk
      controller_path = relative_path.join(CONTROLLER_FILE_NAME)
      @features_controllers_paths << controller_path
      @ignored_paths << controller_path
      # Feature directories are Zeitwerk roots (push_dir), so the group-level
      # ignore does not cover leftover 0.10.x hook files.
      @ignored_paths << relative_path.join(LEGACY_HOOK_FILE_NAME)
    end

    def create_feature_struct(base_path, feature_name, group, absolute_path, relative_path, routes_file_path, feature_path)
      feature_sub_path = relative_path.sub(/^#{Regexp.escape(@features_path.to_s)}\//, '')
      manifest_path = File.join(feature_path, MANIFEST_FILE_NAME)
      
      unless File.exist?(manifest_path)
        raise "Manifest file not found for feature '#{feature_name}' at #{manifest_path}"
      end
      
      OpenStruct.new(
        id: base_path.scan(FEATURE_ID_PATTERN).first.delete_suffix('_'),
        name: feature_name,
        group: group,
        absolute_path: absolute_path,
        relative_path: relative_path,
        sub_path: feature_sub_path,
        routes_file_path: routes_file_path,
        routes_file: feature_sub_path.join('routes'),
        views_absolute_path: absolute_path.join('views'),
        views_relative_path: feature_sub_path.join('views'),
        javascript_relative_path: feature_sub_path.join('javascript'),
        manifest: load_manifest(manifest_path)
      )
    end

    def define_feature_methods(feature)
      def feature.class_name = "FeaturePack::#{group.name.to_s.camelize}::#{name.to_s.camelize}"
      def feature.namespace = class_name.constantize
      def feature.view(view_name) = "#{views_relative_path}/#{view_name}"     
      def feature.javascript_module(javascript_file_name) = "#{javascript_relative_path}/#{javascript_file_name}"
    end

    def setup_feature_aliases(feature)
      feature.manifest.fetch(:const_aliases, []).each do |const_alias|
        alias_method_name, alias_const_name = const_alias.first
        feature.define_singleton_method(alias_method_name) do
          "#{class_name}::#{alias_const_name}".constantize
        end
      end
    end
  end
end
