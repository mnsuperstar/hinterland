class AdventureFilter
  attr_accessor :params, :query, :filters

  def initialize(params)
    self.params = params
    self.filters = []
    self.query = {}
  end

  def search
    filter_difficulty params[:difficulty]
    filter_activities uids: params[:activity_uids], titles: params[:activity_titles]
    filter_coordinate params[:coordinate]
    filter_date_range params[:date_range]
    filter_price_cents_range params[:price_cents_range]
    filter_group_size_range params[:group_size_range]
    prepare_query
    if params[:query].present?
      self.query = {
        query: {
          filtered: {
            query: {
              multi_match: {
                query: params[:query],
                type: 'most_fields',
                fields: %w(title description guide_name location_name),
                fuzziness: 'auto'
              }
            }
          }.merge(query)
        }
      }
    end
    apply_pagination
    Adventure.elasticsearch(query)
  end

  def closest
    filter_coordinate params[:coordinate]
    prepare_query(sort_geolocation(params[:coordinate]))
    apply_pagination
    Adventure.elasticsearch(query)
  end

  private

  # ES 2.x
  # def prepare_query(options={})
  #   self.query = {
  #     query: {
  #       bool: {
  #         filter: filters
  #       }
  #     }
  #   }.merge(options)
  # end

  # ES 1.x
  def prepare_query(options={})
    options.reverse_merge!(filter: {})
    options[:filter].reverse_merge!(and: filters) if filters.present?
    unless params[:is_listed].nil?
      options[:filter].reverse_merge!(and: [])
      options[:filter][:and] << {
        term: { is_listed: params[:is_listed] }
      }
      options[:filter][:and] << {
        exists: { field: :guide_name }
      }
    end
    self.query = options
  end

  def apply_pagination
    query.merge! size: params[:limit].presence || params[:size].presence || Kaminari.config.default_per_page
    query.merge! from: params[:from] if params[:limit].blank? && params[:from].present?
  end

  def sort_geolocation(coordinate)
    {
      sort: [
        {
          _geo_distance: {
            coordinate: {
              lat: coordinate[:latitude],
              lon: coordinate[:longitude]
            },
            order: 'asc',
            unit: 'miles',
            distance_type: 'plane'
          }
        }
      ]
    }
  end

  def filter_difficulty(difficulty)
    self.filters << { term: { difficulty: difficulty } } if difficulty.present?
  end

  def filter_activities(uids: nil, titles: nil)
    return if uids.blank? && titles.blank?
    h = {
      bool: {
        should: []
      }
    }
    h[:bool][:should] += uids.map { |uid|
      { term: { 'activities.uid' => uid } }
    } if uids.present?
    h[:bool][:should] += titles.map { |title|
      { term: { 'activities.title' => title } }
    } if titles.present?
    self.filters << h
  end

  def filter_coordinate(coordinate)
    return if !coordinate || coordinate[:latitude].blank? || coordinate[:longitude].blank?
    coordinate[:miles] ||= AppSetting['adventure.filter_max_distance_in_miles'] || 10
    self.filters << { geo_distance: {
      distance: "#{coordinate[:miles]}miles",
      coordinate: {
        lat: coordinate[:latitude],
        lon: coordinate[:longitude] } } }
  end

  def filter_date_range(date_range)
    return if date_range.blank?
    self.filters << {
      nested: {
        path: 'adventure_dates',
        query: {
          bool: {
            must: [
              { range: { 'adventure_dates.end_on' => { gte: date_range[:min] } } },
              { range: { 'adventure_dates.start_on' => { lte: date_range[:max] } } }
            ]
          }
        }
      }
    }
  end

  def filter_price_cents_range(price_cents_range)
    filter_range :price_cents, price_cents_range if price_cents_range.present?
  end

  def filter_group_size_range(group_size_range)
    filter_range :group_size, group_size_range if group_size_range.present?
  end

  def filter_range(attribute, range)
    self.filters << { range: {
      attribute => {
        gte: range[:min],
        lte: range[:max]
      } } }
  end
end
