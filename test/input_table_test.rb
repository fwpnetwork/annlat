require 'test_helper'

class TestInputTable < Minitest::Test
  def test_three_by_three_with_headers
    it = InputTable.new(rows: 3, cols: 3, col_labels: ['Male', 'Female', 'Total'],
                        row_labels: ['Left', 'Right', 'Total'],
                        data: [[1, nil, nil], [nil, 3, nil], [18, nil, 33]])
    assert_equal "<table><tr><th></th><th>Male</th><th>Female</th><th>Total</th></tr>" +
                 "<tr><td>Left</td><td><span>1</span></td><td><input type=\"text\" name=\"answers[0]\" /></td>" +
                 "<td><input type=\"text\" name=\"answers[1]\" /></td></tr>" +
                 "<tr><td>Right</td><td><input type=\"text\" name=\"answers[2]\" /></td>" +
                 "<td><span>3</span></td><td><input type=\"text\" name=\"answers[3]\" /></td></tr>" +
                 "<tr><td>Total</td><td><span>18</span></td><td><input type=\"text\" name=\"answers[4]\" /></td><td><span>33</span></td></tr>" +
                 "</table>", it.to_html
  end

  def test_two_by_six_with_row_headers_header
    it = InputTable.new(rows: 6, cols: 2, col_labels: ['Day', 'Tally', 'Relative Frequency'],
                        row_labels: ['M', 'T', 'W', 'R', 'F', 'Total'],
                        data: [[3, '15%'], [4, '20%'], [6, '30%'], [2, nil], [5, nil], [20, '100%']])
    assert_equal "<table><tr><th>Day</th><th>Tally</th><th>Relative Frequency</th></tr>" +
                 "<tr><td>M</td><td><span>3</span></td><td><span>15%</span></td></tr>" +
                 "<tr><td>T</td><td><span>4</span></td><td><span>20%</span></td></tr>" +
                 "<tr><td>W</td><td><span>6</span></td><td><span>30%</span></td></tr>" +
                 "<tr><td>R</td><td><span>2</span></td><td><input type=\"text\" name=\"answers[0]\" /></td></tr>" +
                 "<tr><td>F</td><td><span>5</span></td><td><input type=\"text\" name=\"answers[1]\" /></td></tr>" +
                 "<tr><td>Total</td><td><span>20</span></td><td><span>100%</span></td></tr>" +
                 "</table>", it.to_html
  end
end
