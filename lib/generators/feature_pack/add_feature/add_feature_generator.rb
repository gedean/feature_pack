require 'rails/generators/base'
require 'rails/generators/named_base'

class FeaturePack::AddFeatureGenerator < Rails::Generators::NamedBase
  desc 'Adds a new Feature'
  source_root File.expand_path('templates', __dir__)

  argument :name, type: :string, required: true, desc: 'The name (sneak case) of the group to add'

  def add_feature
    raise "Feature name couldn't have more than one bar '/'" if name.count('/') > 1

    @group_name, @feature_name = name.split('/')
    @group = FeaturePack.group(@group_name.to_sym)
    @group_class_name = @group_name.camelcase
    @feature_class_name = @feature_name.camelcase

    raise "Group '#{@group_name}' doesn't exist. First, create it." if @group.nil?

    raise "Feature '#{@group_class_name}::#{@feature_class_name}' already Exist." if FeaturePack.feature(@group_name.to_sym, @feature_name.to_sym).present?

    @feature_id = @feature_name.gsub('_', '-') + '-' + '999'
    @feature_dir = @group.relative_path.join("feature_#{@feature_id}_#{@feature_name}")

    template './controller.rb.tt', @feature_dir.join('controller.rb')
    template './manifest.yaml.tt', @feature_dir.join('manifest.yaml')
    template './routes.rb.tt', @feature_dir.join('routes.rb')
    template './views/home.html.slim.tt', @feature_dir.join('views/home.html.slim')
    template './views/partials/_header.html.slim.tt', @feature_dir.join('views/partials/_header.html.slim')
    template './views/partials/_footer.html.slim.tt', @feature_dir.join('views/partials/_footer.html.slim')
    template './doc/readme.md.tt', @feature_dir.join('doc/readme.md')
    create_file @feature_dir.join('queries', '.gitkeep')
  end
end
