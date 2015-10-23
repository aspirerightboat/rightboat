class Rightboat::Captcha
  NUMS = (1..10).to_a
  OPERATORS = [:+, :*]

  def self.generate
    {a: NUMS.sample,
     b: NUMS.sample,
     op: OPERATORS.sample}
  end

  def self.image(opts)
    question = "What is #{opts[:a]} #{opts[:op].to_s == '*' ? '×' : opts[:op]} #{opts[:b]} ="
    # see: http://www.imagemagick.org/Usage/text/#label
    `convert -fill '#777777' -pointsize 16 -font Helvetica label:'#{question}' png:-`
  end

  def self.correct?(opts, value)
    opts.present? && value.present? && opts[:a].send(opts[:op], opts[:b]) == value.to_i
  end
end
