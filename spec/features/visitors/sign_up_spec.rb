require 'rails_helper'

# Feature: Sign up
#   As a visitor
#   I want to sign up
#   So I can visit protected areas of the site

VALID_PASSWORD = 'Val!dPassw0rd'.freeze
INVALID_PASSWORD = 'asdf'.freeze

feature 'Sign Up', devise: true do
  context 'new user visits sign up page' do
    before { visit new_user_registration_url }

    it 'has a localized title' do
      expect(page).to have_title t('upaya.titles.registrations.new')
    end

    it 'has a localized heading' do
      expect(page).to have_content t('upaya.headings.registrations.new')
    end

    # it 'explains what the email address will be used for' do
    #   expect(page).to have_content t('upaya.forms.registration.email_field')
    # end

    it 'links to Terms of Use' do
      skip 'waiting for OMB approval'
      click_link 'Terms of Use'
      expect(page).to have_content('Prohibitions')
    end
  end

  # Scenario: Visitor can sign up with valid email address and password
  #   Given I am not signed in
  #   When I sign up with a valid email address and password
  #   Then I see a successful sign up message
  scenario 'visitor can sign up with valid email address and password' do
    sign_up_with('test@example.com')
    expect(page).to have_content(
      t('devise.registrations.signed_up_but_unconfirmed', email: 'test@example.com')
    )
  end

  # Scenario: Visitor can sign up and confirm with valid email address and password
  #   Given I am not signed in
  #   When I sign up with a valid email address and password and click my confirmation link
  #   Then I see a successful confirmation message
  scenario 'visitor can sign up and confirm a valid email' do
    sign_up_with('test@example.com')

    confirm_last_user

    expect(page).to have_content t('devise.confirmations.confirmed')
    expect(page).to have_title t('upaya.titles.confirmations.show')
    expect(page).to have_content t('upaya.forms.confirmation.show_hdr')

    fill_in 'user[password]', with: VALID_PASSWORD
    fill_in 'user[password_confirmation]', with: VALID_PASSWORD
    click_button 'Submit'

    expect(page).to have_content I18n.t('devise.two_factor_authentication.otp_setup')
  end

  scenario 'user#reset_account is called after password confirmation' do
    sign_up_with('test@example.com')

    confirm_last_user

    fill_in 'user[password]', with: VALID_PASSWORD
    fill_in 'user[password_confirmation]', with: VALID_PASSWORD

    expect_any_instance_of(User).to receive(:reset_account)

    click_button 'Submit'
  end

  # Scenario: Visitor is given option to receive OTP via both email & mobile
  #   Given I am not signed in
  #   When I sign up with a valid email address and password and click my confirmation link
  #   Then I am prompted to choose a method for receiving one-time passwords (OTPs)
  #   And I see that both mobile and email are selected by default
  scenario 'visitor sees both email and mobile checked by default' do
    sign_up_with_and_set_password_for('test@example.com')

    expect(find('#user_second_factor_ids_email')).to be_checked
    expect(find('#user_second_factor_ids_mobile')).to be_checked
  end

  scenario 'form should have autocomplete turned off' do
    sign_up_with_and_set_password_for('test@example.com')
    expect(find('#edit_user')[:autocomplete]).to eq 'off'
  end

  # Scenario: Visitor can sign up, confirm email, and setup 2FA
  #   Given I am not signed in
  #   When I sign up, confirm email, and setup 2FA
  #   Then I see the dashboard
  context 'visitor can sign up and confirm a valid email for OTP', email: true do
    before do
      sign_up_with_and_set_password_for('test@example.com')
      check 'Email'
      uncheck 'Mobile'
      click_button 'Submit'
    end

    it 'sends an email with an OTP' do
      open_email('test@example.com')

      expect(last_email.body).to have_content 'Please enter this secure one-time password:'
    end

    it 'allows the user to sign in with the emailed OTP' do
      otp = last_email.body.match(/secure one-time password: (\w*)/)

      fill_in 'Secure one-time password', with: otp[1]
      click_button 'Submit'

      expect(page).to have_content I18n.t('devise.two_factor_authentication.success')
      expect(User.find_by_email('test@example.com').second_factor_confirmed_at).to be_present
    end

    it 'does not include a link to enter a number again' do
      expect(page).to_not have_link 'entering it again'
    end

    it 'does not update mobile_confirmed_at' do
      otp = last_email.body.match(/secure one-time password: (\w*)/)

      fill_in 'Secure one-time password', with: otp[1]
      click_button 'Submit'

      expect(User.find_by_email('test@example.com').mobile_confirmed_at).to be_nil
    end

    it 'disables OTP lockout during account creation' do
      Devise.max_login_attempts.times do
        fill_in 'Secure one-time password', with: '12345678'
        click_button 'Submit'
      end

      expect(page).to_not have_content t('upaya.titles.account_locked')
      visit user_two_factor_authentication_path
      expect(current_path).to eq user_two_factor_authentication_path
    end
  end

  context 'visitor can sign up and confirm a valid mobile for OTP' do
    before do
      sign_up_with_and_set_password_for('test@example.com')
      check 'Mobile'
      fill_in 'Mobile', with: '555-555-5555'
      click_button 'Submit'
    end

    it 'updates mobile_confirmed_at and second_factor_confirmed_at' do
      user = User.find_by_email('test@example.com')

      fill_in 'Secure one-time password', with: user.reload.otp_code
      click_button 'Submit'

      expect(user.reload.mobile_confirmed_at).to be_present
      expect(user.reload.second_factor_confirmed_at).to be_present
    end

    it 'provides user with link to type in a new number so they are not locked out' do
      click_link 'entering it again'
      expect(current_path).to eq users_otp_path
    end

    it 'allows user to enter new number if they Sign Out before confirming' do
      click_link(t('upaya.headings.log_out'), match: :first)
      user = User.find_by_email('test@example.com')
      signin(user.email, VALID_PASSWORD)
      expect(current_path).to eq users_otp_path
    end

    it 'disables mobile 2FA after Sign Out if user has no mobile' do
      user = User.find_by_email('test@example.com')
      click_link(t('upaya.headings.log_out'), match: :first)
      expect(user.reload.second_factors.pluck(:name)).to_not include('Mobile')
    end
  end

  context 'visitor can confirm mobile 2FA device when email is also selected', email: true do
    before do
      sign_up_with_and_set_password_for('test@example.com')
      check 'Mobile'
      fill_in 'Mobile', with: '555-555-5555'
      check 'Email'
      click_button 'Submit'
    end

    it 'does not send the OTP via email so the mobile OTP option can be confirmed' do
      expect(last_email.subject).to eq t('devise.mailer.confirmation_instructions.subject')
      expect(last_email.body).
        to match('To finish creating your Upaya Account, you must confirm your email address')
    end

    it 'informs the user that the OTP code is only sent to the mobile' do
      user = User.find_by_email('test@example.com')

      expect(page).
        to have_content(
          "A one-time passcode has been sent to #{user.unconfirmed_mobile}. " \
          'Please enter the code that you received. ' \
          'If you do not receive the code in 10 minutes, please request a new passcode.'
        )
    end

    it 'provides user with link to type in a new number so they are not locked out' do
      click_link 'entering it again'
      expect(current_path).to eq users_otp_path
    end

    # JJG - I think we should go as far as making sure the user enters
    # a new number and that the OTP is sent to the new number.
    it 'allows user to enter new number if they Sign Out before confirming' do
      click_link(t('upaya.headings.log_out'), match: :first)
      user = User.find_by_email('test@example.com')
      signin(user.email, VALID_PASSWORD)
      expect(current_path).to eq users_otp_path
    end

    it 'disables mobile 2FA after Sign Out if user has no mobile' do
      user = User.find_by_email('test@example.com')
      click_link(t('upaya.headings.log_out'), match: :first)
      expect(user.reload.second_factors.pluck(:name)).to_not include('Mobile')
    end
  end

  scenario 'visitor is redirected back to password form when passwords do not match' do
    sign_up_with('test@example.com')
    confirm_last_user
    fill_in 'user[password]', with: VALID_PASSWORD
    fill_in 'user[password_confirmation]', with: 'gobilily-gook'
    click_button 'Submit'

    expect(page).to have_content 'does not match password'
    expect(current_url).to eq confirm_url
  end

  scenario 'visitor is redirected back to password form when password is blank' do
    sign_up_with('test@example.com')
    confirm_last_user
    fill_in 'user[password]', with: ''
    fill_in 'user[password_confirmation]', with: 'gobilily-gook'
    click_button 'Submit'

    expect(page).to have_content 'does not match password'
    expect(current_url).to eq confirm_url
  end

  scenario 'visitor is redirected back to password form when password_confirmation is blank' do
    sign_up_with('test@example.com')
    confirm_last_user
    fill_in 'user[password]', with: VALID_PASSWORD
    fill_in 'user[password_confirmation]', with: ''
    click_button 'Submit'

    expect(page).to have_content 'does not match password'
    expect(current_url).to eq confirm_url
  end

  scenario 'visitor is redirected back to password form when both password fields are blank' do
    sign_up_with('test@example.com')
    confirm_last_user
    fill_in 'user[password]', with: ''
    fill_in 'user[password_confirmation]', with: ''
    click_button 'Submit'

    expect(page).to have_content "can't be blank"
    expect(current_url).to eq confirm_url
  end

  context 'password and/or password_confirmation fields are blank when JS is on', js: true do
    before do
      User.create!(email: 'test@example.com')
      confirm_last_user
    end

    it 'shows error message when password_confirmation is blank' do
      fill_in 'user[password]', with: VALID_PASSWORD
      fill_in 'user[password_confirmation]', with: ''
      click_button 'Submit'

      expect(page).to have_content 'Please fill in all required fields'
    end

    it 'shows error message when both password fields are blank' do
      fill_in 'user[password]', with: ''
      fill_in 'user[password_confirmation]', with: ''
      click_button 'Submit'

      expect(page).to have_content 'Please fill in all required fields'
    end

    it 'shows error message when password is blank' do
      fill_in 'user[password]', with: ''
      fill_in 'user[password_confirmation]', with: 'gobilily-gook'
      click_button 'Submit'

      expect(page).to have_content 'Please fill in all required fields'
    end
  end

  scenario 'visitor is redirected back to password form when password is invalid' do
    sign_up_with('test@example.com')
    confirm_last_user
    fill_in 'user[password]', with: 'Q!2e'
    fill_in 'user[password_confirmation]', with: 'Q!2e'
    click_button 'Submit'

    expect(page).to have_content('characters')
    expect(current_url).to eq confirm_url
  end

  scenario 'visitor confirms more than once' do
    sign_up_with('test@example.com')

    confirm_last_user

    fill_in 'user[password]', with: VALID_PASSWORD
    fill_in 'user[password_confirmation]', with: VALID_PASSWORD
    click_button 'Submit'

    visit user_confirmation_url(confirmation_token: @raw_confirmation_token)

    expect(page).to have_content t('errors.messages.already_confirmed')
  end

  # Scenario: Visitor cannot sign up with invalid email address
  #   Given I am not signed in
  #   When I sign up with an invalid email address
  #   Then I see an invalid email message
  scenario 'visitor cannot sign up with invalid email address' do
    sign_up_with('bogus')
    expect(page).to have_content t('valid_email.validations.email.invalid')
  end

  scenario 'visitor cannot sign up with empty email address', js: true do
    sign_up_with('')

    expect(page).to have_content('Please fill in all required fields')
  end

  scenario 'visitor cannot sign up with email with invalid domain name' do
    invalid_addresses = [
      'foo@bar.com',
      'foo@example.com'
    ]
    allow(ValidateEmail).to receive(:mx_valid?).and_return(false)

    invalid_addresses.each do |email|
      sign_up_with(email)
      expect(page).to have_content t('valid_email.validations.email.invalid')
    end
  end

  scenario 'visitor cannot sign up with empty email address' do
    sign_up_with('')

    expect(page).to have_content "can't be blank"
  end

  # Scenario: Visitor is not aware of an email existing in the system
  #   Given I am not signed in
  #   When I sign up with an invalid email address
  #   Then I see a valid, but unconfirmed email message
  scenario 'visitor signs up with an email already in the system', email: true do
    user = create(:user, email: 'existing_user@example.com')
    sign_up_with('existing_user@example.com')

    expect(page).to have_content(
      t('devise.registrations.signed_up_but_unconfirmed', email: user.email)
    )
    expect(last_email.body).to have_content 'This email address is already in use.'
    expect(last_email.body).
      to include 'at <a href="https://upaya.18f.gov/contact">'
  end

  # Scenario: Visitor signs up but confirms with an expired token
  #   Given I am not signed in
  #   When I sign up with a email address and attempt to confirm with expired token
  #   Then I see a message that my confirmation token has expired
  #   And that I should request a new one
  scenario 'visitor signs up but confirms with an expired token' do
    allow(Devise).to receive(:confirm_within).and_return(24.hours)
    sign_up_with('test@example.com')
    confirm_last_user
    User.last.update(confirmation_sent_at: Time.current - 2.days)
    visit user_confirmation_url(confirmation_token: @raw_confirmation_token)

    expect(current_path).to eq user_confirmation_path
    expect(page).to have_content t(
      'errors.messages.confirmation_period_expired', period: '24 hours')
  end

  # Scenario: Visitor signs up but confirms with an invalid token
  #   Given I am not signed in
  #   When I sign up with a email address and attempt to confirm with invalid token
  #   Then I see a message that the token is invalid
  scenario 'visitor signs up but confirms with an invalid token' do
    sign_up_with('test@example.com')
    raw_confirmation_token = Devise.token_generator.generate(User, :confirmation_token)

    User.last.update(
      confirmation_token: raw_confirmation_token, confirmation_sent_at: Time.current)
    visit '/users/confirmation?confirmation_token=invalid_token'

    expect(page).to have_content 'Confirmation token is invalid'
    expect(current_path).to eq user_confirmation_path
  end

  describe 'Setting account type' do
    def success_notice
      t('upaya.notices.account_created',
        date: (Time.current + 1.year).strftime('%B %d, %Y'))
    end

    scenario 'visitor signs up and sets account type to self' do
      user = create(:user, :all_but_account_type)
      sign_in_and_2fa_user(user)

      expect(page.current_url).to eq users_type_url

      choose 'user_account_type_self'
      click_button 'Submit'

      expect(page.current_url).to eq dashboard_index_url
    end

    scenario 'visitor signs up and sets account type to representative' do
      user = create(:user, :all_but_account_type)
      sign_in_and_2fa_user(user)

      expect(current_path).to eq('/users/type')

      choose 'user_account_type_representative'
      click_button 'Submit'

      expect(current_path).to eq('/users/type/confirm')

      click_button 'I am a representative'

      expect(page).to have_content(success_notice)
      expect(current_path).to eq('/dashboard')
      user.reload
      expect(user.account_type).to eq('representative')
    end

    scenario 'visitor signs up and sets account type to self on confirm page' do
      user = create(:user, :all_but_account_type)
      sign_in_and_2fa_user(user)

      choose 'user_account_type_representative'
      click_button 'Submit'
      click_button 'I am not a representative'

      expect(page).to have_content(success_notice)
      expect(current_path).to eq('/dashboard')
      user.reload
      expect(user.account_type).to eq('self')
    end

    scenario 'visitor signs up and does not want to choose account type, must' do
      user = create(:user, :all_but_account_type)
      sign_in_and_2fa_user(user)

      expect(page.current_url).to eq users_type_url

      click_button 'Submit'

      expect(page.current_url).to eq users_type_url
      expect(page).to have_content t('upaya.errors.no_account_type')
    end

    scenario 'visitor sets account type and tries to set it again' do
      user = create(:user, :all_but_account_type)
      sign_in_and_2fa_user(user)

      choose 'user_account_type_self'
      click_button 'Submit'

      visit users_type_path

      expect(page.current_url).to eq dashboard_index_url
      expect(page).to have_content t('upaya.errors.cannot_change_account_type')
    end

    scenario 'visitor sets account type and tries to confirm it again' do
      user = create(:user, :all_but_account_type)
      sign_in_and_2fa_user(user)

      choose 'user_account_type_self'
      click_button 'Submit'

      visit users_type_confirm_path

      expect(page.current_url).to eq dashboard_index_url
      expect(page).to have_content t('upaya.errors.cannot_change_account_type')
    end
  end
end