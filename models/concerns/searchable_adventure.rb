module SearchableAdventure
  extend ActiveSupport::Concern

  included do
    include Searchable

    mapping do
      indexes :difficulty, type: 'string', index: :not_analyzed
      indexes :coordinate, type: 'geo_point'
      indexes :price_cents, type: 'integer'
      indexes :group_size, type: 'integer'
      indexes :adventure_dates, type: 'nested' do
        indexes :start_on, type: 'date'
        indexes :end_on, type: 'date'
      end
      indexes :activities do # not nested so uid and title can be searched individually
        indexes :uid, type: 'string', index: :not_analyzed
        indexes :title, type: 'string', index: :not_analyzed
      end
      indexes :title, type: 'string'
      indexes :description, type: 'string'
      indexes :guide_name, type: 'string'
      indexes :location_name, type: 'string'
      indexes :is_listed, type: 'boolean'
    end
  end

  def as_indexed_json(options={})
    h = as_json(only: %i(difficulty price_cents group_size adventure_dates title description is_listed)).merge(
      'guide_name' => guides.map { |guide| guide.try(:short_name) }, #guide.try(:short_name),
      'location_name' => "#{location_name} #{location.try(:name)}"
    )
    h.merge!('coordinate' => { 'lat' => latitude, 'lon' => longitude }) if latitude && longitude
    h[:activities] = activities.as_json(only: [:uid, :title])
    h[:adventure_dates] = self.adventure_dates.map do |adventure_date|
      {
        start_on: adventure_date.start_on,
        end_on: adventure_date.end_on
      }
    end
    h
  end
end
