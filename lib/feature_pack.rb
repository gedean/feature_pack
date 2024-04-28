require 'active_support/all'

module FeaturePack
  GROUP_ID_PATTERN = /^group_.*?_/.freeze
  FEATURE_ID_PATTERN = /^feature_.*?_/.freeze
  GROUP_METADATA_DIRECTORY = '_group_metadata'.freeze
  MANIFEST_FILE_NAME = 'manifest.yaml'.freeze
  CONTROLLER_FILE_NAME = 'controller.rb'.freeze

  ATTR_READERS = %i[
    path
    features_path
    ignored_paths
    groups
    groups_controllers_paths
    features_controllers_paths
    javascript_files_paths
  ].freeze

  def self.setup(features_path:)   
    raise 'FeaturePack already setup!' if defined?(@@setup_executed_flag)

    @@path = Pathname.new(__dir__)
    load @@path.join('feature_pack/error.rb')

    @@features_path = Pathname.new(features_path)
    raise "Invalid features_path: '#{@@features_path}'" if @@features_path.nil?
    raise "Inexistent features_path: '#{@@features_path}'" unless Dir.exist?(@@features_path)

    @@groups_controllers_paths = []
    @@features_controllers_paths = []

    @@ignored_paths = Dir.glob("#{@@features_path}/[!]*/")

    @@javascript_files_paths = Dir.glob("#{@@features_path}/[!_]*/**/*.js")
      .map { |js_path| js_path.sub(/^#{Regexp.escape(@@features_path.to_s)}\//, '') }.to_a

    ATTR_READERS.each { |attr| define_singleton_method(attr) { class_variable_get("@@#{attr}") } }
    
    @@ignored_paths << @@path.join('feature_pack/feature_pack_routes.rb')

    raise "No Groups found in: '#{@@features_path}'" if Dir.glob("#{@@features_path}/[!_]*/").empty?

    @@groups = Dir.glob("#{@@features_path}/[!_]*/").map do |group_path|
      relative_path = Pathname.new(group_path)
      base_path = File.basename(group_path, File::SEPARATOR)

      # On route draw call, the extension is ignored
      routes_file = File.exist?(File.join(group_path, GROUP_METADATA_DIRECTORY, 'routes.rb')) ? File.join(base_path, GROUP_METADATA_DIRECTORY, 'routes') : nil

      @@groups_controllers_paths << File.join(group_path, GROUP_METADATA_DIRECTORY, CONTROLLER_FILE_NAME)
      
      raise "Group '#{base_path}' does not have a valid ID" if base_path.scan(GROUP_ID_PATTERN).empty?
      group = OpenStruct.new(
        id: base_path.scan(GROUP_ID_PATTERN).first.delete_suffix('_'),
        name: base_path.gsub(GROUP_ID_PATTERN, '').to_sym,
        metadata_path: @@features_path.join(group_path, GROUP_METADATA_DIRECTORY),
        relative_path: relative_path,
        base_dir: File.basename(relative_path, File::SEPARATOR),
        routes_file: routes_file,
        features: [],
        manifest: YAML.load_file(File.join(group_path, GROUP_METADATA_DIRECTORY, MANIFEST_FILE_NAME)).deep_symbolize_keys
      )

      def group.feature(feature_name) = features.find { |p| p.name.eql?(feature_name) }
      def group.views_path = "#{base_dir}/#{GROUP_METADATA_DIRECTORY}/views"
      def group.view(view_name) = "#{base_dir}/#{GROUP_METADATA_DIRECTORY}/views/#{view_name}"
      def group.javascript_module(javascript_file_name) = "#{base_dir}/#{GROUP_METADATA_DIRECTORY}/javascript/#{javascript_file_name}"

      group
    end

    @@groups.each do |group|
      Dir.glob("#{group.relative_path}[!_]*/").each do |feature_path|
        absolute_path = @@features_path.join(feature_path)
        relative_path = Pathname.new(feature_path)
        base_path = File.basename(feature_path, File::SEPARATOR)
        
        feature_name = base_path.gsub(FEATURE_ID_PATTERN, '').to_sym
        
        routes_file_path = relative_path.join('routes.rb')

        # The custom routes file loads before the Rails default routes,
        # leading to errors like NoMethodError for 'scope'.
        # Ignoring them is required to prevent these issues.
        @@ignored_paths << routes_file_path
        
        # Due to Zeiwerk rules, Controllers have special load process
        @@features_controllers_paths << relative_path.join(CONTROLLER_FILE_NAME)

        @@ignored_paths << relative_path.join(CONTROLLER_FILE_NAME)

        raise "Resource '#{relative_path}' does not have a valid ID" if base_path.scan(FEATURE_ID_PATTERN).empty?
        feature_sub_path = relative_path.sub(/^#{Regexp.escape(@@features_path.to_s)}\//, '')
        feature = OpenStruct.new(
          id: base_path.scan(FEATURE_ID_PATTERN).first.delete_suffix('_'),
          name: feature_name,
          group: group,
          absolute_path: absolute_path,
          relative_path: relative_path,
          sub_path: feature_sub_path,
          routes_file_path: routes_file_path,
          routes_file: feature_sub_path.join('routes'),
          # controller_path: relative_path.join('controller'),
          views_absolute_path: absolute_path.join('views'),
          views_relative_path: relative_path.sub(/^#{Regexp.escape(@@features_path.to_s)}\//, '').join('views'),
          javascript_relative_path: relative_path.sub(/^#{Regexp.escape(@@features_path.to_s)}\//, '').join('javascript'),
          manifest: YAML.load_file(File.join(feature_path, MANIFEST_FILE_NAME)).deep_symbolize_keys
        )

        def feature.class_name = "FeaturePack::#{group.name.name.camelize}::#{name.name.camelize}"
        def feature.namespace = class_name.constantize

        feature.manifest.fetch(:const_aliases, []).each do |alias_data|
          alias_method_name, alias_const_name = alias_data.first
          feature.define_singleton_method(alias_method_name) { "#{class_name}::#{alias_const_name}".constantize }
        end

        def feature.view(view_name) = "#{views_relative_path}/#{view_name}"       
        def feature.javascript_module(javascript_file_name) = "#{javascript_relative_path}/#{javascript_file_name}"

        group.features << feature
      end
    end

    @@setup_executed_flag = true
  end

  def self.group(group_name) = @@groups.find { |g| g.name.eql?(group_name) }
  def self.feature(group_name, feature_name)
    requested_group = group(group_name)
    return nil if requested_group.nil?
    requested_group.feature(feature_name)
  end
end
