# FeaturePack Library Documentation

## Overview

The `FeaturePack` library is a Ruby module designed to manage and organize feature groups and individual features within a Rails application. It provides a structured way to handle feature-specific routes, controllers, views, and JavaScript files.

## Key Components

### Constants

- `GROUP_ID_PATTERN`: Regex pattern for group IDs
- `FEATURE_ID_PATTERN`: Regex pattern for feature IDs
- `GROUP_METADATA_DIRECTORY`: Name of the directory containing group metadata
- `MANIFEST_FILE_NAME`: Name of the manifest file for groups and features
- `CONTROLLER_FILE_NAME`: Name of the controller file

### Attributes

The module defines several read-only attributes:

- `path`: Path to the FeaturePack library
- `features_path`: Path to the features directory
- `ignored_paths`: Paths to be ignored
- `groups`: Array of group objects
- `groups_controllers_paths`: Paths to group controllers
- `features_controllers_paths`: Paths to feature controllers
- `javascript_files_paths`: Paths to JavaScript files

## Setup

The `setup` method initializes the FeaturePack library:

1. Validates the provided `features_path`
2. Sets up ignored paths
3. Discovers and initializes groups and features
4. Sets up routes and controllers for groups and features

### Usage

```ruby
FeaturePack.setup(features_path: '/path/to/features')
```

## Groups

Groups are represented as `OpenStruct` objects with the following properties:

- `id`: Unique identifier for the group
- `name`: Human-readable name of the group
- `metadata_path`: Path to the group's metadata directory
- `relative_path`: Relative path to the group directory
- `base_dir`: Base directory name
- `routes_file`: Path to the group's routes file (if exists)
- `features`: Array of feature objects belonging to this group
- `manifest`: Parsed content of the group's manifest file

Groups also have methods for accessing views and JavaScript modules.

## Features

Features are represented as `OpenStruct` objects with the following properties:

- `id`: Unique identifier for the feature
- `name`: Human-readable name of the feature
- `group`: Reference to the parent group object
- `absolute_path`: Absolute path to the feature directory
- `relative_path`: Relative path to the feature directory
- `sub_path`: Sub-path of the feature directory
- `routes_file_path`: Path to the feature's routes file
- `routes_file`: Route name for the feature
- `views_absolute_path`: Absolute path to the feature's views
- `views_relative_path`: Relative path to the feature's views
- `javascript_relative_path`: Relative path to the feature's JavaScript files
- `manifest`: Parsed content of the feature's manifest file

Features also have methods for accessing their class name, namespace, views, and JavaScript modules.

## Utility Methods

- `FeaturePack.group(group_name)`: Finds a group by name
- `FeaturePack.feature(group_name, feature_name)`: Finds a feature within a group

## File Structure

The library expects the following file structure:

```
features_path/
├── group_name_1/
│   ├── _group_space/
│   │   ├── manifest.yaml
│   │   ├── controller.rb
│   │   └── routes.rb (optional)
│   ├── feature_name_1/
│   │   ├── manifest.yaml
│   │   ├── controller.rb
│   │   └── routes.rb
│   └── feature_name_2/
│       └── ...
└── group_name_2/
    └── ...
```

## Manifest Files

Both groups and features use manifest files (`manifest.yaml`) to store metadata. These files can include `const_aliases` for defining method aliases to constants.

## JavaScript Integration

The library automatically discovers and tracks JavaScript files within feature directories, making them accessible through the `javascript_files_paths` attribute.

## Error Handling

The library includes basic error handling for invalid or non-existent paths and missing group/feature IDs.

## Limitations and Notes

- The library assumes a specific directory structure and naming conventions.
- It relies on Rails' autoloading capabilities for controllers.
- Custom routes files for features are ignored to prevent conflicts with Rails' default routing.

This documentation provides an overview of the `FeaturePack` library's structure and functionality. For specific implementation details, refer to the inline comments and method definitions in the source code.