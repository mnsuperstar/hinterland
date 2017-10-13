class Api::SearchController < Api::ModuleController
  def show
    params[:limit] ||= 6
    params[:limit] = [params[:limit].to_i, Kaminari.config.default_per_page].min
    @adventures = AdventureFilter.new(query: params[:q].to_s, limit: params[:limit], is_listed: true).search.records
    @locations = LocationSearch.new(text: params[:q].to_s, limit: params[:limit]).results
    render json: {
      adventures: @adventures.to_api_data('index'),
      locations: @locations.to_api_data('index')
    }
    track(current_user, "do universal searches", params.to_unsafe_h.slice(:q, :limit))
  end
end
