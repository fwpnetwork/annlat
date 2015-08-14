require 'gnuplot'
require 'securerandom'

require 'annlat/image'

class Plot < Image
  def parameters
    @parameters
  end

  def self.parse_answer(answer)
    coords = answer.split(';')
    coords.map do |c|
      # strip ()
      c = c[1..-2]
      # split up coords, convert to float
      c.split(',').map {|x| x.to_f}
    end
  end

  def self.parse_numbers(answer)
    coords = self.parse_answer(answer)
    coords.map do |c|
      c[0] == 0 ? c[1] : c[0]
    end
  end

  def self.parse_ranges(answer)
    answer.split(';')
  end

  def color(c=@parameters[:color])
    self.class.color(c)
  end

  def self.color(c)
    case c
    when nil, :red
      "#FF1700"
    when :blue
      "#3499FC"
    when :green
      "#00CB00"
    when :yellow
      "#FFCA00"
    when :orange
      "#FF6600"
    when :purple
      "#6732FD"
    when :pink
      "#FF98FC"
    when :lightblue
      "#66CBFF"
    when :grey
      "#BBBBBB"
    end
  end

  def self.available_colors
    [:red, :blue, :green, :yellow, :orange,
     :purple, :pink, :lightblue, :grey]
  end

  def self.hex_colors
    self.available_colors.map do |c|
      self.color(c)
    end
  end

  def color=(c)
    raise "Invalid Color" unless self.class.available_colors.include?(c)
    @parameters[:color] = c
    @parameters[:rgb] = color(c)
  end

  def maximum_points=(p)
    @parameters[:maximum_points] = p
  end
end

class NumberLine < Plot
  def initialize(low, high, tics = 1, horizontal = true, id = 0)
    @parameters = {
      low: low,
      high: high,
      tics: tics,
      horizontal: horizontal,
      fn: "#{SecureRandom.uuid}.png"
    }

    super(@parameters[:fn], {dynamic: true})
  end

  def denominator=(d)
    @parameters[:denominator] = d
  end

  def range=(r)
    @parameters[:range] = r ? true : false
  end

  def add_arrow(start, finish, color = nil, one_head = false)
    @arrows ||= []
    @arrows << [start, finish, self.color(color), one_head]
  end

  def decimals=(d)
    @parameters[:decimals] = d
  end

  # points is an array of values to plot on the number line
  def plot(points = [])
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal "pngcairo size 460,460"
        plot.output @parameters[:fn]
        plot.key "off"
        x = []
        y = []
        points << (@parameters[:high]-@parameters[:low])*2+@parameters[:high] if points.empty?
        @arrows ||= []
        if @parameters[:horizontal]
          plot.xrange "[#{@parameters[:low]}:#{@parameters[:high]}]"
          plot.yrange "[0:1]"
          plot.border 1
          plot.xtics generate_tics
          plot.unset "ytics"
          points.each do |p|
            x << p
            y << 0
          end
          @arrows.each do |a|
            if a[3]
              plot.arrow "from #{a[0]}, 0.05 to #{a[1]}, 0.05 filled lc rgb '#{a[2]}'"
            else
              plot.arrow "from #{a[0]}, 0.05 to #{a[1]}, 0.05 heads filled lc rgb '#{a[2]}'"
            end
          end
        else
          plot.yzeroaxis "lt -1"
          plot.xrange "[-1:1]"
          plot.yrange "[#{@parameters[:low]}:#{@parameters[:high]}]"
          plot.border 0
          plot.ytics "axis #{generate_tics}"
          plot.unset "xtics"
          points.each do |p|
            x << 0
            y << p
          end
          @arrows.each do |a|
            if a[3]
              plot.arrow "from 0.1, #{a[0]} to 0.1, #{a[1]} filled lc rgb '#{a[2]}'"
            else
              plot.arrow "from 0.1, #{a[0]} to 0.1, #{a[1]} heads filled lc rgb '#{a[2]}'"
            end
          end
        end
        plot.data << Gnuplot::DataSet.new([x, y]) do |ds|
          ds.with = "points pt 7 lc rgb '#{color}'"
          ds.notitle
        end
      end
    end
    if @parameters[:horizontal]
      `convert #{@parameters[:fn]} -crop 460x100+0+360 +repage #{@parameters[:fn]}`
    else
      `convert #{@parameters[:fn]} -crop 100x460+180+0 +repage #{@parameters[:fn]}`
    end
    self
  end

  private
  def generate_tics
    if @parameters[:denominator]
      tics = []
      d = @parameters[:denominator]
      (@parameters[:low]..@parameters[:high]).each do |i|
        last = i == @parameters[:high] ? 0 : d - 1
        (0..last).each do |j|
          numer = i*d+j
          frac = Frac.new(numer.l, d.l)
          f = frac.reduce
          if f.class == Frac
            tics << "\"#{f.numerator}/#{f.denominator}\" #{f.eval}"
          else
            tics << "\"#{f}\" #{f}"
          end
        end
      end
      "(#{tics.join(',')})"
    else
      @parameters[:tics]
    end
  end
