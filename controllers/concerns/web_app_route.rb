module WebAppRoute
  private

  def web_app_url(page = "", params = {}, options = { host: "#{ENV['APP_PROTOCOL']}://#{ENV['APP_DOMAIN']}" })
    mapping = HashWithIndifferentAccess.new(
      sign_in: 'signin',
      sign_up: 'signup',
      adventures: 'adventures',
      guides: 'guides',
      messages: 'messages',
      bookings: 'bookings',
      reservations: 'reservations',
      forgot_password: 'forgot-password',
      'adventurer/bookings' => 'adventurer/bookings',
      'guide/bookings' => 'guide/bookings',
      not_found: '404',
      root: ''
    )
    path = mapping[page]
    raise NoMethodError.new("undefined web app route: #{page}") if path.nil? && page.present?
    res = [[options[:host], path.presence, params.delete(:id), params.delete(:child_page)].compact.join('/'), params.to_param.presence].compact.join('?')
    res
  end
end
