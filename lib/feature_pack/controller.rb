# Base controller for all feature controllers
# Handles the setup of features, views, and layouts
class FeaturePack::Controller < ApplicationController
  prepend_before_action :setup_feature

  # Default index action
  def index; end

  private

  # Main setup method that configures the feature environment
  def setup_feature
    set_group_and_feature
    set_view_lookup_context_prefix
    set_layout_paths
  end

  # Extracts and sets the group and feature from the controller path
  def set_group_and_feature
    group_name, feature_name = params['controller']
      .delete_prefix('feature_pack/')
      .split('/')
      .map(&:to_sym)
    
    @group = FeaturePack.group(group_name)
    @feature = FeaturePack.feature(group_name, feature_name)
    
    raise FeaturePack::Error::NoGroup, "Group '#{group_name}' not found" if @group.nil?
    raise FeaturePack::Error::NoDataError, "Feature '#{feature_name}' not found in group '#{group_name}'" if @feature.nil?
  end

  # Configures the view lookup path to include feature-specific views
  def set_view_lookup_context_prefix
    return if lookup_context.prefixes.include?(@feature.views_relative_path)

    lookup_context.prefixes.prepend(@feature.views_relative_path)
  end

  # Sets up header and footer layout paths with fallback logic
  # Search order:
  # 1. Feature-specific partials
  # 2. Group-level partials (fallback)
  # 3. Application default (if neither exists)
  def set_layout_paths
    feature_partials_path = @feature.views_relative_path.join('partials')
    group_partials_path = @feature.group.views_path.concat('/partials')

    # Set header layout
    if template_exists?('header', feature_partials_path, true)
      @header_layout_path = @feature.view('partials/header')
    elsif template_exists?('header', group_partials_path, true)
      @header_layout_path = @feature.group.view('partials/header')
    end

    # Set footer layout
    if template_exists?('footer', feature_partials_path, true)
      @footer_layout_path = @feature.view('partials/footer')
    elsif template_exists?('footer', group_partials_path, true)
      @footer_layout_path = @feature.group.view('partials/footer')
    end
  end
end
