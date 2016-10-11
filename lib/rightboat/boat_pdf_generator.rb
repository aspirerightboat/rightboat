module Rightboat
  class BoatPdfGenerator

    def self.ensure_pdf(boat)
      name = "#{boat.ref_no}-#{boat.short_makemodel_fileslug(50)}"
      pdf_file_path = "#{Rails.root}/boat_pdfs/#{Time.current.strftime('%Y-%m-%d')}/#{name}.pdf"

      if !File.exist?(pdf_file_path)
        FileUtils.mkdir_p(File.dirname(pdf_file_path))

        pdf_html = BoatsController.render template: 'boats/pdf', layout: 'layouts/pdf', assigns: {boat: boat}
        footer_html = BoatsController.render template: 'shared/_pdf_footer', layout: 'layouts/pdf'

        pdf = WickedPdf.new.pdf_from_string(pdf_html,
            margin: { bottom: 20 },
            footer: {content: footer_html}
        )

        File.open(pdf_file_path, 'wb') { |file| file << pdf }
      end

      pdf_file_path
    end

  end
end