end

class CoordinatePlane < Plot
  def initialize(xlow, xhigh, ylow, yhigh, xtics=1, ytics=1, id=0)
    @parameters = {
      xlow: xlow,
      xhigh: xhigh,
      ylow: ylow,
      yhigh: yhigh,
      xtics: xtics,
      ytics: ytics,
      fn: "#{SecureRandom.uuid}.png"
    }

    super(@parameters[:fn], {dynamic: true})
  end

  def lines=(l)
    @parameters[:lines] = l ? true : false
  end

  def points=(p)
    @parameters[:points] = p
  end

  def extend_lines=(tf)
    @parameters[:extend] = tf ? true : false
  end

  def add_label(text, x, y, size, color=nil)
    @labels ||= []
    @labels << [text, x, y, size, self.color(color)]
  end

  def label_align=(la)
    @parameters[:label_align] = la
  end

  def add_point(x, y, color=nil)
    @points ||= []
    @points << [x, y, self.color(color)]
  end

  def xlabel(lab)
    @parameters[:xlabel] = lab
  end

  def ylabel(lab)
    @parameters[:ylabel] = lab
  end

  def no_axes
    @parameters[:no_axes] = true
  end

  def plot
    self.plot_points
  end

  # points is an array of points to plot on the coordinate plane
  def plot_points(points = [])
    x = []
    y = []
    points << [(@parameters[:xhigh]-@parameters[:xlow])*2 + @parameters[:xhigh],
               (@parameters[:yhigh]-@parameters[:xlow])*2 + @parameters[:xhigh]] if points.empty?
    points.each do |p|
      x << p[0]
      y << p[1]
    end

    plot_generic(x, y, "points pt 7")
  end

  # lines is an array of end point lists
  # ex: lines = [[[1,2],[1,3]], [[3,2],[4,1]]] would plot two lines,
  # one from (1,2) to (1,3) and one from (3,2) to (4,1)
  # lines = [[[1,2],[3,4],[3,2]]] would plot a single line consisting of two segments
  # one from (1,2) to (3,4) and one from (3,4) to (3,2)
  def plot_lines(lines = [])
    x = []
    y = []
    return self.plot if lines.empty?
    lines.each do |l|
      l.each do |p|
        x << p[0]
        y << p[1]
      end
      x << nil
      y << nil
    end

    plot_generic(x, y, "lines")
  end

  def plot_generic(x, y, with)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal "pngcairo size 460,460"
        plot.output @parameters[:fn]
        plot.key "off"
        if @parameters[:no_axes].nil?
          plot.xzeroaxis
          plot.yzeroaxis
          plot.xtics "axis #{parameters[:xtics]}"
          plot.ytics "axis #{@parameters[:ytics]}"
          plot.grid "xtics lt 0 lc rgb '#bbbbbb'"
          plot.grid "ytics lt 0 lc rgb '#bbbbbb'"
        else
          plot.unset "xtics"
          plot.unset "ytics"
        end
        plot.xrange "[#{@parameters[:xlow]}:#{@parameters[:xhigh]}]"
        plot.yrange "[#{@parameters[:ylow]}:#{@parameters[:yhigh]}]"
        plot.xlabel "'#{@parameters[:xlabel]}' font 'Latin-Modern'" if @parameters[:xlabel]
        plot.ylabel "'#{@parameters[:ylabel]}' font 'Latin-Modern'" if @parameters[:ylabel]
        plot.border 0
        label_index = 1
        @labels ||= []
        la = @parameters[:label_align]
        @labels.each do |l|
          if la
            plot.label "#{label_index} '#{l[0]}' at #{l[1]},#{l[2]} #{la} font 'Latin-Modern,#{l[3]}' tc rgb '#{l[4]}'"
          else
            plot.label "#{label_index} '#{l[0]}' at #{l[1]},#{l[2]} font 'Latin-Modern,#{l[3]}' tc rgb '#{l[4]}'"
          end
          label_index += 1
        end
        plot.data << Gnuplot::DataSet.new([x, y]) do |ds|
          ds.with = "#{with} lc rgb '#{color}'"
          ds.notitle
        end
        @points ||= []
        @points.each do |x, y, c|
          plot.data << Gnuplot::DataSet.new([[x], [y]]) do |ds|
            ds.with = "points pt 7 lc rgb '#{c}'"
            ds.notitle
          end
        end
      end
    end
    self
  end

  # verticies is an array of points for an enclosed polygon
  def plot_polygon(vertices = [])
    return self.plot if vertices.empty?
    plot_lines([vertices + [vertices[0]]])
  end
