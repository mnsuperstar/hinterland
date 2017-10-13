module ActiveAdmin::ViewsHelper
  def reviewable_link reviewable
    if reviewable.is_a? UsersRole
      link_to "#{reviewable.user.name} [#{reviewable.role_name}]", [:admin, reviewable.user]
    elsif reviewable.is_a? Booking
      link_to reviewable.booking_number || "Booking id:#{reviewable.id}", [:admin, reviewable]
    else # adventure
      link_to reviewable.title, [:admin, reviewable]
    end
  end

  def app_setting_value_hint app_setting, n2br = true
    hint = "Input #{app_setting.value_type} value."
    hint = (hint + "\nyou can use the following denomination : #{AppSetting::TIME_DENOMINATIONS.to_sentence}.\nDon't use decimal value for month and year.").html_safe if app_setting.value_type == 'time'
    hint = hint.gsub("\n", '<br />').html_safe if n2br
    hint
  end

  def cancel_link booking
    if booking.pending? || booking.accepted?
      link_to('cancel', cancel_admin_booking_path(booking),
              method: :put, data: {confirm: 'Are you sure?'})
    end
  end
end
