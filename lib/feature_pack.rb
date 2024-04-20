require 'active_support/all'

module FeaturePack
  GROUP_ID_PATTERN = /^group_.*?_/.freeze
  FEATURE_ID_PATTERN = /^feature_.*?_/.freeze
  RELATIVE_ROOT_PATH = 'app/feature_packs'.freeze
  GROUP_METADATA_DIRECTORY = '_group_metadata'.freeze
  MANIFEST_FILE_NAME = 'manifest.yml'.freeze
  CONTROLLER_FILE_NAME = 'controller.rb'.freeze

  ATTR_READERS = %i[core_path absolute_root_path relative_root_path
    groups ignored_paths custom_layouts_paths javascript_files_paths
    group_controllers_paths controllers_paths].freeze

  def self.setup
    raise 'FeaturePack already setup!' if defined?(@@setup_executed_flag)
    
    @@core_path = Pathname.new(__dir__)

    @@group_controllers_paths = []
    @@controllers_paths = []
    @@relative_root_path = Pathname.new(RELATIVE_ROOT_PATH)
    
    # Don't fail tests outside of a Rails app
    @@absolute_root_path = defined?(Rails) ? Rails.root.join(RELATIVE_ROOT_PATH) : nil

    @@ignored_paths = Dir.glob("#{RELATIVE_ROOT_PATH}/[!]*/")
    @@javascript_files_paths = Dir.glob("#{@@relative_root_path}/[!_]*/**/*.js")
      .map { |js_path| js_path.sub(/^#{Regexp.escape(@@relative_root_path.to_s)}\//, '') }.to_a

    @@custom_layouts_paths = Dir.glob("#{@@relative_root_path}/[!_]*/**/views/layouts")
      .map { |layout_path| layout_path.delete_suffix '/layouts' }

    ATTR_READERS.each { |attr| define_singleton_method(attr) { class_variable_get("@@#{attr}") } }
    
    # load @@core_path.join('feature_pack/error.rb')
    @@ignored_paths << @@core_path.join('feature_pack/feature_pack_routes.rb')

    @@groups = Dir.glob("#{RELATIVE_ROOT_PATH}/[!_]*/").map do |group_path|
      relative_path = Pathname.new(group_path)
      base_path = File.basename(group_path, File::SEPARATOR)

      # On route draw call, the extension is ignored
      routes_file = File.exist?(File.join(group_path, GROUP_METADATA_DIRECTORY, 'routes.rb')) ? File.join(base_path, GROUP_METADATA_DIRECTORY, 'routes') : nil

      @@group_controllers_paths << File.join(group_path, GROUP_METADATA_DIRECTORY, CONTROLLER_FILE_NAME)
      
      raise "Group '#{base_path}' does not have a valid ID" if base_path.scan(GROUP_ID_PATTERN).empty?
      group = OpenStruct.new(
        id: base_path.scan(GROUP_ID_PATTERN).first.delete_suffix('_'),
        name: base_path.gsub(GROUP_ID_PATTERN, '').to_sym,
        metadata_path: Rails.root.join(group_path, GROUP_METADATA_DIRECTORY),
        relative_path: relative_path,
        base_dir: File.basename(relative_path, File::SEPARATOR),
        routes_file: routes_file,
        features: [],
        manifest: YAML.load_file(File.join(group_path, GROUP_METADATA_DIRECTORY, MANIFEST_FILE_NAME)).deep_symbolize_keys
      )

      def group.feature(feature_name) = features.find { |p| p.name.eql?(feature_name) }
      def group.views_path = "#{base_dir}/#{GROUP_METADATA_DIRECTORY}/views"
      def group.view(view_name) = "#{base_dir}/#{GROUP_METADATA_DIRECTORY}/views/#{view_name}"

      group
    end

    @@groups.each do |group|
      Dir.glob("#{group.relative_path}[!_]*/").each do |feature_path|
        absolute_path = Rails.root.join(feature_path)
        relative_path = Pathname.new(feature_path)
        base_path = File.basename(feature_path, File::SEPARATOR)
        
        feature_name = base_path.gsub(FEATURE_ID_PATTERN, '').to_sym
        feature_class_name = "#{group.name.name.camelize}::#{feature_name.name.camelize}"
        # FIX-ME
        # params_class_name = "#{feature_pack_class_name}::Params"
        
        routes_file_path = relative_path.join('routes.rb')

        # The custom routes file loads before the Rails default routes, leading to errors like NoMethodError for 'scope'. Ignoring them is required to prevent these issues.
        @@ignored_paths << routes_file_path
        
        # Due to Zeiwerk rules, Controllers have special load process
        @@controllers_paths << relative_path.join(CONTROLLER_FILE_NAME)
        @@ignored_paths << relative_path.join(CONTROLLER_FILE_NAME)

        raise "Resource '#{relative_path}' does not have a valid ID" if base_path.scan(FEATURE_ID_PATTERN).empty?
        feature_sub_path = relative_path.sub(/^#{Regexp.escape(@@relative_root_path.to_s)}\//, '')
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
          views_relative_path: relative_path.sub(/^#{Regexp.escape(@@relative_root_path.to_s)}\//, '').join('views'),
          class_name: feature_class_name,
          # FIX-ME
          #params_class_name: params_class_name,
          manifest: YAML.load_file(File.join(feature_path, MANIFEST_FILE_NAME)).deep_symbolize_keys
        )

        # FIX-ME
        # def feature.params_class = params_class_name.constantize
        def feature.view(view_name) = "#{views_relative_path}/#{view_name}"

        group.features << feature
      end
    end

    @@setup_executed_flag = true
  end

  def self.group(group_name) = @@groups.find { |g| g.name.eql?(group_name) }
  def self.feature(group_name, feature_name) = group(group_name).feature(feature_name)
end
