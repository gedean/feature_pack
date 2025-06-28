# Changelog

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