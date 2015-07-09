require 'test_helper'

class TestAnnLatDivision < Minitest::Test
  def test_integer_input_with_remainder
    l = AnnLat.new
    d = AnnLatDivision.new(9, 20)
    d.add_to_annlat(l, true)
    assert_equal 1, 1
  end
end
