class MixpanelPeople
  def initialize
    @tracker = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
  end

  def add user
    @tracker.people.set(user.id, {
      '$first_name' => user.first_name,
      '$last_name' => user.last_name,
      '$email' => user.email,
      '$phone' => user.phone_number,
      '$created' => user.created_at,
      'Location' => user.location,
      'Gender' => user.gender,
      'Birthdate' => user.birthdate
    }, user.current_sign_in_ip)
  end

  def delete user
    @tracker.people.delete_user(user.id)
  end
end
