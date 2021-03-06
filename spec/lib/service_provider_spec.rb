require 'rails_helper'

describe ServiceProvider do
  describe '#issuer' do
    it 'returns the constructor value' do
      sp = ServiceProvider.new('http://localhost:3000')
      expect(sp.issuer).to eq 'http://localhost:3000'
    end
  end

  describe '#metadata' do
    shared_examples 'invalid service provider' do
      it 'returns a hash with only fingerprint' do
        sp_attributes = { fingerprint: nil }

        expect(@service_provider.metadata).to eq sp_attributes
      end
    end

    context 'when the service provider is defined in the YAML' do
      it 'returns a hash with symbolized attributes from YAML plus fingerprint' do
        service_provider = ServiceProvider.new('http://localhost:3000')

        fingerprint = {
          fingerprint: '40808e52ef80f92e697149e058af95f898cefd9a54d0dc2416bd607c8f9891fa'
        }

        yaml_attributes = ServiceProviderConfig.new(
          issuer: 'http://localhost:3000'
        ).sp_attributes

        expect(service_provider.metadata).to eq yaml_attributes.merge!(fingerprint)
      end
    end

    context 'when the service provider is not defined in the YAML' do
      before { @service_provider = ServiceProvider.new('invalid_host') }

      it_behaves_like 'invalid service provider'
    end

    context 'when the app is running on a superb legit domain' do
      before do
        allow(Figaro.env).to receive(:domain_name).and_return('superb.legit.domain.gov')
        ServiceProviderConfig.fetch_providers_from_domain_name_or_rails_env
      end

      after do
        allow(Figaro.env).to receive(:domain_name).and_return('')
        ServiceProviderConfig.fetch_providers_from_domain_name_or_rails_env
      end

      context 'when the host is valid in the current env but not on the legit domain' do
        before { @service_provider = ServiceProvider.new('http://test.host') }

        it_behaves_like 'invalid service provider'
      end

      context 'when the host is valid on the legit domain' do
        it 'uses the config from the domain_name key' do
          service_provider = ServiceProvider.new('urn:govheroku:serviceprovider')

          yaml_attributes = ServiceProviderConfig.new(
            issuer: 'urn:govheroku:serviceprovider'
          ).sp_attributes

          fingerprint = {
            fingerprint: '40808e52ef80f92e697149e058af95f898cefd9a54d0dc2416bd607c8f9891fa'
          }

          expect(service_provider.metadata).to eq yaml_attributes.merge!(fingerprint)
        end
      end
    end
  end

  describe '#encryption_opts' do
    context 'when responses are not encrypted' do
      it 'returns nil' do
        # block_encryption is set to 'none' for this SP
        sp = ServiceProvider.new('http://localhost:3000')

        expect(sp.encryption_opts).to be_nil
      end
    end

    context 'when responses are encrypted' do
      it 'returns a hash with cert, block_encryption, and key_transport keys' do
        # block_encryption is 'aes256-cbc' for this SP
        sp = ServiceProvider.new('https://rp1.serviceprovider.com/auth/saml/metadata')

        expect(sp.encryption_opts.keys).to eq [:cert, :block_encryption, :key_transport]
        expect(sp.encryption_opts[:block_encryption]).to eq 'aes256-cbc'
        expect(sp.encryption_opts[:key_transport]).to eq 'rsa-oaep-mgf1p'
        expect(sp.encryption_opts[:cert]).to be_an_instance_of(OpenSSL::X509::Certificate)
      end

      it 'calls OpenSSL::X509::Certificate with the SP cert' do
        sp = ServiceProvider.new('https://rp1.serviceprovider.com/auth/saml/metadata')
        cert = File.read("#{Rails.root}/certs/sp/saml_test_sp.crt")

        expect(OpenSSL::X509::Certificate).to receive(:new).with(cert)

        sp.encryption_opts
      end
    end
  end
end
