require 'gnuplot'
require 'annlat/image'

class Plot < Image

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

  # points is an array of values to plot on the number line
  def plot(points = [])
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal "pngcairo size 640,640"
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
          ds.with = "points pt 7"
          ds.notitle
        end
      end
    end
    if @parameters[:horizontal]
      `convert #{@parameters[:fn]} -crop 640x100+0+540 +repage #{@parameters[:fn]}`
    else
      `convert #{@parameters[:fn]} -crop 100x640+0+0 +repage #{@parameters[:fn]}`
    end
    self
  end
end

class CoordinatePlane < Plot

end
