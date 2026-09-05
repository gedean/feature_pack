# Changelog

## [0.12.0] - 2026-09-05
### Added
- `FeaturePack.initialized?` and `FeaturePack::NotInitializedError`
- `FeaturePack.setup(require_features_path:)` to allow booting without `app/feature_packs`
- Generator `add_feature` validates that the group controller defines `FeaturePack::<Group>Controller`

### Changed
- Generated feature controllers inherit `FeaturePack::<Group>Controller`; the group controller resolves
  group or feature context from the routed path (see README, "Migrating from 0.10.x")
- The view hooks `set_view_lookup_context_prefix` and `set_layout_paths` are shared by group and feature
  requests, so a group controller override applies to both
- Registry attributes raise `NotInitializedError` before `setup`, instead of `NoMethodError`/`NameError`
- A missing `app/feature_packs` directory fails `setup` unless `require_features_path: false` is passed
- Groups without `_group_space/controller.rb` are allowed (namespace-only groups)
- `ostruct` declared as a gem dependency (required by Ruby 3.5+); Gemfile now uses `gemspec`

### Fixed
- Failed `setup` now rolls back on `LoadError`/`SyntaxError` as well as `StandardError`
- View prefixes are added per request instead of mutating the controller class' shared prefix array
- Feature partial lookup passes a String prefix to ActionView (was a `Pathname`)
- Leftover `__after_initialize.rb` files are still ignored by Zeitwerk

### Removed
- `__after_initialize.rb` hooks (introduced in 0.10.0)

## [0.10.0] - 2025-08-03
### Added
- `__after_initialize.rb` hooks for groups and features

## [0.9.1] - 2025-08-03
### Changed
- Feature controller inheritance adjusted

## [0.9.0] - 2025-06-28
### Added
- Comprehensive inline documentation for all classes and methods
- Improved error handling with specific error classes
- Better validation in generators with helpful error messages
- Support for JavaScript directories in generators
- Detailed README with examples and troubleshooting guide

### Changed
- Refactored main FeaturePack module for better organization and maintainability
- Improved generator ID generation using timestamp format (YYMMDD)
- Enhanced controller error handling with proper exceptions

### Fixed
- Fixed typo in group_controller.rb (patials_path -> partials_path)
- Fixed inconsistent indentation in error.rb
- Corrected generator argument descriptions

## [0.4.0] 2024-10-25
- Reorganized group files to Group _group_space dir

## [0.3.1] 2024-08-30
- Fixes references to index, instead of home

## [0.2.0] 2024-05-05
- Moved `home` to `index` default action
- Pluralized `index` action as the rails convention, so 'car', becomes 'cars'

## [0.0.4] 2024-04-15
Renamed the project to `Feature Pack`.

## [0.0.2] 2024-04-15
Renamed the project to MicroResources due to ruby gem refuse to publish the previous name due to similarity with another gem.