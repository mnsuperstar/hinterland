class Api::ContactUsController < Api::ModuleController
  skip_before_action :authenticate_user_from_token!, :authenticate_user!

  def create
    if new_contact.save
      head :ok
    else
      render_error_json(new_contact, status: :unprocessable_entity)
    end
  end

  private

  def contact_us_params
    params.require(:contact_us)
          .permit(:full_name, :email, :phone, :company, :message)
  end

  def new_contact
    @contact ||= Contact.new(contact_us_params)
  end
end
