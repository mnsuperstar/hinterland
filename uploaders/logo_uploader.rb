# encoding: utf-8
class LogoUploader < ImageUploader
  version :iphone_thumbnail do
    process resize_to_fill: [100, 100]
  end

  version :desktop do
    process resize_to_fill: [80, 80]
  end

  version :desktop_thumb do
    process resize_to_fill: [68, 68]
  end

  version :desktop_large do
    process resize_to_fill: [136, 136]
  end
end
