class Api::Guide::AdventureImagesController < Api::Guide::ResourcesController
  before_action :ensure_verified_guide, only: [:create, :update, :destroy]
  before_action :prepare_adventure

  def create
    @adventure_image = scoped_resources.new adventure_image_params
    if @adventure_image.save
      render_resource @adventure_image
    else
      render_error_json @adventure_image, status: :unprocessable_entity
    end
  end

  def update
    @adventure_image = scoped_resources.find_by_uid(params[:id])
    if @adventure_image.update adventure_image_params
      render_resource @adventure_image
    else
      render_error_json @adventure_image, status: :unprocessable_entity
    end
  end

  def destroy
    scoped_resources.find_by_uid(params[:id]).destroy
    head :ok
  end

  private

  def prepare_adventure
    @adventure = current_user.adventures.find_by_uid!(params[:adventure_id])
  end

  def scoped_resources
    @adventure.adventure_images
  end

  def adventure_image_params
    params.require(:adventure_image).permit(:file, :order_number)
  end
end
