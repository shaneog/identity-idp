module Users
  class PhoneConfirmationController < ApplicationController
    before_action :authenticate_user!
    before_action :check_for_unconfirmed_phone

    def show
      @code_value = confirmation_code if FeatureManagement.prefill_otp_codes?
      @unconfirmed_phone = unconfirmed_phone
      @reenter_phone_number_path = if current_user.phone.present?
                                     profile_path
                                   else
                                     phone_setup_path
                                   end
    end

    def send_code
      send_confirmation_code
      redirect_to phone_confirmation_path
    end

    def confirm
      if params['code'] == confirmation_code
        process_valid_code
      else
        process_invalid_code
      end
    end

    def self.generate_confirmation_code
      digits = Devise.direct_otp_length
      random_base10(digits)
    end

    def self.random_base10(digits)
      SecureRandom.random_number(10**digits).to_s.rjust(digits, '0')
    end

    private

    def process_invalid_code
      analytics.track_event('User entered invalid phone confirmation code')
      flash[:error] = t('errors.invalid_confirmation_code')
      redirect_to phone_confirmation_path
    end

    def process_valid_code
      old_phone = current_user.phone
      current_user.update(phone: unconfirmed_phone, phone_confirmed_at: Time.current)
      clear_session_data

      flash[:success] = t('notices.phone_confirmation_successful')
      if old_phone.present?
        after_phone_number_change(old_phone)
      else
        after_initial_confirmation
      end
    end

    def after_phone_number_change(old_phone)
      analytics.track_event('User updated their phone number')
      create_user_event(:phone_changed)
      SmsSenderNumberChangeJob.perform_later(old_phone)

      redirect_to profile_path
    end

    def after_initial_confirmation
      analytics.track_event('User confirmed their phone number')
      create_user_event(:phone_confirmed)

      redirect_to after_sign_in_path_for(current_user)
    end

    def check_for_unconfirmed_phone
      redirect_to root_path unless unconfirmed_phone
    end

    def send_confirmation_code
      # Generate a new confirmation code only if there isn't already one set in the
      # user's session. Re-sending the confirmation code doesn't generate a new one.
      if confirmation_code.nil?
        self.confirmation_code = PhoneConfirmationController.generate_confirmation_code
      end

      SmsSenderOtpJob.perform_later(confirmation_code, unconfirmed_phone)
    end

    def confirmation_code=(code)
      user_session[:phone_confirmation_code] = code
    end

    def confirmation_code
      user_session[:phone_confirmation_code]
    end

    def unconfirmed_phone
      user_session[:unconfirmed_phone]
    end

    def clear_session_data
      user_session.delete(:unconfirmed_phone)
      user_session.delete(:phone_confirmation_code)
    end
  end
end
