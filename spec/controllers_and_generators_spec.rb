require_relative 'spec_helper'
require 'action_controller'
require 'rack/mock'
require 'rails/generators'
require_relative '../lib/generators/feature_pack/add_group/add_group_generator'
require_relative '../lib/generators/feature_pack/add_feature/add_feature_generator'

class ApplicationController < ActionController::Base
end

require_relative '../lib/feature_pack/group_controller'
require_relative '../lib/feature_pack/controller'

RSpec.describe 'Generated controllers', :integration do
  around do |example|
    Dir.mktmpdir('feature_pack_integration') do |directory|
      Rails.feature_pack_test_root = Pathname.new(directory)
      FeaturePack.send(:reset_state!)
      FeaturePack.setup(require_features_path: false)
      FeaturePack::AddGroupGenerator.start(['finance', '--quiet'], destination_root: directory)
      reload_registry
      FeaturePack::AddFeatureGenerator.start(['finance/reports', '--quiet'], destination_root: directory)
      reload_registry

      FeaturePack.const_set(:Finance, Module.new)
      load FeaturePack.groups_controllers_paths.first
      load FeaturePack.features_controllers_paths.first
      FeaturePack::FinanceController.class_eval do
        before_action :authorize_group
        private
        def authorize_group
          head :forbidden unless request.get_header('HTTP_X_ALLOWED') == 'yes'
        end
      end
      [FeaturePack::FinanceController, FeaturePack::Finance::ReportsController].each do |controller|
        controller.prepend_view_path FeaturePack.features_path.to_s
      end
      @group = FeaturePack.group(:finance)
      @feature = @group.feature(:reports)
      write_view(@group.metadata_path.join('views/index.html.erb'), 'group:<%= @group.name %>')
      write_view(@feature.absolute_path.join('views/index.html.erb'),
                 'feature:<%= @feature.name %>;group:<%= @group.name %>')
      example.run
    ensure
      FeaturePack.send(:reset_state!)
      Rails.feature_pack_test_root = nil
      %i[FinanceController Finance].each do |name|
        FeaturePack.send(:remove_const, name) if FeaturePack.const_defined?(name, false)
      end
    end
  end

  it 'creates the first group and feature in a fresh application' do
    expect(@group).not_to be_nil
    expect(@feature).not_to be_nil
    expect(@feature.absolute_path.join('routes.rb')).to exist
    expect(FeaturePack::Finance::ReportsController.superclass).to eq(FeaturePack::FinanceController)
  end

  it 'rejects duplicate groups without changing existing files' do
    controller = @group.metadata_path.join('controller.rb')
    original = File.read(controller)
    generator = FeaturePack::AddGroupGenerator.new(['finance'])
    expect { generator.create_feature_group }.to raise_error(Thor::Error, /already exists/)
    expect(File.read(controller)).to eq(original)
  end

  it 'rejects duplicate features without changing existing files' do
    controller = @feature.absolute_path.join('controller.rb')
    original = File.read(controller)
    generator = FeaturePack::AddFeatureGenerator.new(['finance/reports'])
    expect { generator.add_feature }.to raise_error(Thor::Error, /already exists/)
    expect(File.read(controller)).to eq(original)
  end

  it 'enforces group authorization on both group and feature requests' do
    expect(request(FeaturePack::FinanceController, 'feature_pack/finance', allowed: false).first).to eq(403)
    feature_status = request(FeaturePack::Finance::ReportsController, 'feature_pack/finance/reports', allowed: false).first
    expect(feature_status).to eq(403)
  end

  it 'renders the group index using group context' do
    status, body = request(FeaturePack::FinanceController, 'feature_pack/finance')
    expect(status).to eq(200)
    expect(body).to eq('group:finance')
  end

  it 'renders the feature index with feature and group context' do
    status, body = request(FeaturePack::Finance::ReportsController, 'feature_pack/finance/reports')
    expect(status).to eq(200)
    expect(body).to eq('feature:reports;group:finance')
  end

  it 'prefers feature partials and falls back to group partials' do
    write_view(@feature.absolute_path.join('views/partials/_header.html.erb'), 'feature header')
    write_view(@group.metadata_path.join('views/partials/_footer.html.erb'), 'group footer')
    FileUtils.rm_f(@feature.absolute_path.join('views/partials/_footer.html.slim'))
    write_view(@feature.absolute_path.join('views/index.html.erb'),
               '<%= render @header_layout_path %>|<%= render @footer_layout_path %>')

    status, body = request(FeaturePack::Finance::ReportsController, 'feature_pack/finance/reports')
    expect(status).to eq(200)
    expect(body).to eq('feature header|group footer')
  end

  it 'renders group partials on group requests' do
    write_view(@group.metadata_path.join('views/partials/_header.html.erb'), 'group header')
    write_view(@group.metadata_path.join('views/partials/_footer.html.erb'), 'group footer')
    write_view(@group.metadata_path.join('views/index.html.erb'),
               '<%= render @header_layout_path %>|<%= render @footer_layout_path %>')

    status, body = request(FeaturePack::FinanceController, 'feature_pack/finance')
    expect(status).to eq(200)
    expect(body).to eq('group header|group footer')
  end

  it 'provides feature context before inherited authorization runs' do
    FeaturePack::FinanceController.class_eval do
      before_action do
        head :forbidden unless @group.name == :finance && @feature.name == :reports
      end
    end

    expect(request(FeaturePack::Finance::ReportsController, 'feature_pack/finance/reports').first).to eq(200)
  end

  it 'raises the domain error for an unknown group' do
    expect do
      request(FeaturePack::FinanceController, 'feature_pack/missing')
    end.to raise_error(FeaturePack::Error::NoGroup, /missing/)
  end

  it 'raises the domain error when a standalone controller names an unknown feature' do
    stub_const('FeaturePack::Finance::MissingController', Class.new(FeaturePack::Controller))
    expect do
      request(FeaturePack::Finance::MissingController, 'feature_pack/finance/missing')
    end.to raise_error(FeaturePack::Error::NoDataError, /missing/)
  end

  it 'applies group controller overrides of the view hooks to feature requests' do
    FeaturePack::FinanceController.class_eval do
      private

      def set_layout_paths
        @header_layout_path = 'custom/header'
      end
    end
    write_view(FeaturePack.features_path.join('custom/_header.html.erb'), 'custom header')
    write_view(@feature.absolute_path.join('views/index.html.erb'), '<%= render @header_layout_path %>')

    status, body = request(FeaturePack::Finance::ReportsController, 'feature_pack/finance/reports')
    expect(status).to eq(200)
    expect(body).to eq('custom header')
  end

  it 'resolves context from the routed path for controllers outside the namespace' do
    stub_const('Admin::FinanceController', Class.new(FeaturePack::FinanceController))
    Admin::FinanceController.prepend_view_path FeaturePack.features_path.to_s

    status, body = request(Admin::FinanceController, 'feature_pack/finance')
    expect(status).to eq(200)
    expect(body).to eq('group:finance')
  end

  it 'keeps internal prefixes out of view assigns' do
    write_view(@feature.absolute_path.join('views/index.html.erb'),
               '<%= controller.view_assigns.keys.sort.join(",") %>')

    _status, body = request(FeaturePack::Finance::ReportsController, 'feature_pack/finance/reports')
    expect(body).to eq('feature,footer_layout_path,group,header_layout_path')
  end

  it 'keeps group context for group sub-controllers served under a feature-like path' do
    stub_const('FeaturePack::Finance::AdminController', Class.new(FeaturePack::FinanceController))
    FeaturePack::Finance::AdminController.prepend_view_path FeaturePack.features_path.to_s

    status, body = request(FeaturePack::Finance::AdminController, 'feature_pack/finance/admin')
    expect(status).to eq(200)
    expect(body).to eq('group:finance')
  end

  it 'does not mutate class-level view prefixes across requests' do
    group_prefixes = FeaturePack::FinanceController._prefixes.dup
    feature_prefixes = FeaturePack::Finance::ReportsController._prefixes.dup

    request(FeaturePack::FinanceController, 'feature_pack/finance')
    request(FeaturePack::Finance::ReportsController, 'feature_pack/finance/reports')

    expect(FeaturePack::FinanceController._prefixes).to eq(group_prefixes)
    expect(FeaturePack::Finance::ReportsController._prefixes).to eq(feature_prefixes)
  end

  it 'refuses to generate a feature when the group controller class is missing' do
    FeaturePack.send(:remove_const, :FinanceController)
    File.write(@group.metadata_path.join('controller.rb'), "# class FeaturePack::FinanceController is missing\n")
    generator = FeaturePack::AddFeatureGenerator.new(['finance/payroll'])
    expect { generator.add_feature }.to raise_error(Thor::Error, /does not define FeaturePack::FinanceController/)
  end

  [true, false].each do |preloaded|
    it "accepts nested module declarations with the group controller #{preloaded ? 'loaded' : 'not loaded'}" do
      FeaturePack.send(:remove_const, :FinanceController)
      controller_path = @group.metadata_path.join('controller.rb')
      File.write(controller_path, <<~RUBY)
        module FeaturePack
          class FinanceController < GroupController
          end
        end
      RUBY
      load controller_path if preloaded

      generator = FeaturePack::AddFeatureGenerator.new(['finance/payroll'], quiet: true)
      expect { generator.add_feature }.not_to raise_error
      reload_registry
      load FeaturePack.feature(:finance, :payroll).absolute_path.join('controller.rb')
      expect(FeaturePack::Finance::PayrollController.superclass).to eq(FeaturePack::FinanceController)
    end
  end

  it 'rejects a group controller constant that is not a class before writing files' do
    FeaturePack.send(:remove_const, :FinanceController)
    File.write(@group.metadata_path.join('controller.rb'), "module FeaturePack::FinanceController; end\n")
    generator = FeaturePack::AddFeatureGenerator.new(['finance/payroll'], quiet: true)

    expect { generator.add_feature }.to raise_error(Thor::Error, /does not define FeaturePack::FinanceController/)
    expect(Dir.glob(@group.relative_path.join('feature_*_payroll').to_s)).to be_empty
  end

  it 'still configures standalone feature controllers' do
    stub_const('FeaturePack::Finance::ReportsController', Class.new(FeaturePack::Controller))
    FeaturePack::Finance::ReportsController.prepend_view_path FeaturePack.features_path.to_s
    status, body = request(FeaturePack::Finance::ReportsController, 'feature_pack/finance/reports')
    expect(status).to eq(200)
    expect(body).to eq('feature:reports;group:finance')
  end

  def reload_registry
    FeaturePack.send(:reset_state!)
    FeaturePack.setup
  end

  def write_view(path, content)
    FileUtils.mkdir_p(path.dirname)
    File.write(path, content)
  end

  def request(controller, path, allowed: true)
    env = Rack::MockRequest.env_for('/', 'HTTP_X_ALLOWED' => allowed ? 'yes' : 'no')
    env['action_dispatch.request.path_parameters'] = { controller: path, action: 'index' }
    status, _headers, response = controller.action(:index).call(env)
    body = +''
    response.each { |part| body << part }
    response.close if response.respond_to?(:close)
    [status, body]
  end
end
