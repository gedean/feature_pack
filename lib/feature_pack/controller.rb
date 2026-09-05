require_relative 'feature_controller_setup'

# Base controller for features without a custom group controller.
class FeaturePack::Controller < ApplicationController
  include FeaturePack::FeatureControllerSetup
  prepend_before_action :setup_feature

  def index; end
end
