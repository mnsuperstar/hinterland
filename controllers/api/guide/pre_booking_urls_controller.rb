class Api::Guide::PreBookingUrlsController < Api::ResourcesController

  def create
    @pre_booking = PreBookingUrl.new(pre_booking_params)
    if @pre_booking.save
      render_resource @pre_booking
    else
      render_error_json @pre_booking, status: :unprocessable_entity
    end
  end

  private

  def scoped_resources
    # user_id is removed from adventure
    # PreBookingUrl.joins(:adventure).where(adventures: { user_id: current_user.id})
    PreBookingUrl.joins(:adventure).where(adventures: { company_id: current_user.company.id})
  end

  def pre_booking_params
    params.require(:pre_booking_url)
          .permit(:start_on, :end_on, :number_of_adventurers, :adventure_uid, :short_uid)
  end
end
