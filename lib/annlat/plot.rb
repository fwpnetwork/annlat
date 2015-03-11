require 'gnuplot'
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
      # split up coords, convert to integer
      c.split(',').map {|x| x.to_i}
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

  def color
    case @parameters[:color]
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

  def color=(c)
    raise "Invalid Color" unless self.class.available_colors.include?(c)
    @parameters[:color] = c
  end
end

class NumberLine < Plot
  def initialize(low, high, tics = 1, horizontal = true, id = 0)
    @parameters = {
      low: low,
      high: high,
      tics: tics,
      horizontal: horizontal,
      fn: "number_line_#{id}.png"
    }

    super(@parameters[:fn], {dynamic: true})
  end

  def range=(r)
    @parameters[:range] = r ? true : false
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
        points << @parameters[:high]*2 if points.empty?
        if @parameters[:horizontal]
          plot.xrange "[#{@parameters[:low]}:#{@parameters[:high]}]"
          plot.yrange "[0:1]"
          plot.border 1
          plot.xtics @parameters[:tics]
          plot.unset "ytics"
          points.each do |p|
            x << p
            y << 0
          end
        else
          plot.xrange "[0:1]"
          plot.yrange "[#{@parameters[:low]}:#{@parameters[:high]}]"
          plot.border 2
          plot.ytics @parameters[:tics]
          plot.unset "xtics"
          points.each do |p|
            x << 0
            y << p
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
      `convert #{@parameters[:fn]} -crop 100x460+0+0 +repage #{@parameters[:fn]}`
    end
    self
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
      fn: "coordinate_plane_#{id}.png"
    }

    super(@parameters[:fn], {dynamic: true})
  end

  def plot
    self.plot_points
  end

  # points is an array of points to plot on the coordinate plane
  def plot_points(points = [])
    x = []
    y = []
    points << [@parameters[:xhigh]*2,@parameters[:yhigh]*2] if points.empty?
    points.each do |p|
      x << p[0]
      y << p[1]
    end

    plot_generic(x, y, "points pt 7")
  end

  # lines is an array of end point lists
  # ex: lines = [[[1,2],[1,3]], [[3,2],[4,1]]] would plot two lines,
  # one from (1,2) to (1,3) and one from (3,2) to (4,1)
  # lines = [[[1,2],[3,4],[3,2]]] woudl plot a single line consisting of two segments
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
        plot.xzeroaxis
        plot.yzeroaxis
        plot.xrange "[#{@parameters[:xlow]}:#{@parameters[:xhigh]}]"
        plot.yrange "[#{@parameters[:ylow]}:#{@parameters[:yhigh]}]"
        plot.xtics "axis #{parameters[:xtics]}"
        plot.ytics "axis #{@parameters[:ytics]}"
        plot.border 0
        plot.grid "xtics lt 0 lc rgb '#bbbbbb'"
        plot.grid "ytics lt 0 lc rgb '#bbbbbb'"
        plot.data << Gnuplot::DataSet.new([x, y]) do |ds|
          ds.with = "#{with} lc rgb '#{color}'"
          ds.notitle
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