end

class Plot3D < Plot
  def initialize(xmin, xmax, ymin, ymax, zmin, zmax)
    @parameters = {
      xmin: xmin,
      xmax: xmax,
      ymin: ymin,
      ymax: ymax,
      zmin: zmin,
      zmax: zmax,
      fn: "#{SecureRandom.uuid}.png"
    }

    super(@parameters[:fn], {dynamic: true})
  end

  def set_view(view)
    @parameters[:view] = view
  end

  def add_label(text, x, y, z, size, color=nil)
    @labels ||= []
    @labels << [text, x, y, z, size, self.color(color)]
  end

  def add_polygon(vertices)
    @lines ||= []
    # add outline
    x = []
    y = []
    z = []
    vertices.each do |xv, yv, zv|
      x << xv
      y << yv
      z << zv
    end
    x << vertices[0][0]
    y << vertices[0][1]
    z << vertices[0][2]
    @lines << [x, y, z]
  end

  def add_gridded_polygon(vertices)
    add_polygon(vertices)
    # extract first vector
    a = [vertices[0][0] - vertices[1][0],
         vertices[0][1] - vertices[1][1],
         vertices[0][2] - vertices[1][2]]
    # extract second vector
    b = [vertices[2][0] - vertices[1][0],
         vertices[2][1] - vertices[1][1],
         vertices[2][2] - vertices[1][2]]
    # normal to polygon
    p_norm = compute_normal(a, b)
    # perpendicular to first vector
    first_direction = compute_normal(a, p_norm)
    # draw lines in first direction
    add_polygon_gridlines(vertices, vertices[0], vertices[1], first_direction)
    first_direction = first_direction.map {|p| -1*p}
    add_polygon_gridlines(vertices, vertices[0], vertices[1], first_direction)
    # second direction
    second_direction = compute_normal(first_direction, p_norm)
    two = [vertices[0][0] + first_direction[0],
           vertices[0][1] + first_direction[1],
           vertices[0][2] + first_direction[2]]
    add_polygon_gridlines(vertices, vertices[0], two, second_direction)
    second_direction = second_direction.map {|p| -1*p}
    add_polygon_gridlines(vertices, vertices[0], two, second_direction)
  end

  def plot
    x = [(@parameters[:xmax] - @parameters[:xmin]) * 2 + @parameters[:xmax]]
    y = [(@parameters[:ymax] - @parameters[:ymin]) * 2 + @parameters[:ymax]]
    z = [(@parameters[:zmax] - @parameters[:zmin]) * 2 + @parameters[:zmax]]
    plot_generic(x, y, z, "lines")
  end

  def plot_generic(x, y, z, with)
    Gnuplot.open do |gp|
      Gnuplot::SPlot.new(gp) do |plot|
        plot.terminal "pngcairo size 460,460"
        plot.output @parameters[:fn]
        plot.key "off"
        plot.xrange "[#{@parameters[:xmin]}:#{@parameters[:xmax]}]"
        plot.yrange "[#{@parameters[:ymin]}:#{@parameters[:ymax]}]"
        plot.zrange "[#{@parameters[:zmin]}:#{@parameters[:zmax]}]"
        plot.unset 'xtics'
        plot.unset 'ytics'
        plot.unset 'ztics'
        if @parameters[:view]
          plot.view @parameters[:view]
        end
        plot.border 0
        label_index = 1
        @labels ||= []
        @labels.each do |text, x, y, z, size, c|
          plot.label "#{label_index} '#{text}' at #{x}, #{y}, #{z} font 'Latin-Modern,#{size}' tc rgb '#{c}'"
          label_index += 1
        end
        plot.data << Gnuplot::DataSet.new([x, y, z]) do |ds|
          ds.with = "#{with} lc rgb '#{color}'"
          ds.notitle
        end
        @lines ||= []
        @lines.each do |x, y, z, c|
          plot.data << Gnuplot::DataSet.new([x, y, z]) do |ds|
            ds.with = "lines lc rgb '#{color}'"
            ds.notitle
          end
        end
      end
    end
    self
  end

  private
  def add_polygon_gridlines(vertices, p1, p2, direction)
    # move 1 step in direction
    one = [p1[0] + direction[0],
           p1[1] + direction[1],
           p1[2] + direction[2]]
    two = [p2[0] + direction[0],
           p2[1] + direction[1],
           p2[2] + direction[2]]
    # find intersection points
    if points = polygon_intersection(vertices, one, two)
      one = points[0]
      two = points[1]
    end
    # make sure intersection points are interior to polygon
    while check_interior(vertices, one) and check_interior(vertices, two)
      @lines << [[one[0], two[0]],
                 [one[1], two[1]],
                 [one[2], two[2]]]
      one = [one[0] + direction[0],
             one[1] + direction[1],
             one[2] + direction[2]]
      two = [two[0] + direction[0],
             two[1] + direction[1],
             two[2] + direction[2]]
      if points = polygon_intersection(vertices, one, two)
        one = points[0]
        two = points[1]
      end
    end
  end
  
  def compute_normal(a, b)
    # normalize vectors to 1 unit
    a = normalize(a)
    b = normalize(b)
    # calculate normal
    [a[1]*b[2] - a[2]*b[1],
     a[2]*b[0] - a[0]*b[2],
     a[0]*b[1] - a[1]*b[0]]
  end

  # sum of angles for interior point should be 2 * pi
  def check_interior(polygon, point)
    sum = 0
    polygon.each_index do |i|
      next_i = i + 1
      next_i = 0 if next_i >= polygon.size
      sum += compute_angle(
        [polygon[i][0] - point[0],
         polygon[i][1] - point[1],
         polygon[i][2] - point[2]],
        [polygon[next_i][0] - point[0],
         polygon[next_i][1] - point[1],
         polygon[next_i][2] - point[2]],
      )
    end

    (sum >= 2*3.1415926 and sum <= 2*3.1415927) or
      check_border(polygon, point)
  end

  def check_border(polygon, point)
    polygon.each_index do |i|
      next_i = i + 1
      next_i = 0 if next_i >= polygon.size
      xs = [polygon[i][0], polygon[next_i][0]]
      next unless (xs.min..xs.max).include?(point[0])
      ys = [polygon[i][1], polygon[next_i][1]]
      next unless (ys.min..ys.max).include?(point[1])
      zs = [polygon[i][2], polygon[next_i][2]]
      next unless (zs.min..zs.max).include?(point[2])
      a = normalize([polygon[i][0] - point[0],
                     polygon[i][1] - point[1],
                     polygon[i][2] - point[2]])
      b = normalize([polygon[next_i][0] - point[0],
                     polygon[next_i][1] - point[1],
                     polygon[next_i][2] - point[2]])
      return true if vector_mag(a) < 0.0001 or vector_mag(b) < 0.0001
      if (a[0] - b[0]).abs < 0.0001 and
        (a[1] - b[1]).abs < 0.0001 and
        (a[2] - b[2]).abs < 0.0001
        return true
      end
    end
    return false
  end

  def polygon_intersection(polygon, p1, p2)
    points = []
    polygon.each_index do |i|
      next_i = i + 1
      next_i = 0 if next_i >= polygon.size
      if point = line_intersection(polygon[i], polygon[next_i],
                                   p1, p2)
        if check_interior(polygon, point) and not(points.include? point)
          points << point
        end
      end
      break if points.size == 2
    end
    if points.size == 2
      points
    else
      [p1, p2]
    end
  end

  # http://paulbourke.net/geometry/pointlineplane/
  def line_intersection(l1p1, l1p2, l2p1, l2p2)
    # calculate segments
    l13 = [l1p1[0] - l2p1[0],
             l1p1[1] - l2p1[1],
             l1p1[2] - l2p1[2]]
    l43 = [l2p2[0] - l2p1[0], 
          l2p2[1] - l2p1[1],
           l2p2[2] - l2p1[2]]
    l21 = [l1p2[0] - l1p1[0],
           l1p2[1] - l1p1[1],
           l1p2[2] - l1p1[2]]

    return false if vector_mag(l43) < 0.00001
    return false if vector_mag(l21) < 0.00001

    l43 = normalize(l43)
    l21 = normalize(l21)

    # cross products
    d1343 = dot_product(l13, l43)
    d4321 = dot_product(l43, l21)
    d1321 = dot_product(l13, l21)
    d4343 = dot_product(l43, l43)
    d2121 = dot_product(l21, l21)

    denom = d2121 * d4343 - d4321 * d4321
    numer = d1343 * d4321 - d1321 * d4343

    if denom < 0.000001
      return false
    end

    mua = numer / denom.to_f
    mub = (d1343 + d4321 * mua) / d4343

    point1 = [
      l1p1[0] + mua * l21[0],
      l1p1[1] + mua * l21[1],
      l1p1[2] + mua * l21[2]
    ]

    point2 = [
      l2p1[0] + mub * l43[0],
      l2p1[1] + mub * l43[1],
      l2p1[2] + mub * l43[2]
    ]

    if (point1[0] - point2[0]) > 0.0000001 or
      (point1[1] - point2[1]) > 0.0000001 or
      (point1[2] - point2[2]) > 0.0000001
      return false
    end

    point1
  end

  def normalize(a)
    a_mag = vector_mag(a)
    return a if a_mag == 0
    a = a.map {|n| n/a_mag}
  end

  def vector_mag(a)
    a_mag = Math.sqrt(a.inject(0) do |sum, n|
                        sum += n*n
                      end)
  end

  def dot_product(u, v)
    u[0]*v[0]+u[1]*v[1]+u[2]*v[2]
  end

  def compute_angle(u, v)
    u = normalize(u)
    v = normalize(v)
    dot = dot_product(u, v)
    dot = 1 if dot > 1
    dot = -1 if dot < -1
    Math.acos(dot)
  end
