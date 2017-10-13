class AdminMailer < ApplicationMailer
  def stripe_account_disabled stripe_account, disabled_attributes
    @stripe_account = stripe_account
    @stripe_account.retrieve_service_account
    @user = stripe_account.user
    @disabled_attributes = disabled_attributes
    mail(to: admin_emails, subject: "#{@user.display_name} stripe account capabilities reduced.")
  end

  def new_contact_us contact
    @contact = contact
    mail to: Contact.recipient_email, subject: "#{@contact.full_name} sent a message"
  end

  def special_transfer_failed charge, message
    @booking = charge.booking
    @adventurer_charge = @booking.charge
    @discount_amount = @booking.discount
    @credit_amount = @booking.credit_amount
    @service_fee = @booking.service_fee
    @message = message
    mail to: ENV.fetch('CONTACT_EMAIL', 'all@gohinterlands.com'), subject: "Special Transfer (Discount) Failed"
  end

  private

  def admin_emails
    @admin_emails ||= AdminUser.pluck :email
  end
end
