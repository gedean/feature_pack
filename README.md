# Feature Pack
Organizes and sets up the architecture of micro-applications within a Rails application, enabling the segregation of code, management, and isolation of functionalities, which can be developed, tested, and maintained independently of each other.

## Installation
Meanwhile installer isn't done, follow the steps below to install FeaturePack GEM:

```ruby
# Add feature_pack to Gemfile
gem 'feature_pack'
```

```bash
bundle install
```

Setup loading 
```ruby
# config/application.rb

  feature_packs_path = Rails.root.join('app/feature_packs')
  FeaturePack.setup(features_path: feature_packs_path)

  FeaturePack.ignored_paths.each { |path| Rails.autoloaders.main.ignore(Rails.root.join(path)) }

  config.eager_load_paths << FeaturePack.features_path
  config.paths['app/views'] << FeaturePack.features_path

  config.paths['config/routes'] << (FeaturePack.path.to_s << '/feature_pack')
  config.paths['config/routes'] << FeaturePack.features_path
  config.assets.paths << FeaturePack.features_path.to_s

  Zeitwerk::Loader.eager_load_all

  config.after_initialize do
    load FeaturePack.path.join('feature_pack/group_controller.rb')
    load FeaturePack.path.join('feature_pack/controller.rb')

    FeaturePack.groups_controllers_paths.each { |group_controller_path| load group_controller_path }
    FeaturePack.features_controllers_paths.each { |controller_path| load controller_path }
  end
```

```ruby
# initializers/feature_pack.rb

FeaturePack.groups.each do |group|
  group_module = FeaturePack.const_set(group.name.name.camelize, Module.new)

  %w[Lib AI Jobs].each do |submodule_name|
    submodule_path = File.join(group.relative_path, '_group_metadata', submodule_name.downcase)
    if Dir.exist?(submodule_path)
      submodule = group_module.const_set(submodule_name, Module.new)
      Rails.autoloaders.main.push_dir(submodule_path, namespace: submodule)
    end
  end

  group.features.each do |feature|
    feature_module = group_module.const_set(feature.name.name.camelize, Module.new)
    Rails.autoloaders.main.push_dir(feature.relative_path, namespace: feature_module)
  end
end
```

```ruby
# app/helpers/application_helper.rb
  def feature_pack_group_path(group, *params) = send("feature_pack_#{group.name}_path".to_sym, *params)
  def feature_pack_path(group, feature, *params) = send("feature_pack_#{group.name}_#{feature.name}_path".to_sym, *params)
```