end

class BoxPlot < Plot
  def initialize(labels = [])
    @parameters = {
      fn: "#{SecureRandom.uuid}.png"
    }

    @labels ||= []
    labels.each do |x|
      @labels << [x[0], x[1], x[2], x[3], self.color(x[4])]
    end

    super(@parameters[:fn], {dynamic: true})
  end

  def add_label(text, x, y, size, color=nil)
    @labels ||= []
    @labels << [text, x, y, size, self.color(color)]
  end

  # points is an array of values to plot on the number line
  def plot(points = [])
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
    
        min_x = points.min - 1
        max_x = points.max + 1

        plot.terminal "pngcairo"
        plot.output @parameters[:fn]

        plot.style  "data boxplot"
        plot.unset "xtics"
        plot.grid "y2tics lc rgb \"#888888\" lw 1 lt 0"
        plot.yrange "[#{min_x}:#{max_x}]"
        plot.y2range "[#{min_x}:#{max_x}]"
        plot.y2tics "center rotate by 90 font \",15\""
        plot.unset "ytics"

        x = []
        y = []
        (min_x..max_x).to_a.each do |current_x|
            points.grep(current_x).size.times do
            x << 1
            y << current_x
          end if points.grep(current_x).size
        end
        plot.data << Gnuplot::DataSet.new([x, y]) do |ds|
          ds.title = ''
        end

        label_index = 1
        @labels ||= []
        @labels.each do |l|
          plot.label "#{label_index} '#{l[0]}' at #{l[1]}, #{l[2]} font 'Latin-Modern,#{l[3]}' tc rgb '#{l[4]}' rotate by 90 center"
          label_index += 1
        end

      end
    end
    `convert -rotate 90 #{@parameters[:fn]} #{@parameters[:fn]}`
    @parameters[:fn]
  end
