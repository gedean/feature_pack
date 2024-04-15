class MicroResources::Controller < ApplicationController
  before_action :set_micro_resources
  before_action :set_view_lookup_context_prefix
  before_action :set_layout_paths

  def home; end

  private

  def set_micro_resources
    @micro_resources = MicroResources.micro_resources *params['controller'].delete_prefix('micro_resources/').split('/').map(&:to_sym)
  end

  def set_view_lookup_context_prefix
    unless lookup_context.prefixes.include?(@micro_resources.views_relative_path)
      lookup_context.prefixes.prepend(@micro_resources.views_relative_path)
    end    
  end

  def set_layout_paths
    # MicroResources Header
    # Fallback to Group
    # Fallback to Application default header

    micro_resources_partials_path = @micro_resources.views_relative_path.join('partials')
    group_partials_path = @micro_resources.group.views_path.concat('/partials')
    
    if template_exists?('header', micro_resources_partials_path, true)
      @header_layout_path = @micro_resources.view('partials/header')
    elsif template_exists?('header', group_partials_path, true)
      @header_layout_path = @micro_resources.group.view('partials/header')
    end

    if template_exists?('footer', micro_resources_partials_path, true)
      @footer_layout_path = @micro_resources.view('partials/footer')
    elsif template_exists?('footer', group_partials_path, true)
      @footer_layout_path = @micro_resources.group.view('partials/footer')
    end
  end
end
