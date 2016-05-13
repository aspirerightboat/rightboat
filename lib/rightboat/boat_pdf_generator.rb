module Rightboat
  class BoatPdfGenerator

    def self.ensure_pdf(boat)
      name = "#{boat.ref_no}-#{boat.manufacturer}-#{boat.model}"
      name = name.gsub(/[^\w .-]/, '').gsub(/\s/, '-').squeeze(' ').strip
      pdf_file_path = "#{Rails.root}/boat_pdfs/#{Time.current.strftime('%Y-%m-%d')}/#{name}.pdf"

      if !File.exist?(pdf_file_path)
        FileUtils.mkdir_p(File.dirname(pdf_file_path))

        view = ActionView::Base.new(Rails.root.join('app/views'))
        view.class_eval do
          include BoatsHelper
          include QrcodeHelper
          include Rails.application.routes.url_helpers
          self.default_url_options = Rails.application.config.action_controller.default_url_options
        end

        pdf = view.render(
            pdf: 'pdf',
            locals: {:@boat => boat},
            template: 'boats/pdf.html.haml',
            layout: 'layouts/pdf.html.haml'
        )

        pdf = WickedPdf.new.pdf_from_string(pdf,
            margin: { bottom: 20 },
            footer: {
              content: view.render({
                template:  'shared/_pdf_footer.html.haml',
                layout:    'layouts/pdf.html.haml'
              })
            }
        )

        File.open(pdf_file_path, 'wb') { |file| file << pdf }
      end

      pdf_file_path
    end

  end
end
