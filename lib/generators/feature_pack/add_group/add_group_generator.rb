require 'rails/generators/base'
require 'rails/generators/named_base'

class FeaturePack::AddGroupGenerator < Rails::Generators::NamedBase

  desc 'Adds a new Feature Group'
  source_root File.expand_path('templates', __dir__)

  argument :name, type: :string, required: true, desc: 'The name (sneak case) of the group to add'

  def create_feature_group
    raise "Group name couldn't have '/'" if name.include?('/')
    raise "Group '#{name}' already exists" if FeaturePack.group(name.to_sym).present?

    @class_name = name.camelcase

    # id can't contain underline '_'
    group_id = name.gsub('_', '-') + '-' + '999'
    group_dir = FeaturePack.features_path.join("group_#{group_id}_#{name}")

    template './_group_space/controller.rb.tt', group_dir.join('_group_space', 'controller.rb')
    template './_group_space/manifest.yaml.tt', group_dir.join('_group_space', 'manifest.yaml')
    template './_group_space/routes.rb.disabled.tt', group_dir.join('_group_space', 'routes.rb.disabled')
    template './_group_space/views/index.html.slim.tt', group_dir.join('_group_space', 'views/index.html.slim')
    template './_group_space/views/partials/_header.html.slim.tt', group_dir.join('_group_space', 'views/partials/_header.html.slim')
    template './_group_space/views/partials/_footer.html.slim.tt', group_dir.join('_group_space', 'views/partials/_footer.html.slim')
  end
end
