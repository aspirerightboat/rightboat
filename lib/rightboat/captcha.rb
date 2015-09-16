class Rightboat::Captcha
  NUMS = (1..10).to_a
  OPERATORS = [:+, :*]

  def self.generate
    {a: NUMS.sample,
     b: NUMS.sample,
     op: OPERATORS.sample}
  end

  def self.image(opts)
    question = "What is #{opts[:a]} #{opts[:op]} #{opts[:b]} ="
    # see: http://www.imagemagick.org/Usage/text/#label
    `convert -fill '#60bbff' -pointsize 12 -font Helvetica-Oblique label:'#{question}' png:-`
  end

  def self.correct?(opts, value)
    opts.present? && value.present? && opts[:a].send(opts[:op], opts[:b]) == value.to_i
  end
end
