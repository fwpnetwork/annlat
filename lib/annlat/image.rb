require 'securerandom'

class Image

  attr_accessor :path
  attr_reader :uuid, :options

  def initialize(path, options={dynamic: true})
    @options=options
    @path=path
    @uuid=SecureRandom.uuid
  end

  alias_method :to_s, :path

end
# Currently, nothing is rotated so convention is as RMagick expects: origin is top-left, +X is right, +Y is down
# Params:
# r => circle radius
# x_orig => x origin for circle
# y_orig => y origin for circle
# opts => style options for figures
# dashed_lines => list of dashed lines to be displayed; each line should be [x1-coord, y1-coord, x2-coord, y2-coord]
# text => list of text to be displayed; each text should be [x-coord, y-coord, text]
def drawCircle(r, x_orig, y_orig, opts, text = [], dashed_lines = [])
  text_opts={:font_weight => 100, :font_size => opts[:font_size], :stroke => "black", :stroke_width => 0.8*opts[:stroke_width], :fill => 'black', :text_anchor => "middle"}

  rvg = RVG.new(opts[:width], opts[:height]).viewbox(0,0,opts[:xcoord],opts[:ycoord]) do |canvas|
    canvas.background_fill = 'white'
    canvas.g.translate(0, 0) do |draw|
      draw.styles({:fill_opacity => 0.8, :fill => opts[:color], :stroke_width => opts[:stroke_width], :stroke => "black"})
      di=opts[:di]
      draw.circle(r, x_orig, y_orig).styles(:fill=>opts[:color], :stroke=>opts[:stroke_color], :stroke_width=>opts[:stroke_width])

      # addl_coords.each do |x|
      #   draw.polygon(x[0], x[1]).styles(:fill=>"transparent", :stroke=>opts[:stroke_color], :stroke_width=>0.5*opts[:stroke_width])
      # end

      dashed_draw = Magick::RVG::Group.new.styles({:stroke=>'black', :fill=>'none', :stroke_width => 0.5*opts[:stroke_width],  :stroke_dasharray =>opts[:dasharray]}) do |fig|
        dashed_lines.each do |x|
          fig.line(x[0], x[1], x[2], x[3])
        end
      end
      draw.use(dashed_draw)
    end

    # new_opts = text_opts.dup
    # how_text.each do |x|
    #   new_opts[:fill] = x[3]
    #   canvas.text(x[0], x[1], x[2]).styles(new_opts)
    # end

    text.each do |x|
      canvas.text(x[0], x[1], x[2]).styles(text_opts)
    end

  end

  rvg.draw.write(opts[:name])
end

class Tree
  attr_accessor(:text, :children, :width, :height, :x, :y)

  def initialize(text, children=nil)
    @text= text
    c = []
    children.each do |x|
      if x.class.name == "Tree"
        c << x
      else
        c << Tree.new("#{x}")
      end
    end unless children == nil
    @children = c
    @x = 0
    @y = 0
  end

  def add_child(c)
    @children ||= []

    if c.class.name == "Tree"
        @children << c
      else
        @children << Tree.new("#{c}")
      end
  end

  def height()
    if @children == nil || @children.count == 0
      return 1
    else
      return 1 + (@children.map { |x| x.height}).max
    end
  end

  def width()
    if @children == nil || @children.count == 0
      return 1
    else
      w = 0
      @children.each do |x|
        w += x.width
      end
      w
    end
  end

  def setPos(x, y)
    @x = x
    @y = y
  end

  def calcPos(p_x, p_y, w=nil)
    if w == nil
      w=p_x
      @x = p_x/2
      @y = 30
      p_x = @x
      p_y = @y
    end

    if @children == nil || @children.count == 0
      return
    end

    w -= 20
    w = w - width*5
    # if @children[0].height > 1

    if @children.count == 1
      space = w
      x = p_x
    else
      space = w/(@children.count-1)
      x = p_x-w/2
    end

    y = 60
    @children.each do |t|
      t.setPos(x, @y+y)
      t.calcPos(x, @y+y+20, space)

      x+=space
    end unless @children == nil || @children.count == 0

  end

  def texts(root=true)
    if root
      l = [[@x, @y, @text]]
    else
      l = []
    end

    if @children != nil && @children.count != 0
      @children.each do |x|
          l << [x.x, x.y-5, x.text]
          l = l + x.texts(false)
        end
    end
    l
  end

  def lines()
    l = []
    if @children != nil && @children.count != 0
      @children.each do |x|
          l << [@x, @y, x.x, x.y-25]
          l = l + x.lines
        end
    end
    l
  end

  def to_s
    @text
  end

end

