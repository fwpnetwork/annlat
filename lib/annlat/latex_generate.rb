require 'securerandom'

class LatexGenerate < Image
  def initialize(math)
    @math = math
    @uuid = SecureRandom.uuid
    super("#{@uuid}.png", {dynamic: true})
  end

  def generate_tex_file
    File.open("#{@uuid}.tex", "w") do |f|
      f.write '\documentclass[convert={density=600,outext=.png}]{standalone}
\usepackage{fontspec}
\setmainfont{lmroman10-regular.otf}
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

  def generate_png_from_tex
    `xelatex -shell-escape #{@uuid}.tex`
  end

  def clean_up_tex_intermediates
    File.unlink("#{@uuid}.tex","#{@uuid}.aux","#{@uuid}.log","#{@uuid}.pdf")
  end

  def generate_png
    generate_tex_file
    generate_png_from_tex
    clean_up_tex_intermediates
  end
end
