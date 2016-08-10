# Methods related to fallback support during phone confirmation
# eg. confirm with Voice OTP when first choice was SMS and
#  		SMS when first choice was Voice OTP

module OtpDeliveryFallback
  extend ActiveSupport::Concern

  included do
    before_action :set_fallback_vars, only: :confirm
  end

  def fallback_confirmation_link
    if sms_enabled?
      otp_new_path(delivery_method: :voice)
    else
      otp_new_path(delivery_method: :sms)
    end
  end

  def set_fallback_vars
    @fallback_confirmation_link = fallback_confirmation_link
    @sms_enabled = sms_enabled?
    @current_otp_delivery_method = current_otp_delivery_method
  end

  def sms_enabled?
    current_otp_delivery_method == 'sms'
  end

  def current_otp_delivery_method
    [params[:delivery_method]].find { |type| /sms|voice|totp/ =~ type }
  end

  def use_sms_or_voice_otp_delivery?
    current_otp_delivery_method.try(:match, /sms|voice/)
  end
end
