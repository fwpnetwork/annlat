require 'test_helper'

class TestAnnLat < MiniTest::Unit::TestCase
  def test_add_step
    l = AnnLat.new
    l.add_step "First do this"
    l.add_step "Then do this"
    l.add_step "Finally, do this. ", "And this."
    assert_equal "Step 1: ", l.objects[0][0]
    assert_equal "Step 2: ", l.objects[1][0]
    assert_equal "Step 3: ", l.objects[2][0]
    assert_equal({tag: 'h4'}, l.options[0][:sentence_options])
    assert_equal({tag: 'h4'}, l.options[1][:sentence_options])
    assert_equal({tag: 'h4'}, l.options[2][:sentence_options])
  end

end
