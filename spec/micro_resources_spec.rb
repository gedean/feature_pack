require 'spec_helper'
require_relative '../lib/micro_resources'

RSpec.describe MicroResources do
    describe ".setup" do
        it "is true" do
           expect(MicroResources.setup).to be_truthy
        end
    end
end