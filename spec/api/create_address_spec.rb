require 'rails_helper'

describe 'POST /locations/:location_id/address' do
  context 'when location does not already have an address' do
    before(:all) do
      @loc = create(:no_address)
    end

    before do
      @attrs = { address_1: 'foo', city: 'bar', state_province: 'CA',
                 postal_code: '90210', country: 'US' }
    end

    after(:all) do
      Organization.find_each(&:destroy)
    end

    it 'creates an address with valid attributes' do
      post api_location_address_index_url(@loc, subdomain: ENV.fetch('API_SUBDOMAIN', nil)),
           @attrs

      expect(response).to have_http_status(:created)
      expect(json['address_1']).to eq(@attrs[:address_1])
    end

    it 'creates the address for the right location' do
      post api_location_address_index_url(@loc, subdomain: ENV.fetch('API_SUBDOMAIN', nil)),
           @attrs

      get api_location_url(@loc, subdomain: ENV.fetch('API_SUBDOMAIN', nil))
      expect(json['address']['address_1']).to eq(@attrs[:address_1])
    end

    it "doesn't create an address with invalid attributes" do
      post api_location_address_index_url(@loc, subdomain: ENV.fetch('API_SUBDOMAIN', nil)),
           address_1: nil

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json['errors'].first['address_1']).
        to eq(["can't be blank for Address"])
    end

    it "doesn't allow creating a address without a valid token" do
      post(
        api_location_address_index_url(@loc, subdomain: ENV.fetch('API_SUBDOMAIN', nil)),
        @attrs,
        'HTTP_X_API_TOKEN' => 'invalid_token'
      )
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when location already has an address' do
    before(:all) do
      @loc = create(:location)
    end

    before do
      @attrs = { address_1: 'foo', city: 'bar', state_province: 'CA',
                 postal_code: '90210', country: 'US' }
      post api_location_address_index_url(@loc, subdomain: ENV.fetch('API_SUBDOMAIN', nil)), @attrs
    end

    after(:all) do
      Organization.find_each(&:destroy)
    end

    it "doesn't create a new address if one already exists" do
      expect(Address.count).to eq 1
    end

    it "does not change the location's current address" do
      get api_location_url(@loc, subdomain: ENV.fetch('API_SUBDOMAIN', nil))
      expect(json['address']['address_1']).to eq '1800 Easton Drive'
    end
  end
end
