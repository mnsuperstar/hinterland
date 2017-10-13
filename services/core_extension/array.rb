module CoreExtension::Array
  def to_api_data(version, nested_namespace = nil)
    map do |item|
      item.to_api_data(version, nested_namespace)
    end
  end
end
