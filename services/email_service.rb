class EmailService
  attr_accessor :client, :api_key
  include ActiveSupport::Rescuable

  rescue_from(Mailchimp::ValidationError) do |e|
    raise e unless e.message == 'This email address looks fake or invalid. Please enter a real email address.'
  end

  rescue_from(Mailchimp::Error) do |e|
    raise e unless e.message =~ / is an invalid email address and cannot be imported.$/
  end

  def initialize api_key = nil
    @api_key = api_key ||  ENV['MAILCHIMP_API_KEY']
    @client = Mailchimp::API.new(@api_key)
  end

  def subscribe list_id, email_options, options = nil
    client.lists.subscribe(
      list_id,
      email_options,
      options,
      'html', # email format html | text
      false, # turn off double opt-in
      true, # update existing subscriber
      false # don't replace existing interest groups
    )
  end
end
