class Api::DevicesController < Api::ResourcesController
  include ::CompanyScoped

  def create
    @device = Device.where(device_params.slice(:token, :os)).first_or_initialize
    if @device.update_attributes device_params.merge(user: current_user) # change ownership if it's existed
      track(current_user, 'register or update a device', device_uid: @device.uid, os: os)
      render_resource @device
    else
      render_error_json @device, json: { device: @device.to_api_data }, status: :unprocessable_entity
    end
  end

  def destroy
    @devices = current_user.devices.where(os: os)
    @devices = @devices.where(uid: params[:id]) if params[:id].present?
    @devices.destroy_all

    track(current_user, 'removed device(s)', device_uid: params[:id], os: os)
    head :ok
  end

  def update
    if prepared_device.update(device_params)
      render_resource prepared_device
    else
      error_json prepared_device
    end
  end

  private

    def os
      @os ||= case request.user_agent
              when /iPad|iPhone|iPod/
                'ios'
              else
                raise ActiveRecord::RecordNotFound
              end
    end

    def prepared_device
      @device ||= current_user.devices.find_by!(uid: params[:id])
    end

    def device_params
      params.required(:device).permit(:token).merge(os: os).merge(is_disabled: false)
    end

    def scoped_resources
      current_user.devices
    end
end
