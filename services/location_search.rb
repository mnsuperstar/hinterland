class LocationSearch
  attr_accessor :text, :limit

  def initialize(attributes = {})
    self.text = attributes[:text]
    self.limit = attributes[:limit]
  end

  def results
    if text.present?
      # TODO: find a way to avoid re-query (converting Array of ActiveRecord::Base to ActiveRecord::Relation which responds to `to_api_data`)
      Location.where(id: Geocoder.new.geocode(text, create_locations: true, limit: limit).map(&:id))
    else
      Location
    end
  end
end
