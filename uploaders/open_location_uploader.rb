# encoding: utf-8

class OpenLocationUploader < ImageUploader
  version :iphone do
    process resize_to_fill: [1000, 1000]
    process convert: 'jpg'
    def full_filename(for_file = model.image.file)
      filename, _ = for_file.split('.')
      "iphone_#{filename}.jpg"
    end
  end
end