def createTree(tree, opts)
  text_opts={:font_weight => 100, :font_size => opts[:font_size], :fill => opts[:font_color], :stroke_width => 0.8*opts[:stroke_width], :text_anchor => "middle"}
  if opts[:font_stroke] != nil
    text_opts[:stroke_width] = opts[:font_stroke]
  end

  rvg = RVG.new(opts[:width], opts[:height]).viewbox(0,0,opts[:xcoord],opts[:ycoord]) do |canvas|
    canvas.background_fill = 'white'
    canvas.g.translate(0, 0) do |draw|
      draw.styles({:fill_opacity => 0.8, :fill => opts[:color], :stroke_width => opts[:stroke_width], :stroke => "black"})
      di=opts[:di]
      # draw.polygon(x_coords, y_coords).styles(:fill=>opts[:color], :stroke=>opts[:stroke_color], :stroke_width=>opts[:stroke_width])


      lines_draw = Magick::RVG::Group.new.styles({:stroke=>opts[:color], :fill=>'none', :stroke_width => 0.5*opts[:stroke_width]}) do |fig|
        tree.lines.each do |x|
          fig.line(x[0], x[1], x[2], x[3])
        end
      end
      draw.use(lines_draw)
    end

    tree.texts.each do |x|
      canvas.text(x[0], x[1], x[2]).styles(text_opts)
    end

  end

  rvg.draw.write(opts[:name])
end

# Currently, nothing is rotated so convention is as RMagick expects: origin is top-left, +X is right, +Y is down
# Params:
# x_coords => list of x coordinates to be plotted in order (passed directly into draw.polygon)
# y_coords => list of y coordinates to be plotted in order (passed directly into draw.polygon)
# opts => style options for figures
# dashed_lines => list of dashed lines to be displayed; each line should be [x1-coord, y1-coord, x2-coord, y2-coord]
# text => list of text to be displayed; each text should be [x-coord, y-coord, text]
# addl_coords => list of x/y coordinates; each list should be [list-of-x-coods, list-of-y-coords]; the idea being use this for right-angle overlays, etc. Will display with transparent fill and 0.8x stroke width
# how_text => just like text but requires a 4th option for fill color
def createPolygon(x_coords,y_coords, opts,dashed_lines = [], text = [], addl_coords = [], how_text = [])
  text_opts={:font_weight => 100, :font_size => opts[:font_size], :stroke => "black", :stroke_width => 0.8*opts[:stroke_width], :fill => 'black', :text_anchor => "middle"}
  if opts[:font_stroke] != nil
    text_opts[:stroke_width] = opts[:font_stroke]
  end
  rvg = RVG.new(opts[:width], opts[:height]).viewbox(0,0,opts[:xcoord],opts[:ycoord]) do |canvas|
    canvas.background_fill = 'white'
    canvas.g.translate(0, 0) do |draw|
      draw.styles({:fill_opacity => 0.8, :fill => opts[:color], :stroke_width => opts[:stroke_width], :stroke => "black"})
      di=opts[:di]
      draw.polygon(x_coords, y_coords).styles(:fill=>opts[:color], :stroke=>opts[:stroke_color], :stroke_width=>opts[:stroke_width])

      addl_coords.each do |x|
        draw.polygon(x[0], x[1]).styles(:fill=>"transparent", :stroke=>opts[:stroke_color], :stroke_width=>0.5*opts[:stroke_width])
      end

      dashed_draw = Magick::RVG::Group.new.styles({:stroke=>'black', :fill=>'none', :stroke_width => 0.5*opts[:stroke_width],  :stroke_dasharray =>opts[:dasharray]}) do |fig|
        dashed_lines.each do |x|
          fig.line(x[0], x[1], x[2], x[3])
        end
      end
      draw.use(dashed_draw)
    end

    new_opts = text_opts.dup
    how_text.each do |x|
      new_opts[:fill] = x[3]
      canvas.text(x[0], x[1], x[2]).styles(new_opts)
    end

    text.each do |x|
      canvas.text(x[0], x[1], x[2]).styles(text_opts)
    end

  end

  rvg.draw.write(opts[:name])
end

