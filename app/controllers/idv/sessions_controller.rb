module Idv
  class SessionsController < ApplicationController
    include IdvSession

    before_action :confirm_two_factor_authenticated

    helper_method :idv_profile_form

    def new
      @using_mock_vendor = pick_a_vendor == :mock
    end

    def create
      idv_params.merge!(profile_params)
      submit_profile
    end

    def dupe
    end

    private

    def submit_profile
      if idv_profile_form.submit(profile_params)
        redirect_to idv_finance_url
      elsif duplicate_ssn_error?
        flash[:error] = dupe_ssn_msg
        redirect_to idv_session_dupe_url
      else
        render :new
      end
    end

    def duplicate_ssn_error?
      form_errors = idv_profile_form.errors
      form_errors.include?(:ssn) && form_errors[:ssn].include?(dupe_ssn_msg)
    end

    def dupe_ssn_msg
      I18n.t('idv.errors.duplicate_ssn')
    end

    def idv_profile_form
      @_idv_profile_form ||= Idv::ProfileForm.new((idv_params || {}), current_user)
    end

    def profile_params
      params.require(:profile).permit(
        :first_name, :last_name, :dob, :ssn, :address1, :address2, :city, :state, :zipcode
      )
    end
  end
end
