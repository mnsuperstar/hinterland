class Api::Guide::BookingsController < Api::Guide::ResourcesController
  include ::CompanyScoped
  alias_method :pending, :index
  alias_method :accepted, :index
  alias_method :previous, :index

  def payments
    @bookings = current_user.received_bookings
    if params[:when].present?
      @bookings = params[:when] == 'upcoming' ? @bookings.upcoming : @bookings.past
    end
    render json: { payments: @bookings.payments }
  end

  def update
    if prepared_booking.update_attributes(booking_params)
      track(current_user, 'updated received booking', booking_uid: prepared_booking.uid, status: prepared_booking.status)
      render_resource prepared_booking
    else
      render_error_json prepared_booking, status: :unprocessable_entity
    end
  end

  private

  def scoped_resources
    bookings = super.where(guide: current_user)
    case action_name
    when 'pending'
      track(current_user, 'views pending received bookings')
      bookings.upcoming.pending.order(start_on: :asc, id: :asc)
    when 'accepted'
      track(current_user, 'views accepted received bookings')
      bookings.upcoming.accepted.order(start_on: :asc, id: :asc)
    when 'previous'
      track(current_user, 'views previous received bookings')
      bookings.past.order(start_on: :desc, id: :desc)
    else
      track(current_user, 'views their received bookings') if action_name == 'index'
      bookings.order(id: :desc)
    end
  end

  def booking_params
    @booking_params = params.require(:booking).permit(:status)
    @booking_params.delete(:status) if @booking_params[:status].present? && !@booking_params[:status].in?(%w(accepted rejected))
    @booking_params
  end

  def api_data_version
    :guide
  end

  def index_api_data_version
    :guide_index
  end

  def prepared_booking
    @booking ||= current_user.received_bookings.pending.find_by_uid!(params[:id])
  end
end
