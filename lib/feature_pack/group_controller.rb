require_relative 'feature_controller_setup'

# Base controller for all group controllers.
#
# Feature controllers inherit their group controller, so group callbacks
# (authentication, authorization...) apply to every feature. The setup callback
# resolves group or feature context from the route, so no extra declaration is
# needed in feature controllers.
class FeaturePack::GroupController < ApplicationController
  include FeaturePack::FeatureControllerSetup
  prepend_before_action :setup_feature_pack_context

  # Default index action
  def index; end
end
