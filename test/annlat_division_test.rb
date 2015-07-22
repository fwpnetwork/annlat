require 'test_helper'
require 'annlat/annlat_division'

class TestAnnLatDivision < Minitest::Test
  def test_steps_less_than_one
    l = AnnLat.new
    d = AnnLatDivision.new(9, 22)
    assert_equal [['0', '9', '0', '9'], :dot, ['4', '90', '88', '02'],
                  ['0', '020', '000', '020'], ['9', '0200', '0198', '0002'],
                  ['0', '00020', '00000', '00020'], [:repeat, 3]], d.steps
  end

  def test_steps_more_than_ten
    l = AnnLat.new
    d = AnnLatDivision.new(200, 12)
    assert_equal [["01", "20", "12", "08"], ["6", "080", "072", "008"], :dot,
                  ["6", "0080", "0072", "0008"], ["6", "00080", "00072", "00008"],
                  [:repeat, 3]],
                 d.steps
  end
end
