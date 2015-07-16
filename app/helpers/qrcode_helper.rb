module QrcodeHelper
  require 'rqrcode'

  def render_qr_code(url, size = 3)
    return if url.blank?
    qr = RQRCode::QRCode.new(url, size: 10)
    sizeStyle = "width: #{size}px; height: #{size}px;"

    content_tag :table, class: 'qrcode' do
      qr.modules.each_index do |x|
        tr = content_tag(:tr) do
          qr.modules.each_index do |y|
            color = qr.dark?(x, y) ? 'black' : 'white'
            concat(content_tag(:td, nil, class: color, style: sizeStyle))
          end
        end
        concat(tr)
      end
    end
  end

end