# encoding: utf-8
class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  process :auto_orient # this should go before all other "process" steps

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.respond_to?(:uid) ? model.uid : model.id}"
  end

  # Only allow jpg, jpeg and pngs.
  def extension_white_list
    %w(pdf jpg jpeg png)
  end

  def as_json(options = nil)
    serializable_hash options
  end

  # Rotates the image based on the EXIF Orientation
  def auto_orient
    manipulate! do |image|
      image.tap(&:auto_orient) if image_type?(image)
    end
  end

  # Allow public read access
  configure do |c|
    c.aws_acl = 'public-read'
  end

  protected

  def image_type?(new_file)
    new_file.mime_type.start_with? 'image'
  end
end
