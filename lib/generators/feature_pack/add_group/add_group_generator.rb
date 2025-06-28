require 'rails/generators/base'
require 'rails/generators/named_base'

module FeaturePack
  # Generator for creating new feature groups
  # Usage: rails generate feature_pack:add_group GROUP_NAME
  class AddGroupGenerator < Rails::Generators::NamedBase
    desc 'Creates a new Feature Group with the standard directory structure'
    source_root File.expand_path('templates', __dir__)

    argument :name, type: :string, required: true, desc: 'The name (snake_case) of the group to add'

    def create_feature_group
      validate_group_name!
      check_group_existence!
      
      @class_name = name.camelcase
      @group_id = generate_group_id
      
      group_dir = FeaturePack.features_path.join("group_#{@group_id}_#{name}")
      
      create_group_files(group_dir)
      
      say "Group '#{name}' created successfully!", :green
      say "Location: #{group_dir}", :green
    end

    private

    def validate_group_name!
      if name.include?('/')
        raise Thor::Error, "Group name cannot contain '/'. Use snake_case format."
      end
      
      unless name.match?(/^[a-z_]+$/)
        raise Thor::Error, "Group name must be in snake_case format (lowercase letters and underscores only)."
      end
    end

    def check_group_existence!
      if FeaturePack.group(name.to_sym).present?
        raise Thor::Error, "Group '#{name}' already exists"
      end
    end

    def generate_group_id
      # Generate a unique ID based on timestamp
      # Format: YYMMDD (can't contain underscores)
      Time.now.strftime('%y%m%d')
    end

    def create_group_files(group_dir)
      template './_group_space/controller.rb.tt', group_dir.join('_group_space', 'controller.rb')
      template './_group_space/manifest.yaml.tt', group_dir.join('_group_space', 'manifest.yaml')
      template './_group_space/routes.rb.tt', group_dir.join('_group_space', 'routes.rb')
      template './_group_space/views/index.html.slim.tt', group_dir.join('_group_space', 'views/index.html.slim')
      template './_group_space/views/partials/_header.html.slim.tt',
               group_dir.join('_group_space', 'views/partials/_header.html.slim')
      template './_group_space/views/partials/_footer.html.slim.tt',
               group_dir.join('_group_space', 'views/partials/_footer.html.slim')
      
      # Create javascript directory
      empty_directory group_dir.join('_group_space', 'javascript')
    end
  end
end