end

class DoubleBoxPlot < Plot
  def initialize(labels = [])
    @parameters = {
      fn: "#{SecureRandom.uuid}.png"
    }

    @labels ||= []
    labels.each do |x|
      @labels << [x[0], x[1], x[2], x[3], self.color(x[4])]
    end

    super(@parameters[:fn], {dynamic: true})
  end

  def add_label(text, x, y, size, color=nil)
    @labels ||= []
    @labels << [text, x, y, size, self.color(color)]
  end

  # points is an array of values to plot on the number line
  def plot(points = [], points2 = [])
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
    
        min_x = (points + points2).min - 1
        max_x = (points + points2).max + 1

        plot.terminal "pngcairo"
        plot.output @parameters[:fn]

        plot.style  "data boxplot"
        plot.unset "xtics"
        plot.grid "y2tics lc rgb \"#888888\" lw 1 lt 0"
        plot.yrange "[#{min_x}:#{max_x}]"
        plot.y2range "[#{min_x}:#{max_x}]"

        plot.xrange "[0.6:2]"
        plot.x2range "[0.6:2]"

        plot.y2tics "center rotate by 90 font \",15\""
        plot.unset "ytics"

        x = []
        y = []

        (min_x..max_x).to_a.each do |current_x|
            points.grep(current_x).size.times do
            x << 1
            y << current_x
          end if points.grep(current_x).size
        end

        x2 = []
        y2 = []
        (min_x..max_x).to_a.each do |current_x|
            points2.grep(current_x).size.times do
            x2 << 1.6
            y2 << current_x
          end if points2.grep(current_x).size
        end
        
        plot.data = [
          Gnuplot::DataSet.new([x, y]) { |ds|
            ds.title = ''
          },

          Gnuplot::DataSet.new([x2, y2]) { |ds|
            ds.title = ''
            ds.linecolor = "rgb \"red\""
          }
        ]

        label_index = 1
        @labels ||= []
        @labels.each do |l|
          plot.label "#{label_index} '#{l[0]}' at #{l[1]}, #{l[2]} font 'Latin-Modern,#{l[3]}' tc rgb '#{l[4]}' rotate by 90 center"
          label_index += 1
        end

      end
    end
    `convert -rotate 90 #{@parameters[:fn]} #{@parameters[:fn]}`
    @parameters[:fn]
  end
