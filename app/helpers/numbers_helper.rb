module NumbersHelper

  def percents(value)
    "#{(value * 100).round}%"
  end

  # def format_pence(value)
  #   sprintf('%.2f', value)
  # end

end
