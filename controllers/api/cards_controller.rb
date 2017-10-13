class Api::CardsController < Api::ResourcesController
  include ::CompanyScoped
  skip_before_action :authenticate_user_from_token!, :authenticate_user!
  before_action :authenticate_member
  before_action :prepare_owner

  def create
    if new_card.save
      track(@owner, "added a card", card_uid: new_card.uid)
      render_resource(new_card)
    else
      render_error_json(new_card, status: :unprocessable_entity)
    end
  rescue Stripe::InvalidRequestError => e
    render_error_json e.message
  rescue Stripe::CardError => e
    render_error_json e.message
  end

  def update
    if prepared_card.update_attributes(update_card_params)
      track(@owner, "updated a card", card_uid: prepared_card.uid)
      render_resource prepared_card
    else
      render_error_json prepared_card, status: :unprocessable_entity
    end
  end

  def destroy
    if prepared_card.destroy
      track(@owner, "removed a card", card_uid: prepared_card.uid)
      head(:ok)
    else
      render_error_json prepared_card, status: :not_acceptable
    end
  end

  private

  def new_card
    @card ||= @owner.cards.new(card_params)
  end

  def card_params
    params.require(:card).permit(:token, :is_primary)
  end

  def update_card_params
    params.require(:card).permit(:is_primary)
  end

  def scoped_resources
    @owner.cards.where(tokenization_method: nil)
  end

  def prepared_card
    @card ||= @owner.cards.find_by!(uid: params[:id])
  end

  def prepare_owner
    @owner = current_user ? current_user : current_admin_company.company
  end

  def authenticate_member
    if params[:auth_token].present?
      authenticate_user_from_token!
      authenticate_user!
    else
      authenticate_admin_company_from_token!
      authenticate_admin_company!
    end
  end
end
