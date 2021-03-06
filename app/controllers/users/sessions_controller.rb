module Users
  class SessionsController < Devise::SessionsController
    include ::ActionView::Helpers::DateHelper

    skip_before_action :session_expires_at, only: [:active]

    def create
      track_authentication_attempt(params[:user][:email])
      super
    end

    def active
      response.headers['Etag'] = '' # clear etags to prevent caching
      Rails.logger.debug("alive?:#{alive?} expires_at:#{expires_at} now:#{Time.zone.now}")
      render json: { live: alive?, timeout: expires_at }
    end

    def timeout
      if sign_out
        analytics.track_event('Session Timed Out')
        flash[:timeout] = t('session_timedout')
      end
      redirect_to root_url
    end

    private

    def expires_at
      @_expires_at ||= (session[:session_expires_at] || (Time.zone.now - 1))
    end

    def alive?
      return false unless session && expires_at
      session_alive = expires_at > Time.zone.now
      current_user.present? && session_alive
    end

    def track_authentication_attempt(email)
      existing_user = User.find_by_email(email)

      if existing_user
        return analytics.track_event('Authentication Attempt', user_id: existing_user.uuid)
      end

      analytics.track_event('Authentication Attempt with nonexistent user')
    end
  end
end
