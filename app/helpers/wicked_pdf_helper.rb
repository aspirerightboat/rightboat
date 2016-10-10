module WickedPdfHelper
  def wicked_pdf_image_tag_if(condition, url)
    if condition
      wicked_pdf_image_tag url
    else
      image_tag url
    end
  end
end
