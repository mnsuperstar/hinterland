class Api::Guide::AdventuresController < Api::Guide::ResourcesController
  include ::CompanyScoped
  before_action :prepare_adventure, only: [:update, :destroy, :list, :unlist]

  def index
    track(current_company, 'views their adventures')
    super
  end

  def show
    super
    track(current_company, 'views their adventure', adventure_uid: @resource.uid)
  end

  def create
    @resource = current_company.adventures.new(adventure_params.merge(tracker: self))
    if @resource.save
      render_resource @resource
    else
      render_error_json @resource, status: :unprocessable_entity
    end
  end

  def update
    if @adventure.update(adventure_params)
      @adventure.send_update_notification
      track(current_company, 'updated their adventure', adventure_uid: @adventure.uid)
      render_resource @adventure
    else
      render_error_json(@adventure, status: :unprocessable_entity)
    end
  end

  def destroy
    if @adventure.destroy
      track(current_company, 'removed their adventure', adventure_uid: @adventure.uid)
      head(:ok)
    else
      render_error_json @adventure, status: :not_acceptable
    end
  end

  def list
    if !current_company.can_list_adventure?
      render_error_json flash_message('forbidden'), status: :forbidden
    elsif !@adventure.list
      render_error_json @adventure, status: :unprocessable_entity
    else
      track(current_company, 'listed their adventure', adventure_uid: @adventure.uid)
      render_resource @adventure
    end
  end

  def unlist
    @adventure.unlist
    track(current_company, 'unlisted their adventure', adventure_uid: @adventure.uid)
    render_resource @adventure
  end

  private

  def scoped_resources
    current_company.adventures
  end

  def adventure_params
    p = [:activity_uid, :group_size, :difficulty, :duration,
          :location_uid, :title, :description, :price_cents, :notes,
          :additional_price_cents, :number_of_people_included, :location_name,
          :inclusions, :is_listed, :preparations, preparations: [],
          inclusions: [], dates: [:start_on, :end_on], images: []]
    p += [:is_draft, :last_edited_attribute] if action_name == 'create' || @adventure.try(:is_draft)
    params.require(:adventure).permit(p)
  end

  def api_data_version
    resource.is_draft ? :guide_draft : :guide
  end

  def index_api_data_version
    :guide
  end

  def prepare_adventure
    @adventure = scoped_resources.find_by_uid!(params[:id])
  end
end
