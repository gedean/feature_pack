class FeaturePack::GroupController < ApplicationController
  prepend_before_action :setup_group
  def index; end

  private

  def setup_group
    set_group
    set_view_lookup_context_prefix
    set_layout_paths
  end

  def set_group
    group_name = params[:controller].split('/')[1].to_sym
    @group = FeaturePack.group(group_name)
  end

  def set_view_lookup_context_prefix
    return if lookup_context.prefixes.include?(@group.views_path)

    lookup_context.prefixes.prepend(@group.views_path)
  end

  def set_layout_paths
    patials_path = @group.views_path.concat('/partials')

    @header_layout_path = @group.view('partials/header') if template_exists?('header', patials_path, true)

    return unless template_exists?('footer', patials_path, true)

    @footer_layout_path = @group.view('partials/footer')
  end
end
