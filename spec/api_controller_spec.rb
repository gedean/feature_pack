require_relative 'spec_helper'
require 'open3'
require 'rbconfig'
require 'action_controller'
require 'rack/mock'

RSpec.describe 'FeaturePack::API::Controller' do
  [true, false].each do |load_feature_pack|
    it "loads in a fresh process #{load_feature_pack ? 'with' : 'without'} the registry loaded first" do
      script = <<~RUBY_CODE
        require 'action_controller'
        #{"require 'feature_pack'" if load_feature_pack}
        require 'feature_pack/api/controller'
        abort 'Incorrect superclass' unless FeaturePack::API::Controller.superclass == ActionController::API
      RUBY_CODE
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby, '-I', File.expand_path('../lib', __dir__), '-e', script
      )

      expect(status.success?).to be(true), "API load failed:\n#{stdout}\n#{stderr}"
    end
  end

  it 'serves JSON through an API subclass without initializing the registry' do
    require_relative '../lib/feature_pack/api/controller'
    stub_const('FeaturePack::API::ProbeController', Class.new(FeaturePack::API::Controller) do
      def index
        render json: { status: 'ok' }
      end
    end)

    env = Rack::MockRequest.env_for('/')
    env['action_dispatch.request.path_parameters'] = { controller: 'feature_pack/api/probe', action: 'index' }
    status, headers, response = FeaturePack::API::ProbeController.action(:index).call(env)
    body = +''
    response.each { |part| body << part }

    expect(status).to eq(200)
    expect(headers.transform_keys(&:downcase)['content-type']).to include('application/json')
    expect(JSON.parse(body)).to eq('status' => 'ok')
    expect(FeaturePack).not_to be_initialized
  ensure
    response.close if response.respond_to?(:close)
  end
end
