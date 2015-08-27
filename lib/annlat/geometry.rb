module Geometry
  class Point2D
    attr_accessor :x, :y

    def initialize(x, y)
      @x = x.to_f
      @y = y.to_f
    end

    def self.origin
      @@origin ||= self.new(0, 0)
    end

    def translate(vector)
      @x += vector.x
      @y += vector.y
    end

    def reflect(line)
      if line.dx == 0
        # handle vertical case
        @x = 2*line.p1.x - @x
      else
        # handle non vertical case
        perp_slope = -1/line.slope
        perp_line = Line2D.from_slope_and_point(perp_slope, self)
        intersection = line.intersection(perp_line)
        vector = intersection - self
        @x = intersection.x + vector.x
        @y = intersection.y + vector.y
      end
    end

    def rotate(angle, center=self.class.origin)
      # translate center to orign
      o = self.class.origin
      vector = o - center
      self.translate(vector)
      # rotate
      rad = Math::PI*angle/180.0
      d = (self - o).distance
      current_rad = Math.atan2(@y, @x)
      x = d*Math.cos(rad + current_rad)
      y = d*Math.sin(rad + current_rad)
      @x = x
      @y = y
      # translate origin to center
      vector.negate
      self.translate(vector)
    end

    def -(other)
      Vector2D.new(@x - other.x, @y - other.y)
    end

    def +(other)
      Point2D.new(@x + other.x, @y + other.y)
    end
  end

  class Vector2D < Point2D
    def normalize
      d = distance
      @x /= d
      @y /= d
    end

    def distance
      Math.sqrt(@x*@x + @y*@y)
    end

    def scale(d)
      Vector2D.new(d*@x, d*@y)
    end

    def negate
      @x *= -1
      @y *= -1
    end
  end

  class Line2D
    attr_accessor :p1, :p2
    # params can be:
    # slope, intercept: y = slope*x + intercept
    # point1, point2: two point objects
    # points: array of x, y pairs (ex: [[0, 0], [1, 1]])
    # x: vertical line at x
    def initialize(params)
      if params[:slope] and params[:intercept]
        @p1 = Point2D.new(0, params[:intercept])
        @p2 = Point2D.new(1, params[:slope] + params[:intercept])
      elsif params[:point1] and params[:point2]
        @p1 = params[:point1]
        @p2 = params[:point2]
      elsif params[:points]
        @p1 = Point2D.new(params[:points][0][0], params[:points][0][1])
        @p2 = Point2D.new(params[:points][1][0], params[:points][1][1])
      elsif params[:x]
        @p1 = Point2D.new(params[:x], -1)
        @p2 = Point2D.new(params[:x], 1)
      end
    end

    def self.from_slope_and_point(slope, point)
      if slope.infinite?
        self.new(x: point.x)
      else
        point2 = point.dup
        vector = Vector2D.new(1, slope)
        point2.translate(vector)
        self.new(point1: point, point2: point2)
      end
    end

    def translate(vector)
      @p1.translate(vector)
      @p2.translate(vector)
    end

    def reflect(line)
      @p1.reflect(line)
      @p2.reflect(line)
    end

    def rotate(degrees, center=Point2D.origin)
      @p1.rotate(degrees, center)
      @p2.rotate(degrees, center)
    end

    def dy
      @p1.y - @p2.y
    end

    def dx
      @p1.x - @p2.x
    end

    def slope
      dy/dx
    end

    def intercept
      @p1.y - slope*@p1.x
    end

    def intersection(other)
      if slope.infinite? or other.slope.infinite?
        if slope.infinite? and other.slope == 0
          Point2D.new(p1.x, other.p1.y)
        elsif other.slope.infinite? and slope == 0
          Point2D.new(other.p1.x, p1.y)
        else
          i_slope1 = dx/dy
          i_slope2 = other.dx/other.dy
          num = i_slope1*intercept - i_slope2*other.intercept
          y_val = num/(i_slope1 - i_slope2)
          if y_val.infinite?
            if num == 0
              # lines identical
              :dependent
            else
              # parallel
              :inconsistent
            end
          else
            Point2D.new((y_val-intercept)*i_slope1, y_val)
          end
        end
      else
        x = (other.intercept - intercept)/(slope - other.slope)
        if x.infinite?
          if intercept == other.intercept
            # lines identical
            :dependent
          else
            # parallel
            :inconsistent
          end
        else
          Point2D.new(x, y(x))
        end
      end
    end

    def y(x)
      slope*x + intercept
    end
  end

  class Polygon2D
    # params can be
    # vertices: array of 3+ x-y pairs [[x1, y1], [x2, y2], [x3, y3]]
    # points: array of Point2D objects
    def initialize(params)
      if params[:vertices]
        @points = params[:vertices].map do |x, y|
          Point2D.new(x, y)
        end
      else
        @points = params[:points]
      end
    end

    def translate(vector)
      @points.each do |p|
        p.translate(vector)
      end
    end

    def reflect(line)
      @points.each do |p|
        p.reflect(line)
      end
    end

    def rotate(degrees, center=Point2D.origin)
      @points.each do |p|
        p.rotate(degrees, center)
      end
    end
  end
end
