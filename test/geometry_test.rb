require 'test_helper'

class GeometryTest < Minitest::Test
  include Geometry
  EPSILON = 0.00000001

  def test_translate_point2d
    point = Point2D.new(0, 0)
    vector1 = Vector2D.new(1, 1)
    vector2 = Vector2D.new(-1, 1)
    vector3 = Vector2D.new(1, -1)
    vector4 = Vector2D.new(-1, -1)
    assert_equal 0, point.x
    assert_equal 0, point.y
    point.translate(vector1)
    assert_equal 1, point.x
    assert_equal 1, point.y
    point.translate(vector2)
    assert_equal 0, point.x
    assert_equal 2, point.y
    point.translate(vector3)
    assert_equal 1, point.x
    assert_equal 1, point.y
    point.translate(vector4)
    assert_equal 0, point.x
    assert_equal 0, point.y
  end

  def test_reflect_point2d
    orig_point = Point2D.new(1, -1)
    # y = x
    line1 = Line2D.new(slope: 1, intercept: 0)
    point = orig_point.dup
    point.reflect(line1)
    assert_equal -1, point.x
    assert_equal 1, point.y
    # y = 1
    line2 = Line2D.new(point1: Point2D.new(-1, 1), point2: Point2D.new(1, 1))
    point = orig_point.dup
    point.reflect(line2)
    assert_equal 1, point.x
    assert_equal 3, point.y
    # y = 3x + 4
    line3 = Line2D.new(points: [[0, 4], [1, 7]])
    point = orig_point.dup
    point.reflect(line3)
    assert (-3.8 - point.x) < EPSILON
    assert (0.6 - point.y) < EPSILON
    # x = 0
    line3 = Line2D.new(x: 0)
    point = orig_point.dup
    point.reflect(line3)
    assert_equal -1, point.x
    assert_equal -1, point.y
  end

  def test_rotate_point2d
    orig_point = Point2D.new(1, 0)
    # 45 degrees about origin
    point = orig_point.dup
    point.rotate(45)
    assert (1/Math.sqrt(2) - point.x) < EPSILON
    assert (1/Math.sqrt(2) - point.y) < EPSILON
    # 45 degrees about 1, 0
    point = Point2D.new(2, 0)
    point.rotate(45, orig_point)
    assert (1 + 1/Math.sqrt(2) - point.x) < EPSILON
    assert (1/Math.sqrt(2) - point.y) < EPSILON
    # rotate (2, 2) 180 degrees around (1, 1)
    point = Point2D.new(2, 2)
    point.rotate(180, Point2D.new(1, 1))
    assert (0 - point.x) < EPSILON
    assert (0 - point.y) < EPSILON
  end

  def test_translate_line2d
    line = Line2D.new(x: 1)
    line.translate(Vector2D.new(1, 1))
    assert_equal 2, line.p1.x
    assert_equal 2, line.p2.x
    line = Line2D.new(points: [[1,1],[2,2]])
    line.translate(Vector2D.new(-1, -2))
    assert_equal 0, line.p1.x
    assert_equal -1, line.p1.y
    assert_equal 1, line.p2.x
    assert_equal 0, line.p2.y
  end

  def test_reflect_line2d
    line = Line2D.new(x: 1)
    line.reflect(Line2D.new(x: 0))
    assert_equal -1, line.p1.x
    assert_equal -1, line.p2.x
    line = Line2D.new(points: [[1, 1], [2, 2]])
    line.reflect(Line2D.new(x: 0))
    assert_equal -1, line.p1.x
    assert_equal 1, line.p1.y
    assert_equal -2, line.p2.x
    assert_equal 2, line.p2.y
    line = Line2D.new(points: [[1, 1], [2, 2]])
    line.reflect(Line2D.new(slope: 0, intercept: 1))
    assert_equal 1, line.p1.x
    assert_equal 1, line.p1.y
    assert_equal 2, line.p2.x
    assert_equal 0, line.p2.y
  end

  def test_rotate_line2d
    line = Line2D.new(points: [[1, 1], [2, 2]])
    line.rotate(45)
    assert (line.p1.x - line.p2.x) < EPSILON
    line = Line2D.new(points: [[1, 1], [2, 2]])
    line.rotate(90, Point2D.new(1, 1))
    assert_equal 1, line.p1.x
    assert_equal 1, line.p1.y
    assert (0 - line.p2.x) < EPSILON
    assert (2 - line.p2.y) < EPSILON
  end
end
