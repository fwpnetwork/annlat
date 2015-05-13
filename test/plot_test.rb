require 'test_helper'

class TestPlot < Minitest::Test
  def test_check_interior
    polygon = [[0,0,0],[0,0,5],[5,0,10],[5,0,0]]
    p = Plot3D.new(0, 1, 0, 1, 0, 1)
    assert(p.instance_eval do
             check_interior(polygon, [0, 0, 0])
           end)
    assert(p.instance_eval do
             check_interior(polygon, [0, 0, 5])
           end)
    assert(p.instance_eval do
             check_interior(polygon, [5, 0, 10])
           end)
    assert(p.instance_eval do
             check_interior(polygon, [5, 0, 0])
           end)
    assert(not(p.instance_eval do
                 check_interior(polygon, [0, 0, 6])
               end))
  end
end
