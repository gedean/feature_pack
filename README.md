# Feature Pack Gem
Organizes and sets up the architecture of micro-applications within a Ruby On Rails application, enabling the segregation of code, management, and isolation of functionalities, which can be developed, tested, and maintained independently of each other.

## Code and Folder Structure

### Group
A group is a collection of related features. Groups are represented as directories in the `app/feature_packs` folder. Each group contains a `_group_space` directory that holds group-level views and JavaScript files. Group directories follow this naming pattern:

#### Naming Convention
Sample: `group_areas-tecnicas-040000_atencao_especializada`

`group_` prefix is followed by the group identification (required)
`areas-tecnicas-040000` between `group_` and class name, exists only for organization purposes. The bounds are `group_` and next underscore `_`
`atencao_especializada` class name of the group (required)

The `_group_space` directory contains:

- `views/` - Views of the group
#### Common Files in _group_space/views

The `_group_space/views` directory typically contains these common files:

```
_group_space/views/
├── index.html.slim    # Default view for the group
└── partials/
    └── _header.html.slim # Base header template for the group
    └── _footer.html.slim # Base footer template for the group
```
Can have more views and partials, depending on the defined on `controller.rb` but these are the most common ones.

- `javascript/` - Group-level JavaScript modules shared across features
- `controller.rb` - Base controller class for the group's features
- `routes.rb` - The route are used only if the group has more than the default `index` action/view.

#### How implement a new Group
```
rails generate feature_pack:add_gruop <group_name>
```

### Feature
A feature is a single feature that can be added to a group. Feature naming patter is the same of group, but without the `group_` prefix.

#### Feature Routes
Every feature has a default route, which is the `index` action/view. If the feature has more than the default `index` action/view, the routes are defined in the `routes.rb` file.

#### How implement a new feature
```
rails generate feature_pack:add_feature <group_name>/<feature_name>
```
