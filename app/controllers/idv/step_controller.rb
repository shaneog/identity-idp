module Idv
  class StepController < ApplicationController
    include IdvSession

    helper_method :idv_params

    before_action :confirm_two_factor_authenticated
    before_action :confirm_idv_session_started
  end
end
