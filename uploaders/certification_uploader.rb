# encoding: utf-8

class CertificationUploader < ImageUploader

  # Only allow jpg, jpeg and pngs.
  def extension_white_list
    %w(pdf jpg jpeg png)
  end

end
