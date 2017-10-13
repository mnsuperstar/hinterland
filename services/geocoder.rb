class Geocoder
  include Geokit::Geocoders

  def geocode address, options = {}
    geos = GoogleGeocoder.geocode(address).all

    geos.delete_if { |g| !g.success }
    geos = geos[0, options[:limit]] if options[:limit].present?
    geos.map! { |g| location_attributes_for(g) }
    if options[:create_locations]
      create_locations geos
    else
      geos
    end
  end

  def reverse_geocode latitude, longitude, options = {}
    geo = location_attributes_for GoogleGeocoder.reverse_geocode("#{latitude},#{longitude}")

    if options[:create_location]
      create_location geo.merge(skip_reverse_geocode: true)
    else
      geo
    end
  end

  private

    def create_location attributes
      l = Location.where(attributes.slice(:latitude, :longitude)).first_or_initialize
      l.update_attributes! attributes
      l
    end

    def create_locations attributes_arr
      attributes_arr.map do |attributes|
        create_location attributes
      end
    end

    def location_attributes_for geo
      if geo.success
        {
          full_address: geo.full_address,
          zipcode: geo.zip,
          latitude: BigDecimal.new(geo.lat, 9).truncate(6),
          longitude: BigDecimal.new(geo.lng, 9).truncate(6),
          country_code: geo.country_code,
          city: geo.city,
          state: geo.state,
          street_address: geo.street_address,
          province: geo.province,
          district: geo.district
        }
      else
        {}
      end
    end

end