end

class HighChart < Plot
  # params is a hash
  # * type: specifies chart type
  #   valid types are:
  #   * piechart
  #   * numberline
  # * title: specifies chart title
  def initialize(params)
    @params = params
    # symbolize keys and type params
    @params.keys.each do |k|
      s = k.to_sym
      if s != k
        @params[s] = @params[k]
        @params.delete(k)
      end
      if s == :type
        @params[s] = @params[s].to_sym
      end
    end

    # pass colors through symbol => hex conversion
    if @params[:colors]
      self.colors = @params[:colors]
    end
  end

  def chart_id
    @chart_id ||= SecureRandom.uuid
  end

  def colors=(colors)
    @params[:colors] = colors.map do |c|
      if c.class == Symbol
        Plot.color(c)
      else
        c
      end
    end
  end

  def xmin=(m)
    @params[:xmin] = m
  end

  def xmax=(m)
    @params[:xmax] = m
  end

  def width=(w)
    @params[:width] = w
  end

  def height=(h)
    @params[:height] = h
  end

  def colors
    @params[:colors] || Plot.hex_colors
  end

  def input_enabled=(ie)
    @params[:input_enabled] = ie
  end

  def input_enabled
    @params[:input_enabled].nil? ? false : @params[:input_enabled]
  end

  def select_enabled=(se)
    @params[:select_enabled] = se
  end

  def select_enabled
    @params[:select_enabled].nil? ? true : @params[:select_enabled]
  end

  def shade_on_click_enabled=(soc)
    @params[:shade_on_click_enabled] = soc
  end

  def shade_on_click_enabled
    @params[:shade_on_click_enabled].nil? ? false : @params[:shade_on_click_enabled]
  end

  def labels_enabled=(le)
    @params[:labels_enabled] = le
  end

  def labels_enabled
    @params[:labels_enabled].nil? ? true : @params[:labels_enabled]
  end

  def tooltip_enabled=(te)
    @params[:tooltip_enabled] = te
  end

  def tooltip_enabled
    @params[:tooltip_enabled].nil? ? true : @params[:tooltip_enabled]
  end

  def decimals=(d)
    @params[:decimals] = d
  end

  def to_s
    "HighChart: params = #{@params.inspect}"
  end

  def to_json(*a)
    @params.to_json(*a)
  end

  def self.from_json(string)
    params = JSON.parse(string)
    self.new(params)
  end

  def chart_template
    case @params[:type]
    when :piechart
      'highchart_piechart'
    when :numberline
      'highchart_numberline'
    end
  end

  def data
    @params[:data].to_a.to_json
  end

  # data as a hash (key-value pairs) or array
  def data=(hash)
    @params[:data] = hash
  end

  def raw_data
    @params[:data]
  end

  def parameters
    @params
  end

  def method_missing(name)
    @params[name]
  end
end