class Polygon
  attr_accessor(:x_coords, :y_coords, :lines, :labels, :lines_how, :labels_how, :area, :addl_coords, :shapes, :colors, :x_off, :y_off)

  def initialize(x = 100, y = 100)
    @x_coords = []
    @y_coords = []
    @lines = []
    @labels = []
    @lines_how = []
    @labels_how = []
    @addl_coords = []
    @area = 0
    @shapes = []
    @x_off = x
    @y_off = y

    @colors=['#BBBBBB', '#66CBFF', '#FF98FC', '#6732FD', '#FF6600', '#FFCA00', '#FF1700', '#00CB00', '#3499FC']
  end

  def create(draw_opts)
    createPolygon(@x_coords,@y_coords, draw_opts, @lines, @labels, @addl_coords)
  end

  def p(idx)
    return [@x_coords[idx], @y_coords[idx]]
  end

  def add_point(x,y)
    x+=@x_off
    y+=@y_off
    @x_coords << x
    @y_coords << y
  end

  def add_label(x, y, text, how = false, color = "lightblue")
    x+=@x_off
    y+=@y_off
    if how
      @labels_how << [x, y, text, color]
    else
      @labels << [x, y, text]
    end
  end

  def add_line(x1, y1, x2, y2, how = false, off = true)
    x_o = 0
    y_o = 0

    if off
      x_o = @x_off
      y_o = @y_off
    end

    if how
      @lines_how << [x1+x_o, y1+y_o, x2+x_o, y2+y_o]
    else
      @lines << [x1+x_o, y1+y_o, x2+x_o, y2+y_o]
    end
  end

  def add_to_area(x, y=0, s="")
    if s.downcase.include?("tri")
      area = (x*y*0.5).round(2)
      # @shapes << "#{s} has area #{area}"
        @shapes << ["The area formula for a triangle is", Frac.new("b*h","2"),". #{s} has", "b=#{y}".l, "and", "h=#{x}".l, ", so the area is", Frac.new("#{y}*#{x}","2"), "=#{area}".l]
    elsif s.downcase.include?("squa")
      area = (x*y).round(2)
      # @shapes << "#{s} has area #{area}"
      @shapes << ["The area formula for a sqaure is", "s*s".l, ". #{s} has", "s=#{x}".l, ", so the area is", "#{x}*#{y}=#{area}".l]
    elsif s.downcase.include?("parall")
      area = (x*y).round(2)
      # @shapes << "#{s} has area #{area}"
        @shapes << ["The area formula for a parallelogram is", "b*h".l, ". #{s} has", "b=#{x}".l, "and", "h=#{y}".l, ", so the area is", "#{x}*#{y}=#{area}".l]
    elsif s.downcase.include?("rect")
      area = (x*y).round(2)
      # @shapes << "#{s} has area #{area}"
      @shapes << ["The area formula for a rectangle is", "b*h".l, ". #{s} has", "b=#{x}".l, "and", "h=#{y}".l, ", so the area is", "#{x}*#{y}=#{area}".l]      
    elsif s.downcase.include?("kite")
      area = (x*y*0.5).round(2)
      # @shapes << "#{s} has area #{area}"
      @shapes << ["The area formula for a kite is", Frac.new("w*h","2"),". #{s} has", "w=#{x}".l, "and", "h=#{y}".l, ", so the area is", Frac.new("#{x}*#{y}","2"), "=#{area}".l]      
    else
      area = x.round(2)
    end

    @area += area
  end

  def rotate(x, y, c, s, b)
    if b
      return x * c - s * y
    else
      return x * s + c * y
    end
  end

  def add_tick(x, y, w, theta = 0, offset=false)
    if offset
      x+=@x_off
      y+=@y_off
    end
    c = Math.cos(theta)
    s = Math.sin(theta)
    r = Math.sqrt(w**2 + w**2)

    xs = [x - r * s]
    ys = [y - r * c]
    xs << x + r * s
    ys << y + r * c
  
    @addl_coords << [xs, ys]

  end

  def add_square(x, y, w, theta=0)
    x+=@x_off
    y+=@y_off

    c = Math.cos(theta)
    s = Math.sin(theta)
    r = Math.sqrt(w**2 + w**2)

    @x_coords << x
    @y_coords << y
    @x_coords << x+(w * s)
    @y_coords << y-(w * c)
    @x_coords << x+(r * Math.sin(theta + Math::PI/4))
    @y_coords << y-(r * Math.cos(theta + Math::PI/4))
    r_x = x+(w * c)
    r_y = y+(w * s)   
    @x_coords << r_x
    @y_coords << r_y

    return [r_x-@x_off, r_y-@y_off]

  end

  def add_rect(x, y, w, h)
    x+=@x_off
    y+=@y_off

    @x_coords << x
    @y_coords << y
    @x_coords << x
    @y_coords << y-h
    @x_coords << x+w
    @y_coords << y-h
    r_x = x+w
    r_y = y
    @x_coords << r_x
    @y_coords << r_y

    return [r_x-@x_off, r_y-@y_off]

  end

  def add_right_angle(x, y, theta = 0)
    x+=@x_off
    y+=@y_off

    c = Math.cos(theta)
    s = Math.sin(theta)
    r = Math.sqrt(200)

    xs = [x]
    ys = [y]
    xs << x+(10 * s)
    ys << y-(10 * c)
    xs << x+(r * Math.sin(theta + Math::PI/4))
    ys << y-(r * Math.cos(theta + Math::PI/4))
    xs << x+(10 * c)
    ys << y+(10 * s)
    @addl_coords << [xs, ys]
  end

end