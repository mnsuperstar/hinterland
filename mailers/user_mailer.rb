class UserMailer < ApplicationMailer
  def welcome_email user
    @user = user
    @feature_adventures = Adventure.featured.take(4)
    mail(to: @user.email, subject: 'Welcome to Hinterlands! Your Adventure Awaits You So Get Started.')
  end

  def notify_missed_chat_messages(user, chat, time)
    @user = user
    @messages = chat.messages.asc_ordered.after(time).where.not(user: @user)
    @chat = chat
    @senders = @messages.map{ |m| m.user.first_name }.uniq
    mail(to: @user.email, subject: "You've received a new message on Hinterlands!") unless @messages.empty?
  end

  def notify_new_booking_created user, booking
    @user = user
    @booking = booking
    mail(to: @user.email, bcc: ENV.fetch('CONTACT_EMAIL', 'all@gohinterlands.com'), subject: "#{@user.first_name}, you have a new adventure request! ")
  end

  def notify_rejected_booking(user, booking)
    @feature_adventures = Adventure.featured.take(4)
    @user = user
    @booking = booking
    mail(to: @user.email, subject: "Adventure request has been declined")
  end

  def notify_canceled_booking(user, booking)
    @feature_adventures = Adventure.featured.take(4)
    @user = user
    @booking = booking
    mail(to: @user.email, subject: "Adventure has been cancelled")
  end

  def notify_accepted_booking(user, booking)
    @user = user
    @booking = booking
    mail(to: @user.email, subject: "#{@user.first_name} You're on your way to a new adventure!")
  end

  def notify_location_subscriber(user, adventure)
    @user = user
    @adventure = adventure

    mail(to: @user.email, subject: 'New Adventure is Opened')
  end

  def forward_sendgrid_event(to, sendgrid_event)
    @body = sendgrid_event.body
    mail(to: to, from: sendgrid_event.sender_email, subject: sendgrid_event.subject)
  end

  def notify_itinerary_recipients(to, booking)
    @booking = booking
    mail(to: to, subject: "Congratulations, adventure accepted!")
  end

  def notify_updated_adventure(user, adventure)
    @user = user
    @adventure = adventure
    mail(to: @user.email, subject: "It looks like you've edited #{adventure.title}")
  end

  def notify_updated_email user, email_was
    @user = user
    mail(to: email_was, subject: "It looks like you changed your account email")
  end

  def notify_updated_payment_method user
    @user = user
    mail(to: @user.email, subject: "Your Hinterlands payment information has been updated")
  end

  def notify_post_booking_creation booking
    @booking = booking
    mail to: @booking.guide.email, subject: "#{@booking.adventurer.name} is awaiting a booking request"
  end

  def notify_post_booking_creation_for_adventurer booking
    @booking = booking
    mail to: @booking.adventurer.email, subject: "#{@booking.adventure.title} will be reviewed"
  end

  def notify_partner_application_email_received user
    @user = user
    mail(to: @user.email, subject: "Submission of Partner application received")
  end

  def notify_partner_application_email_verified user
    @user = user
    mail(to: @user.email, subject: "Your Hinterlands Partner request has been accepted")
  end

  def adventure_reminder booking
    @booking = booking
    recipients = @booking.itinerary_recipients << @booking.adventurer.email
    mail to: recipients, subject: 'You have an upcoming adventure!'
  end

  def notify_leave_review booking
    @booking = booking
    @activities = booking.adventure.activities.pluck(:title).join(', ').downcase
    mail(to: @booking.adventurer.email, subject: "Leave a review for #{@booking.guide.first_name}")
  end

  def notify_leave_review_reminder booking
    @booking = booking
    @activities = booking.adventure.activities.pluck(:title).join(', ').downcase
    mail(to: @booking.adventurer.email, subject: "Reminder to leave a review for #{@booking.guide.first_name}")
  end

  def guide_ach_reminder guide
    @guide = guide
    mail to: guide.email, subject: 'Update your ACH details to receive bookings'
  end
end
