require 'securerandom'

class LatexGenerate < Image
  def initialize(math)
    @math = math
    @uuid = SecureRandom.uuid
    super("#{@uuid}.png", {dynamic: true})
  end

  def ensure_header
    unless File.exist?('header.fmt')
      FileUtils.cp(File.dirname(__FILE__) +  '/header.fmt', 'header.fmt')
    end
  end

  def generate_tex_file
    File.open("#{@uuid}.tex", "w") do |f|
      f.write '%&header
\usepackage{fontspec}
\begin{document}
$
'
      f.write @math
      f.write '
$
\end{document}
'
    end
  end

  def generate_pdf_from_tex
    `xelatex -shell-escape #{@uuid}.tex`
  end

  def generate_png_from_pdf
    `convert -density 600 #{@uuid}.pdf #{@uuid}.png`
  end

  def clean_up_tex_intermediates
    File.unlink("#{@uuid}.tex","#{@uuid}.aux","#{@uuid}.log","#{@uuid}.pdf")
  end

  def generate_png
    ensure_header
    generate_tex_file
    generate_pdf_from_tex
    generate_png_from_pdf
    clean_up_tex_intermediates
  end
end
