require 'rails_helper'

describe Idv::ReviewController do
  let(:user) { create(:user, :signed_up, email: 'old_email@example.com') }
  let(:user_attrs) do
    {
      first_name: 'Some',
      last_name: 'One',
      ssn: '666661234',
      dob: 'March 29, 1972',
      address1: '123 Main St',
      address2: '',
      city: 'Somewhere',
      state: 'KS',
      zipcode: '66044',
      phone: user.phone,
      ccn: '12345678'
    }
  end

  describe 'before_actions' do
    it 'includes before_actions from AccountStateChecker' do
      expect(subject).to have_actions(
        :before,
        :confirm_two_factor_authenticated,
        :confirm_idv_session_started,
        :confirm_idv_steps_complete
      )
    end
  end

  describe '#confirm_idv_steps_complete' do
    controller do
      before_action :confirm_idv_steps_complete

      def show
        render text: 'Hello'
      end
    end

    before(:each) do
      sign_in(user)
      routes.draw do
        get 'show' => 'idv/review#show'
      end
    end

    context 'user has missed phone step' do
      before do
        allow(subject).to receive(:idv_session).and_return(
          params: user_attrs.reject { |key| key == :phone }
        )
      end

      it 'redirects to phone step' do
        get :show

        expect(response).to redirect_to idv_phone_path
      end
    end

    context 'user has missed finance step' do
      before do
        allow(subject).to receive(:idv_session).and_return(
          params: user_attrs.reject { |key| key == :ccn }
        )
      end

      it 'redirects to finance step' do
        get :show

        expect(response).to redirect_to idv_finance_path
      end
    end
  end

  describe '#new' do
    before do
      allow(subject).to receive(:confirm_two_factor_authenticated).and_return(true)
      allow(subject).to receive(:confirm_idv_session_started).and_return(true)
      allow(subject).to receive(:current_user).and_return(user)
    end

    context 'user has completed all steps' do
      before do
        allow(subject).to receive(:idv_session).and_return(params: user_attrs)
      end

      it 'shows completed session' do
        get :new

        expect(response).to render_template :new
      end
    end
  end

  describe '#create' do
    before do
      sign_in(user)
      allow(subject).to receive(:confirm_two_factor_authenticated).and_return(true)
      allow(subject).to receive(:confirm_idv_session_started).and_return(true)
      allow(subject).to receive(:current_user).and_return(user)
    end

    context 'user has completed all steps' do
      before do
        allow(subject).to receive(:idv_session).and_return(
          params: user_attrs.merge(phone_confirmed_at: Time.zone.now)
        )
      end

      it 'redirects to questions path' do
        put :create

        expect(response).to redirect_to idv_questions_path
      end
    end

    context 'user has entered different phone number from MFA' do
      before do
        allow(subject).to receive(:idv_session).and_return(
          params: user_attrs.merge(phone: '213-555-1000')
        )
      end

      it 'redirects to phone confirmation path' do
        put :create

        expect(response).to redirect_to idv_phone_confirmation_send_path
      end
    end
  end
end
