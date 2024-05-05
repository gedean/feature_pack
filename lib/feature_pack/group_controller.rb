class FeaturePack::GroupController < ApplicationController
  before_action :set_group
  before_action :set_view_lookup_context_prefix
  before_action :set_layout_paths

  def index; end

  private 

  def set_group
    group_name = params[:controller].split('/')[1].to_sym
    @group = FeaturePack.group(group_name) 
  end

  def set_view_lookup_context_prefix
    unless lookup_context.prefixes.include?(@group.views_path)
      lookup_context.prefixes.prepend(@group.views_path)
    end
  end

  def set_layout_paths
    patials_path = @group.views_path.concat('/partials')
    
    if template_exists?('header', patials_path, true)
      @header_layout_path = @group.view('partials/header')
    end

    if template_exists?('footer', patials_path, true)
      @footer_layout_path = @group.view('partials/footer')
    end    
  end
end
