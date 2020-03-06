require "prawn"

normal_font = "/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans.ttf"
bold_font = "/usr/share/fonts/truetype/ttf-dejavu/DejaVuSans-Bold.ttf"

ix = Institution.where.not(siglum: nil).where.not(siglum: "").order(:siglum)

pdf = Prawn::Document.new(:page_size => 'A4')

pdf.font_families.update(
      'DejaVu' => { bold: bold_font,
                normal: normal_font }
)
pdf.font('DejaVu')

pdf.text "<b>RISM Library Sigla</b>",
  :inline_format => true,
  :leading => 5,
  :size => 20,
  :align => :center

pdf.text "",
  :leading => 15,
  :size => 20,
  :align => :center


ix.each do |i|
  pdf.text "#{i.siglum} <b>#{i.place}</b>, #{i.name}",
  :inline_format => true,
  :leading => 5,
  :size => 10
end


pdf.render_file "sigla.pdf"



