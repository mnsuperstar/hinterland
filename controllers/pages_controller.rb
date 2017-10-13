class PagesController < ApplicationController
  def show
    render action: params[:id].downcase.gsub(/[^a-z\d]/, '')
  end

  def adventure_short_url
    @adventure = Adventure.listed.find_by(short_uid: params[:short_uid])
    if @adventure
      redirect_to web_app_url("adventures", id: @adventure.slug)
    else
      redirect_to web_app_url(:not_found)
    end
  end

  def pre_booking_url
    @pre_booking = PreBookingUrl.find_by(short_uid: params[:short_uid])
    if @pre_booking
      @adventure = @pre_booking.adventure
      redirect_to web_app_url(
        "adventures",
        {
          id: @adventure.slug,
          start_date: @pre_booking.start_on,
          end_date: @pre_booking.end_on,
          adventurers: @pre_booking.number_of_adventurers,
          adventure_id: @adventure.id,
          child_page: 'booking'
        }
      )
    else
      redirect_to web_app_url(:not_found)
    end
  end

  def apple_app_site_association
    send_file Rails.root.join('app', 'views', 'pages', 'apple-app-site-association'), type: 'application/pkcs7-mime'
  end

  def generate_short_url
    @short_url = ShortUrl.find_by(short_uid: params[:short_uid])
    if @short_url
      @short_url.update_attributes(access_count: @short_url.access_count + 1)
      redirect_to @short_url.long_url
    else
      raise NoMethodError.new("undefined web app route")
    end
  end
end
