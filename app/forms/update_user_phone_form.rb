class UpdateUserPhoneForm
  include ActiveModel::Model
  include FormPhoneValidator
  include CustomFormHelpers::PhoneHelpers

  attr_accessor :phone
  attr_reader :user

  def persisted?
    true
  end

  def initialize(user)
    @user = user
    self.phone = @user.phone
  end

  def submit(params)
    check_phone_change(params)

    valid?
  end
end
