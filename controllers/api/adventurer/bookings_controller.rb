class Api::Adventurer::BookingsController < Api::Adventurer::ResourcesController
  include ::UserAgentController
  include ::CompanyScoped
  before_action :ensure_verified_adventurer, except: [:index, :show]

  def show
    super
    track(current_user, "selects #{@resource.past? ? "past" : "upcoming"} booking", booking_uid: @resource.uid)
  end

  def create
    if new_booking.save
      track(current_user, 'created a booking', booking_uid: new_booking.uid)
      render_resource(new_booking)
    else
      render_error_json(new_booking, status: :unprocessable_entity)
    end
  end

  def update
    if !prepared_booking.pending?
      render_error_json flash_message('forbidden'), status: :forbidden
    elsif prepared_booking.update_attributes(booking_params)
      track(current_user, 'updated created booking', booking_uid: prepared_booking.uid)
      render_resource prepared_booking
    else
      render_error_json prepared_booking, status: :unprocessable_entity
    end
  end

  def availability
    track(current_user, 'checks availability', adventure_uid: new_booking.adventure.try(:uid))
    if new_booking.valid?
      render_resource(new_booking)
    else
      render_error_json(new_booking, status: :unprocessable_entity)
    end
  end

  def adventure
    @adventure = prepared_booking.adventure
    raise ActiveRecord::RecordNotFound if @adventure.nil?
    track(current_user, "views #{@adventure.listed? ? 'listed' : 'unlisted'} adventure from created booking", adventure_uid: @adventure.uid, booking_uid: prepared_booking.uid)
    render json: { adventure: @adventure.to_api_data }
  end

  def set_tips
    if new_booking_tips.save
      render_resource(prepared_booking)
    else
      render_error_json(new_booking_tips, status: :unprocessable_entity)
    end
  end

  private

  def new_booking_tips
    @booking_tips ||= BookingTip.new(tips_params.merge(booking: prepared_booking))
  end

  def booking_params
    @booking_params ||=
      params
      .require(:booking)
      .permit(:start_on, :end_on,
              :promo_code, :number_of_adventurers, :adventure_uid, :card_uid,
              itinerary_recipients: [])
  end

  def tips_params
    params.require(:booking).permit(:tips_cents, :card_uid)
  end

  def scoped_resources
    bookings = super.where(adventurer: current_user)
    if params[:upcoming].present?
      track(current_user, "views upcoming created bookings")
      bookings.upcoming.order(start_on: :asc, id: :desc)
    elsif params[:past].present?
      track(current_user, "views past created bookings")
      bookings.past.order(start_on: :desc, id: :desc)
    else
      track(current_user, "views their created bookings") if action_name == 'index'
      bookings.order(id: :desc)
    end
  end

  def api_data_version
    :adventurer
  end

  def index_api_data_version
    :adventurer_index
  end

  def new_booking
    @booking ||= current_user.created_bookings.new(booking_params.merge(skip_validation_for_availability: action_name == 'availability').merge(user_agent))
  end

  def prepared_booking
    @booking ||= scoped_resources.find_by_uid!(params[:id])
  end
end
