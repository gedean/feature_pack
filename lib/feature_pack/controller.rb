class FeaturePack::Controller < ApplicationController
  prepend_before_action :setup_feature

  def index; end

  private

  def setup_feature
    set_group_and_feature
    set_view_lookup_context_prefix
    set_layout_paths
  end

  def set_group_and_feature
    group_name, feature_name = params['controller'].delete_prefix('feature_pack/').split('/').map(&:to_sym)
    @group = FeaturePack.group group_name
    @feature = FeaturePack.feature group_name, feature_name
  end

  def set_view_lookup_context_prefix
    return if lookup_context.prefixes.include?(@feature.views_relative_path)

    lookup_context.prefixes.prepend(@feature.views_relative_path)
  end

  def set_layout_paths
    #     Header/Footer Lookup order
    #
    #     - Feature dir/_partials, if not exists
    #       - Fallback to Group, if not exists
    #         - Fallback to Application's default header/footer

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
