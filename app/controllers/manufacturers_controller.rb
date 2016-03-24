class ManufacturersController < ApplicationController
  def index
  end

  def show
  end

  def by_letter
    @letter = params[:id]
    redirect_to(action: :index) if @letter.blank? || @letter !~ /\A[a-z]\z/

    @manufacturers = Manufacturer.joins(:boats).where(boats: {status: 'active'})
                         .where('manufacturers.name LIKE ?', "#{@letter}%")
                         .group('manufacturers.name, manufacturers.slug')
                         .order('manufacturers.name').page(params[:page]).per(100)
                         .select('manufacturers.name, manufacturers.slug, COUNT(*) AS boats_count')
  end
end
