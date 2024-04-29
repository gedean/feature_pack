class FeaturePack::AddGroupGenerator < Rails::Generators::NamedBase
# class  Generators::FeaturePack::AddGroup::AddGroupGenerator < Rails::Generators::NamedBase
  desc 'Adds a new Feature Group'
  source_root File.expand_path('templates', __dir__)

  argument :name, type: :string, required: true, desc: 'The name (sneak case) of the group to add'

  def create_feature_group
    raise "Group '#{name}' already exists" if FeaturePack.group(name.to_sym).present?

    @class_name = name.camelcase

    # id can't contain underline '_'
    group_id = name.gsub('_', '-') + '-' + '999'
    group_dir = FeaturePack.features_path.join("group_#{group_id}_#{name}")

    template './_group_metadata/controller.rb.tt', group_dir.join('_group_metadata', 'controller.rb')
    template './_group_metadata/manifest.yaml.tt', group_dir.join('_group_metadata', 'manifest.yaml')
    template './_group_metadata/routes.rb.disabled.tt', group_dir.join('_group_metadata', 'routes.rb.disabled')
    template './_group_metadata/views/home.html.slim.tt', group_dir.join('_group_metadata', 'views/home.html.slim')
    template './_group_metadata/views/partials/_header.html.slim.tt', group_dir.join('_group_metadata', 'views/partials/_header.html.slim')
    template './_group_metadata/views/partials/_footer.html.slim.tt', group_dir.join('_group_metadata', 'views/partials/_footer.html.slim')

    # create_file "app/models/#{group_name.underscore}/#{name.underscore}.rb", <<-FILE
    # class #{group_name.camelize}::#{name.camelize} < ApplicationRecord
    #   # Lógicas específicas da feature, como validações e associações
    # end
    # FILE
  end
end
