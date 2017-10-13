# encoding: utf-8
class AdventureUploader < ImageUploader
  version :iphone_thumbnail do
    process resize_to_fill: [736, 736]
  end

  version :desktop do
    process resize_to_fill: [350, 234]
  end

  version :desktop_large do
    process resize_to_fill: [650, 382]
  end

  version :desktop_thumb do
    process resize_to_fill: [148, 99]
  end
end
