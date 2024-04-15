require 'active_support/all'

module MicroResources
  GROUP_ID_PATTERN = /^group_.*?_/.freeze
  MICRO_RESOURCES_ID_PATTERN = /^resource_.*?_/.freeze
  RELATIVE_ROOT_PATH = 'app/micro_resources'.freeze
  GROUP_METADATA_DIRECTORY = '_group_metadata'.freeze
  MANIFEST_FILE_NAME = 'manifest.yml'.freeze
  CONTROLLER_FILE_NAME = 'controller.rb'.freeze

  ATTR_READERS = %i[core_path absolute_root_path relative_root_path
    groups ignored_paths custom_layouts_paths javascript_files_paths
    group_controllers_paths controllers_paths].freeze

  def self.setup
    raise 'MicroResources already setup!' if defined?(@@relative_root_path)
    
    @@core_path = Pathname.new(__dir__)

    @@group_controllers_paths = []
    @@controllers_paths = []
    @@relative_root_path = Pathname.new(RELATIVE_ROOT_PATH)
    @@absolute_root_path = Rails.root.join(RELATIVE_ROOT_PATH)
    @@ignored_paths = Dir.glob("#{RELATIVE_ROOT_PATH}/[!]*/")
    @@javascript_files_paths = Dir.glob("#{@@relative_root_path}/[!_]*/**/*.js")
      .map { |js_path| js_path.sub(/^#{Regexp.escape(@@relative_root_path.to_s)}\//, '') }.to_a

    @@custom_layouts_paths = Dir.glob("#{@@relative_root_path}/[!_]*/**/views/layouts")
      .map { |layout_path| layout_path.delete_suffix '/layouts' }

    ATTR_READERS.each { |attr| define_singleton_method(attr) { class_variable_get("@@#{attr}") } }
    
    # load @@core_path.join('micro_resources/error.rb')
    @@ignored_paths << @@core_path.join('micro_resources/micro_resources_routes.rb')

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
        relative_path: relative_path,
        base_dir: File.basename(relative_path, File::SEPARATOR),
        routes_file: routes_file,
        micro_resources: [],
        manifest: YAML.load_file(File.join(group_path, GROUP_METADATA_DIRECTORY, MANIFEST_FILE_NAME)).deep_symbolize_keys
      )

      def group.micro_resource(micro_resource_name) = micro_resources.find { |p| p.name.eql?(micro_resource_name) }
      def group.views_path = "#{base_dir}/#{GROUP_METADATA_DIRECTORY}/views"
      def group.view(view_name) = "#{base_dir}/#{GROUP_METADATA_DIRECTORY}/views/#{view_name}"

      group
    end

    @@groups.each do |group|
      Dir.glob("#{group.relative_path}[!_]*/").each do |micro_resource_path|
        absolute_path = Rails.root.join(micro_resource_path)
        relative_path = Pathname.new(micro_resource_path)
        base_path = File.basename(micro_resource_path, File::SEPARATOR)
        
        micro_resource_name = base_path.gsub(MICRO_RESOURCES_ID_PATTERN, '').to_sym
        micro_resource_class_name = "#{group.name.name.camelize}::#{micro_resource_name.name.camelize}"
        params_class_name = "#{micro_resource_class_name}::Params"
        
        routes_file_path = relative_path.join('routes.rb')

        # The custom routes file loads before the Rails default routes, leading to errors like NoMethodError for 'scope'. Ignoring them is required to prevent these issues.
        @@ignored_paths << routes_file_path
        
        # Due to Zeiwerk rules, Controllers have special load process
        @@controllers_paths << relative_path.join(CONTROLLER_FILE_NAME)
        @@ignored_paths << relative_path.join(CONTROLLER_FILE_NAME)

        raise "Resource '#{relative_path}' does not have a valid ID" if base_path.scan(MICRO_RESOURCES_ID_PATTERN).empty?
        micro_resource_sub_path = relative_path.sub(/^#{Regexp.escape(@@relative_root_path.to_s)}\//, '')
        micro_resource = OpenStruct.new(
          id: base_path.scan(MICRO_RESOURCES_ID_PATTERN).first.delete_suffix('_'),
          name: micro_resource_name,
          group: group,
          absolute_path: absolute_path,
          relative_path: relative_path,
          sub_path: micro_resource_sub_path,
          routes_file_path: routes_file_path,
          routes_file: micro_resource_sub_path.join('routes'),
          # controller_path: relative_path.join('controller'),
          views_absolute_path: absolute_path.join('views'),
          views_relative_path: relative_path.sub(/^#{Regexp.escape(@@relative_root_path.to_s)}\//, '').join('views'),
          class_name: micro_resource_class_name,
          params_class_name: params_class_name,
          manifest: YAML.load_file(File.join(micro_resource_path, MANIFEST_FILE_NAME)).deep_symbolize_keys
        )

        def micro_resource.params_class = params_class_name.constantize
        def micro_resource.view(view_name) = "#{views_relative_path}/#{view_name}"

        group.micro_resources << micro_resource
      end
    end
  end

  def self.group(group_name) = @@groups.find { |g| g.name.eql?(group_name) }
  def self.micro_resources(group_name, micro_resources_name) = group(group_name).micro_resources(micro_resources_name)
end