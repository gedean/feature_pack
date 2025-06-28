# Feature Pack Gem

[![Gem Version](https://badge.fury.io/rb/feature_pack.svg)](https://badge.fury.io/rb/feature_pack)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Feature Pack organizes and sets up the architecture of micro-applications within a Ruby on Rails application, enabling the segregation of code, management, and isolation of functionalities. Features can be developed, tested, and maintained independently of each other.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'feature_pack'
```

And then execute:

```bash
bundle install
```

## Setup

Add to your `config/application.rb`:

```ruby
# After Bundler.require
require 'feature_pack'
FeaturePack.setup
```

## Concepts

### Groups
Groups are collections of related features. They provide:
- Shared layouts and partials
- Common base controller functionality
- Namespace organization
- Shared JavaScript modules

### Features
Features are individual functionalities within a group. They provide:
- Independent controllers and views
- Isolated routes
- Feature-specific JavaScript
- Complete MVC structure

## Usage

### Creating a New Group

```bash
rails generate feature_pack:add_group human_resources
```

This creates the following structure:
```
app/feature_packs/
└── group_YYMMDD_human_resources/
    └── _group_space/
        ├── controller.rb
        ├── manifest.yaml
        ├── routes.rb
        ├── javascript/
        └── views/
            ├── index.html.slim
            └── partials/
                ├── _header.html.slim
                └── _footer.html.slim
```

### Creating a New Feature

```bash
rails generate feature_pack:add_feature human_resources/employees
```

This creates:
```
app/feature_packs/
└── group_YYMMDD_human_resources/
    └── feature_YYMMDD_employees/
        ├── controller.rb
        ├── manifest.yaml
        ├── routes.rb
        ├── doc/
        │   └── readme.md
        ├── javascript/
        ├── queries/
        └── views/
            ├── index.html.slim
            └── partials/
                ├── _header.html.slim
                └── _footer.html.slim
```

## Code Structure

### Naming Convention

#### Groups
Format: `group_<id>_<name>`
- `group_` - Required prefix
- `<id>` - Unique identifier (typically YYMMDD format)
- `<name>` - Group name in snake_case

Example: `group_241209_human_resources`

#### Features
Format: `feature_<id>_<name>`
- `feature_` - Required prefix
- `<id>` - Unique identifier (typically YYMMDD format)
- `<name>` - Feature name in snake_case

Example: `feature_241209_employees`

### Directory Structure

#### Group Space (`_group_space`)
Contains group-level resources:
- `controller.rb` - Base controller for all features in the group
- `manifest.yaml` - Group configuration
- `routes.rb` - Group-level routes
- `views/` - Shared views and layouts
- `javascript/` - Shared JavaScript modules

#### Feature Directory
Contains feature-specific resources:
- `controller.rb` - Feature controller
- `manifest.yaml` - Feature configuration
- `routes.rb` - Feature routes
- `views/` - Feature views
- `javascript/` - Feature-specific JavaScript
- `queries/` - Database queries
- `doc/` - Feature documentation

## Controllers

### Group Controller
```ruby
class FeaturePack::HumanResourcesController < FeaturePack::GroupController
  # Group-wide functionality
end
```

### Feature Controller
```ruby
class FeaturePack::HumanResources::EmployeesController < FeaturePack::HumanResourcesController
  def index
    # Feature-specific logic
  end
end
```

## Routes

Routes are automatically configured based on manifest files:

```yaml
# Group manifest.yaml
url: /hr
name: Human Resources

# Feature manifest.yaml
url: /employees
name: Employees Management
```

This generates routes like:
- `/hr` - Group index
- `/hr/employees` - Feature index

## Helpers

### Path Helpers

```ruby
# Group path
feature_pack_group_path(:human_resources)
# => "/hr"

# Feature path
feature_pack_path(:human_resources, :employees)
# => "/hr/employees"

# With parameters
feature_pack_path(:human_resources, :employees, id: 1)
# => "/hr/employees?id=1"
```

### Controller Variables

Available in controllers and views:
- `@group` - Current group object
- `@feature` - Current feature object (not available in group controller)

## View Hierarchy

Views are resolved in the following order:
1. Feature-specific views
2. Group-shared views
3. Application default views

### Partials
Header and footer partials follow a fallback pattern:
1. Feature's `views/partials/_header.html.slim`
2. Group's `views/partials/_header.html.slim`
3. Application's default header

## JavaScript Integration

JavaScript files are automatically discovered and can be referenced:

```ruby
# In views
javascript_include_tag @group.javascript_module('shared')
javascript_include_tag @feature.javascript_module('employees')
```

## Advanced Configuration

### Manifest Files

Group manifest (`_group_space/manifest.yaml`):
```yaml
url: /hr
name: Human Resources
const_aliases:
  - employee_model: Employee
  - department_model: Department
```

Feature manifest:
```yaml
url: /employees
name: Employees Management
const_aliases:
  - service: EmployeeService
```

### Const Aliases

Access aliased constants:
```ruby
# In controllers
@group.employee_model  # => Employee
@feature.service       # => FeaturePack::HumanResources::Employees::EmployeeService
```

## Best Practices

1. **Group Organization**: Group related features that share common functionality
2. **Naming**: Use descriptive snake_case names for groups and features
3. **Isolation**: Keep features independent and loosely coupled
4. **Shared Resources**: Place common code in group space
5. **Documentation**: Document each feature in its `doc/readme.md`

## Troubleshooting

### Common Issues

1. **Group/Feature Not Found**
   - Ensure proper naming convention
   - Run `FeaturePack.setup` after adding new groups/features
   - Check manifest files exist

2. **Routes Not Working**
   - Verify manifest.yaml has correct URL configuration
   - Check routes.rb files exist
   - Restart Rails server after changes

3. **Views Not Rendering**
   - Check view file extensions (.html.slim, .html.erb, etc.)
   - Verify view paths in controller
   - Check for typos in view names

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Author

Gedean Dias - gedean.dias@gmail.com

## Links

- [GitHub Repository](https://github.com/gedean/feature_pack)
- [RubyGems](https://rubygems.org/gems/feature_pack)
- [Bug Reports](https://github.com/gedean/feature_pack/issues)