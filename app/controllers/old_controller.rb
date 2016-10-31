class OldController < ApplicationController

  def boat_urls
    manufacturer_name, _model_name, res = Rightboat::MakeModelSplitter.split(params[:makemodel].to_s.gsub('-', ' ').strip)
    if res && (manufacturer = Manufacturer.query_with_aliases(manufacturer_name).first)
      redirect_to sale_manufacturer_path(manufacturer)
    else
      redirect_to root_path
    end
  end

end