class PlotRelation < Plot
  # relation is array of x,y pairs
  # ex: relation = [[1,2],[2,3],[6,2]]
  def initialize(relation)
    @parameters = {
      r: relation,
      fn: "#{SecureRandom.uuid}.png"
    }
    super(@parameters[:fn], {dynamic: true})
  end

  def plot
    xs, ys = r.transpose
    uniq_xs = xs.uniq
    uniq_ys = ys.uniq
    x_spacing = 1.0 / (uniq_xs.size - 1)
    y_spacing = 1.0 / (uniq_ys.size - 1)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal "pngcairo size 460,460"
        plot.output @parameters[:fn]
        plot.key "off"
        plot.xrange "[-1:1]"
        plot.yrange "[-1:1]"
        plot.unset "xtics"
        plot.unset "ytics"
        plot.border 0
        plot.object "1 ellipse center -0.5,0 size 0.75,1.75 front fs empty bo 3 fc rgb '#{Plot.color(:blue)}'"
        plot.object "2 ellipse center 0.5,0 size 0.75,1.75 front fs empty bo 3 fc rgb '#{Plot.color(:blue)}'"
        label_index = 1
        uniq_xs.each_with_index do |x, i|
          plot.label "#{label_index} '#{x}' at -0.55,#{0.5 - x_spacing*i} font 'Latin-Modern,20' tc rgb '#{Plot.color(:green)}'"
          label_index += 1
        end
        uniq_ys.each_with_index do |y, i|
          plot.label "#{label_index} '#{y}' at 0.5,#{0.5 - y_spacing*i} font 'Latin-Modern,20' tc rgb '#{Plot.color(:green)}'"
          label_index += 1
        end
        xs.each_with_index do |x, i|
          y = ys[i]
          plot.arrow "from -0.45,#{0.5 - x_spacing*uniq_xs.index(x)} to 0.5,#{0.5 - y_spacing*uniq_ys.index(y)} filled lc rgb '#{Plot.color(:red)}'"
        end
        plot.label "#{label_index} 'Domain' at -0.75,-1 font 'Latin-Modern,20' tc rgb '#{Plot.color(:green)}'"
        plot.label "#{label_index + 1} 'Range' at 0.3,-1 font 'Latin-Modern,20' tc rgb '#{Plot.color(:green)}'"
        plot.data << Gnuplot::DataSet.new([[10],[10]])
      end
    end
    self
  end

  def method_missing(n)
    @parameters[n]
  end
end

