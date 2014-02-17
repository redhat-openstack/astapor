# For manual test user:
# rspec spec/configuration_spec.rb --format doc
require './spec/spec_helper'

describe Configuration do
  describe Hostgroups do
    before :all do
      @hostgroups = Hostgroups.new('./config/hostgroups.yaml')
    end

    it 'responds to #get' do
      expect(@hostgroups).to respond_to(:get)
    end

    it 'responds to #to_s' do
      expect(@config).to respond_to(:to_s)
    end

    it '#get produces an Array of right size' do
      expect(@hostgroups.get.size).to equal(12)
    end
  end

  describe Setup do
    before :all do
      @setup = Setup.new('./config/install.yaml')
    end

    it 'responds to #get' do
      expect(@setup).to respond_to(:get)
    end

    it 'responds to #to_s' do
      expect(@config).to respond_to(:to_s)
    end

    it '#debug provides a boolean' do
      expect(@setup.debug).to equal(false)
    end

    it 'responds to #quickstack ' do
      expect(@setup).to respond_to(:quickstack)
    end

    it 'responds to #foreman_provisioning ' do
      expect(@setup).to respond_to(:foreman_provisioning)
    end

    it 'responds to #hostgroups ' do
      expect(@setup).to respond_to(:hostgroups)
    end
  end

  describe Quickstack do
    before :all do
      @config = Quickstack.new('./config/quickstack.yaml.erb')
    end

    it 'responds to #get' do
      expect(@config).to respond_to(:get)
    end

    it 'responds to #to_s' do
      expect(@config).to respond_to(:to_s)
    end

    it '#get produces a Hash of right size' do
      expect(@config.get.size).to equal(135)
    end

    context 'with automatic password assigned' do
      it "must be different" do
        params = @config.get
        expect(params['ceilometer_user_password']).not_to eq(params['cinder_db_password'])
      end
    end
  end
end
