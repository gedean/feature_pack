class FeaturePack::Controller < ApplicationController
  before_action :set_feature
  before_action :set_view_lookup_context_prefix
  before_action :set_layout_paths

  def home; end

  private

  def set_feature
    @feature = FeaturePack.feature *params['controller'].delete_prefix('feature_pack/').split('/').map(&:to_sym)
  end

  def set_view_lookup_context_prefix
    unless lookup_context.prefixes.include?(@feature.views_relative_path)
      lookup_context.prefixes.prepend(@feature.views_relative_path)
    end    
  end

  def set_layout_paths
=begin
    Header/Footer Lookup order

    - Feature dir/_partials, if not exists
      - Fallback to Group, if not exists
        - Fallback to Application's default header/footer
=end

    feature_partials_path = @feature.views_relative_path.join('partials')
    group_partials_path = @feature.group.views_path.concat('/partials')
    
    if template_exists?('header', feature_partials_path, true)
      @header_layout_path = @feature.view('partials/header')
    elsif template_exists?('header', group_partials_path, true)
      @header_layout_path = @feature.group.view('partials/header')
    end

    if template_exists?('footer', feature_partials_path, true)
      @footer_layout_path = @feature.view('partials/footer')
    elsif template_exists?('footer', group_partials_path, true)
      @footer_layout_path = @feature.group.view('partials/footer')
    end
  end
end
