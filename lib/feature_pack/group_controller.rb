# Base controller for all group controllers
# Handles the setup of groups and their views
class FeaturePack::GroupController < ApplicationController
  prepend_before_action :setup_group
  
  # Default index action
  def index; end

  private

  # Main setup method that configures the group environment
  def setup_group
    set_group
    set_view_lookup_context_prefix
    set_layout_paths
  end

  # Extracts and sets the group from the controller path
  def set_group
    group_name = params[:controller].split('/')[1].to_sym
    @group = FeaturePack.group(group_name)
    
    raise FeaturePack::Error::NoGroup, "Group '#{group_name}' not found" if @group.nil?
  end

  # Configures the view lookup path to include group-specific views
  def set_view_lookup_context_prefix
    return if lookup_context.prefixes.include?(@group.views_path)

    lookup_context.prefixes.prepend(@group.views_path)
  end

  # Sets up header and footer layout paths for the group
  def set_layout_paths
    partials_path = @group.views_path.concat('/partials')

    if template_exists?('header', partials_path, true)
      @header_layout_path = @group.view('partials/header')
    end

    if template_exists?('footer', partials_path, true)
      @footer_layout_path = @group.view('partials/footer')
    end
  end
end
