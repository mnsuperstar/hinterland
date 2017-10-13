# encoding: utf-8

class ProfileBackgroundUploader < ImageUploader
  version :iphone_thumbnail do
    process resize_to_fill: [736, 736]
  end

  version :desktop do
    process resize_to_fill: [730, 250]
  end
end
