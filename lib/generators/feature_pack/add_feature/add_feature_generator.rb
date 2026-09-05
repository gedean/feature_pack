require 'rails/generators/base'
require 'rails/generators/named_base'

module FeaturePack
  # Generator for creating new features within a group
  # Usage: rails generate feature_pack:add_feature GROUP_NAME/FEATURE_NAME
  class AddFeatureGenerator < Rails::Generators::NamedBase
    desc 'Creates a new Feature within an existing Group'
    source_root File.expand_path('templates', __dir__)

    argument :name, type: :string, required: true,
                    desc: 'The group/feature name (snake_case) format: group_name/feature_name'

    def add_feature
      validate_feature_name!
      parse_names
      check_group_existence!
      check_feature_existence!
      check_group_controller!
      
      @feature_id = generate_feature_id
      @feature_dir = @group.relative_path.join("feature_#{@feature_id}_#{@feature_name}")
      
      create_feature_files
      
      say "Feature '#{@feature_name}' created successfully in group '#{@group_name}'!", :green
      say "Location: #{@feature_dir}", :green
    end

    private

    def validate_feature_name!
      if name.count('/') != 1
        raise Thor::Error, "Feature name must be in format: group_name/feature_name"
      end
    end

    def parse_names
      @group_name, @feature_name = name.split('/')
      
      unless @group_name.match?(/^[a-z_]+$/) && @feature_name.match?(/^[a-z_]+$/)
        raise Thor::Error, "Group and feature names must be in snake_case format"
      end
      
      @group_class_name = @group_name.camelcase
      @feature_class_name = @feature_name.camelcase
    end

    def check_group_existence!
      @group = FeaturePack.group(@group_name.to_sym)
      
      if @group.nil?
        raise Thor::Error, "Group '#{@group_name}' doesn't exist. Create it first with: rails generate feature_pack:add_group #{@group_name}"
      end
    end

    # The generated feature controller inherits FeaturePack::<Group>Controller,
    # so validate the resolved class independently of its declaration syntax.
    def check_group_controller!
      controller_path = @group.metadata_path.join(FeaturePack::CONTROLLER_FILE_NAME)
      expected_class = "FeaturePack::#{@group_class_name}Controller"

      unless File.exist?(controller_path)
        raise Thor::Error,
              "Group controller not found at #{controller_path}. The feature controller must inherit #{expected_class}."
      end

      controller_class = expected_class.safe_constantize || load_group_controller(controller_path, expected_class)

      return if controller_class.is_a?(Class)

      raise Thor::Error, "#{controller_path} does not define #{expected_class}, which the feature controller inherits."
    end

    def load_group_controller(controller_path, expected_class)
      load controller_path
      expected_class.safe_constantize
    rescue StandardError, ScriptError => e
      raise Thor::Error, "Could not load group controller #{controller_path}: #{e.class}: #{e.message}"
    end

    def check_feature_existence!
      if FeaturePack.feature(@group_name.to_sym, @feature_name.to_sym).present?
        raise Thor::Error, "Feature '#{@feature_name}' already exists in group '#{@group_name}'"
      end
    end

    def generate_feature_id
      # Generate a unique ID based on timestamp
      # Format: YYMMDD (can't contain underscores)
      Time.now.strftime('%y%m%d')
    end

    def create_feature_files
      template './controller.rb.tt', @feature_dir.join('controller.rb')
      template './manifest.yaml.tt', @feature_dir.join('manifest.yaml')
      template './routes.rb.tt', @feature_dir.join('routes.rb')
      template './views/index.html.slim.tt', @feature_dir.join('views/index.html.slim')
      template './views/partials/_header.html.slim.tt', @feature_dir.join('views/partials/_header.html.slim')
      template './views/partials/_footer.html.slim.tt', @feature_dir.join('views/partials/_footer.html.slim')
      template './doc/readme.md.tt', @feature_dir.join('doc/readme.md')
      
      # Create directories
      empty_directory @feature_dir.join('queries')
      empty_directory @feature_dir.join('javascript')
    end
  end
end