class PlotTriangle < CoordinatePlane
  # triangle can be specified as:
  # angles: angles in degrees that sum to 180 [a1, a2, a3]
  # vertices: points on the coordinate plane [[x1, y1], [x2, y2], [x3, y3]]
  #   vertices should be specified counter-clockwise
  #
  # when specified by angles, no coordinate plane is displayed
  def initialize(params)
    if params[:angles]
      # angles
      super(0, 1, 0, 1)
      no_axes
      @parameters.merge!(params)
      # sort angles
      sorted = angles.sort
      # convert to radians
      sorted_radians = sorted.map do |a|
        a*Math::PI/180
      end
      # calculate last point
      right = Math::PI/2
      s1 = Math.sin(right - sorted_radians[0])
      c1 = Math.cos(right - sorted_radians[0])
      s2 = Math.sin(right - sorted_radians[1])
      c2 = Math.cos(right - sorted_radians[1])
      x = 3*c2/(4*s2*(c1/s1 + c2/s2))
      y = x*c1/s1
      # adjust for first point
      x += 0.125
      y += 0.125
      final_point = [x, y]
      @parameters[:vertices] = [[0.125, 0.125],
                                [0.875, 0.125],
                                final_point]
      @parameters[:calculated_angles] = sorted
      @parameters[:x_range] = 1
      @parameters[:y_range] = 1
    else
      # vertices
      xs, ys = params[:vertices].transpose
      # determine bounds
      x_min = (xs.min - 1).floor
      x_max = (xs.max + 1).ceil
      y_min = (ys.min - 1).floor
      y_max = (ys.max + 1).ceil
      x_tics = [1, (x_max - x_min)/10].max
      y_tics = [1, (y_max - y_min)/10].max
      super(x_min, x_max, y_min, y_max, x_tics, y_tics)
      @parameters.merge!(params)
      # calculate angles
      side1 = Math.sqrt((vertices[0][0] - vertices[1][0])**2 +
                        (vertices[0][1] - vertices[1][1])**2)
      side2 = Math.sqrt((vertices[2][0] - vertices[1][0])**2 +
                        (vertices[2][1] - vertices[1][1])**2)
      side3 = Math.sqrt((vertices[0][0] - vertices[2][0])**2 +
                        (vertices[0][1] - vertices[2][1])**2)
      angles = []
      # Law of Cosines
      angles[0] = Math.acos((side3**2 + side1**2 - side2**2)/(2*side1*side3))
      # Law of Sines
      angles[1] = Math.asin((side3*Math.sin(angles[0]))/side2)
      angles[2] = Math::PI - (angles[0] + angles[1])
      angles.map! do |a|
        a*180/Math::PI
      end
      # sort angles and vertices based on angle
      angle_vertices = angles.each_with_index.map do |a, i|
        [a, vertices[i]]
      end.sort do |a, b|
        a[0] <=> b[0]
      end
      # extract angles
      @parameters[:calculated_angles] = angle_vertices.map do |a, v|
        a
      end
      # extract vertices
      @parameters[:vertices] = angle_vertices.map do |a, v|
        v
      end
      @parameters[:x_range] = x_max - x_min
      @parameters[:y_range] = y_max - y_min
    end
    self.label_align = 'center'
  end

  def label_vertices
    @parameters[:label_vertices?] = true
  end

  def label_angles
    @parameters[:label_angles?] = true
  end

  def angle_labels=(labels)
    @parameters[:alabels] = labels
  end

  def edge_labels(short, medium, long)
    # calculate midpoint of each edge
    l = [(vertices[0][0] + vertices[1][0])/2.0, (vertices[0][1] + vertices[1][1])/2.0]
    # find vector from center of triangle to midpoint of edge
    l_v = unit_vector(center, l)
    m = [(vertices[0][0] + vertices[2][0])/2.0, (vertices[0][1] + vertices[2][1])/2.0]
    m_v = unit_vector(center, m)
    s = [(vertices[1][0] + vertices[2][0])/2.0, (vertices[1][1] + vertices[2][1])/2.0]
    s_v = unit_vector(center, s)
    # add label, moving slighlty along vector (scaled to graph range)
    add_label(short, s[0] + 0.05*s_v[0]*x_range, s[1] + 0.05*s_v[1]*y_range, 12)
    add_label(medium, m[0] + 0.05*m_v[0]*x_range, m[1] + 0.05*m_v[1]*y_range, 12)
    add_label(long, l[0] + 0.05*l_v[0]*x_range, l[1] + 0.05*l_v[1]*y_range, 12)
  end

  def plot
    # find angle midpoint vectors
    vectors = vertices.each_with_index.map do |v, i|
      a = [0,1,2]
      a.delete(i)
      # vector to other points
      v1 = unit_vector(v, vertices[a[0]])
      v2 = unit_vector(v, vertices[a[1]])
      # average them
      average_vector(v1, v2)
    end
    if label_vertices?
      vertices.each_with_index do |v, i|
        x, y = v
        # round display values, but not positioning values
        x_r = (x*10).round/10.0
        x_r = x if x_r == x
        y_r = (y*10).round/10.0
        y_r = y if y_r == y
        uv = vectors[i]
        # move opposite of angle midpoint vector
        add_label("(#{x_r}, #{y_r})", x - 0.1*uv[0]*x_range, y - 0.1*uv[1]*y_range, 12)
      end
    end
    angle_labels
    if label_angles? or alabels
      labels = nil
      if alabels
        # display submitted angles
        labels = alabels
      else
        # round displayed angles
        labels = calculated_angles.map do |a|
          a = (a*10).round/10.0
          if a == a.to_i
            a.to_i
          else
            a
          end
        end
      end
      vertices.each_with_index do |v, i|
        uv = vectors[i]
        # move in direction of angle midpoint vector
        add_label(labels[i], v[0] + 0.1*uv[0]*x_range, v[1] + 0.1*uv[1]*y_range, 12)
      end
    end
    plot_polygon(vertices)
  end

  def method_missing(n)
    @parameters[n]
  end

  private
  # find center of triangle
  def center
    @center ||= begin
                  xs, ys = vertices.transpose
                  [xs.inject(:+)/xs.size.to_f, ys.inject(:+)/ys.size.to_f]
                end
  end

  # find unit vector from p1 to p2
  def unit_vector(p1, p2)
    x = p2[0] - p1[0]
    y = p2[1] - p1[1]
    normalize_vector([x,y])
  end

  # normalize vector to 1 unit length
  def normalize_vector(v)
    d = v[0]*v[0] + v[1]*v[1]
    if d != 1
      root = Math.sqrt(d)
      v[0] /= root
      v[1] /= root
    end
    v
  end

  # find average of two vectors (recommend normalizing first)
  def average_vector(v1, v2)
    [(v1[0] + v2[0])/2.0, (v1[1] + v2[1])/2.0]
  end
end
