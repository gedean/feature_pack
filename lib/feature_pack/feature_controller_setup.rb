require_relative '../feature_pack'

# Request setup shared by group controllers, feature controllers that inherit
# their group controller, and standalone feature controllers
# (FeaturePack::Controller).
#
# The group and feature are resolved from the routed controller path
# ("feature_pack/<group>[/<feature>]"). When the second segment names a
# registered feature the request gets feature context (@group and @feature);
# otherwise it gets group context (@group only). No opt-in is required, so a
# controller can never silently receive the wrong setup.
module FeaturePack::FeatureControllerSetup
  ROUTE_NAMESPACE = 'feature_pack/'.freeze
  PROTECTED_IVARS = %i[@_feature_pack_prefixes].freeze

  # Implicit rendering and the lookup context both read `_prefixes`.
  # Override it per instance so a request-specific prefix never leaks into the
  # controller class' memoized array (which subclasses share by reference).
  def _prefixes
    @_feature_pack_prefixes || super
  end

  # Keep the internal prefix array out of view assigns
  def _protected_ivars
    super + PROTECTED_IVARS
  end

  private

  # Resolves group and feature from the route and configures the request.
  # Used by GroupController (and everything inheriting it).
  def setup_feature_pack_context
    group_name, feature_name = feature_pack_route_segments
    set_group(group_name)
    @feature = @group.feature(feature_name) if feature_name

    set_view_lookup_context_prefix
    set_layout_paths
  end

  # Configures a request that must resolve to a feature (FeaturePack::Controller).
  def setup_feature
    set_group_and_feature
    set_view_lookup_context_prefix
    set_layout_paths
  end

  # @return [Array<Symbol>] [group_name, feature_name]; feature_name may be nil
  def feature_pack_route_segments
    path = (params[:controller] || controller_path).to_s
    path.delete_prefix(ROUTE_NAMESPACE).split('/').first(2).map(&:to_sym)
  end

  def set_group(group_name)
    @group = FeaturePack.group(group_name)
    raise FeaturePack::Error::NoGroup, "Group '#{group_name}' not found" if @group.nil?
  end

  # Extracts and sets the group and feature from the controller path
  def set_group_and_feature
    group_name, feature_name = feature_pack_route_segments
    set_group(group_name)

    @feature = @group.feature(feature_name)
    return unless @feature.nil?

    raise FeaturePack::Error::NoDataError, "Feature '#{feature_name}' not found in group '#{group_name}'"
  end

  # Configures the view lookup path to include feature (or group) views.
  # Overridable in group controllers; applies to group and feature requests.
  def set_view_lookup_context_prefix
    prepend_view_prefix(@feature ? @feature.views_relative_path : @group.views_path)
  end

  # Sets up header and footer layout paths with fallback logic
  # Search order:
  # 1. Feature-specific partials (feature requests only)
  # 2. Group-level partials
  # 3. Application default (if neither exists)
  def set_layout_paths
    @header_layout_path = resolve_layout_partial('header')
    @footer_layout_path = resolve_layout_partial('footer')
  end

  def prepend_view_prefix(prefix)
    prefix = prefix.to_s
    return if _prefixes.include?(prefix)

    @_feature_pack_prefixes = [prefix, *_prefixes].freeze
    lookup_context.prefixes = @_feature_pack_prefixes if defined?(@_lookup_context) && @_lookup_context
  end

  # @return [String, nil] the view path of the first existing partial
  def resolve_layout_partial(name)
    layout_partial_candidates.each do |partials_prefix, view_path|
      return format(view_path, name) if template_exists?(name, partials_prefix, true)
    end
    nil
  end

  # @return [Array<Array(String, String)>] pairs of [partials_prefix, view path format with %s for the name]
  def layout_partial_candidates
    candidates = []
    if @feature
      candidates << [@feature.views_relative_path.join('partials').to_s, @feature.view('partials/%s')]
    end
    candidates << ["#{@group.views_path}/partials", @group.view('partials/%s')]
    candidates
  end
end
