module Rightboat
  module BoatDescriptionUtils
    ALLOWED_TAGS = %w(p br i b strong h3 ul ol li)

    private

    def cleanup_description(str)
      return '' if str.blank?
      str = ActionController::Base.helpers.simple_format(str) if !str['<']

      frag = Nokogiri::HTML.fragment(str)
      frag.css('table').remove

      frag.traverse do |node|
        if node.elem? && node != frag
          tag_name = node.name
          if tag_name.in?(ALLOWED_TAGS)
            node.each { |attr, _| node.delete(attr) }
            node.remove if tag_name == 'p' && node.text.blank?
          else
            node.replace(node.children)
          end
        end
      end
      frag.to_html
    end

    def cleanup_short_description(desc)
      return '' if desc.blank?
      desc = cleanup_description(desc)

      if desc.size > 480
        desc = desc[0..480]
        desc.sub!(/(?:[^.>!]|\.(?=\d))+\z/, '') # because '<p>qwe</p> qwe 5.5 asd' should be cropped to '<p>qwe</p>'
      end
      desc.gsub!(/\S+@\S(?:\.\S)+/, '') # remove email
      desc.gsub!(/[\d\(\) -]{9,20}/, '') # remove phone
      desc.gsub!(%r{(?:https?://|www\.)\S+}, '') # remove url
      Nokogiri::HTML.fragment(desc).to_html # ensure html is valid
    end

  end
end
