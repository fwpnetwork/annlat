require 'test_helper'

class TestLatexEval < Minitest::Test
  def test_parse_nesting
    assert_equal (:x.l + (:y.l + (:z.l - 3.l))).latex,
    parse_unparse('x+\left(y+\left(z-3\right)\right)')

    assert_equal (:x.l + (:y.l + (:z.l/3.l))).latex,
    parse_unparse('x+\left(y+\frac{z}{3}\right)')

    assert_equal (:x.l + (:y.l/(:z.l/3.l))).latex,
    parse_unparse('x+\frac{y}{\frac{z}{3}}')

    assert_equal (:x.l + (:y.l/(:z.l/(3.l + :i.l)))).latex,
    parse_unparse('x+\frac{y}{\frac{z}{3+i}}')

    assert_equal (:x.l / (:y.l + 2.l)).latex,
    parse_unparse('\frac{x}{y+2}')

    # frac inside paren
    assert_equal (2.l*(:x.l + 2.l/3.l)).latex,
    parse_unparse('2\cdot\left(x+\frac{2}{3}\right)')

    # paren inside frac
    assert_equal (:x.l / (2.l * (:y.l + 2.l))).latex,
    parse_unparse('\frac{x}{2\cdot\left(y+2\right)}')

    # frac inside paren inside frac
    assert_equal (2.l/(3.l*(:x.l+:y.l/5.l))).latex,
    parse_unparse('\frac{2}{3\cdot\left(x+\frac{y}{5}\right)}')
  end

  def test_parse_string_with_spaces
    assert_equal "This is a test of a string".l.latex,
    parse_unparse('This\ is\ a\ test\ of\ a\ string')

    assert_equal "This is a test of a string with ".l.space(1.l / 4.l).latex,
    parse_unparse('This\ is\ a\ test\ of\ a\ string\ with\ \frac{1}{4}')

    assert_equal "This is a test of a string with ".l.space(1.l / 4.l).space('in the middle'.l).latex,
    parse_unparse('This\ is\ a\ test\ of\ a\ string\ with\ \frac{1}{4}\ in\ the\ middle')

    assert_equal "This is a test of a string with ".l.space(1.l / 4.l).space('in the middle and with extraneous spaces'.l).latex,
    parse_unparse(' This\ is\ a\ test\ of\ a\ st r ing\ with\ \frac{1} {4} \ in\ the\ middle\ and\ with \  extraneous\ spaces ')

    assert_equal "This is a test of a string with a multiplication problem".l.space(3.l*4.2.l).space('and extra spaces'.l).latex,
    parse_unparse('This\ is\ a\ test\ of\ a\ string\ with\ a\ multiplication\ problem\ 3  \c  do t 4.2     \ and\ extra\ spaces')

    assert_equal "This string doesn't have a space before the multiplication (".l.glue(3.l*4.l).glue(") or after".l).latex,
    parse_unparse('This\ string\ doesn\'t\ have\ a\ space\ before\ the\ multiplication\ (3\cdot 4)\ or\ after')
  end

  def test_factored
    assert_equal (4.l*(-3.l*:a.l+9.l*:b.l+7)).latex, parse_unparse("4\\cdot\\left(-3\\cdot a+9\\cdot b+7\\right)")
  end

  def test_parse_eval
    assert_equal 5, "3+\\frac{4}{2}".parse_latex.eval
    assert_equal -1, "3+\\frac{4}{2}-6".parse_latex.eval
    assert_equal 13, "3+4^2-6".parse_latex.eval
    assert_equal 13, "3+4^\\frac{4}{2}-6".parse_latex.eval
  end

  def test_parse_latex
    assert_equal "3+\\frac{4}{2}", parse_unparse("3+\\frac{4}{2}")
    assert_equal "3+\\frac{4}{2}-6", parse_unparse("3+\\frac{4}{2}-6")
    # differences in next 2 cases due to how platform writes latex and how LaRuby outputs
    assert_equal "3+4^{2}-6", parse_unparse("3+4^2-6")
    assert_equal "3+4^{\\frac{4}{2}}-6", parse_unparse("3+4^\\frac{4}{2}-6")
  end

  def test_eval
    assert_equal 5, (3.l + 4.l / 2.l).eval
    assert_equal -1, (3.l + 4.l / 2.l - 6.l).eval
    assert_equal 13, (3.l + 4.l ** 2.l - 6.l).eval
    assert_equal 13, (3.l + 4.l ** (4.l / 2.l) - 6.l).eval
  end

  def test_implicit_multiplication
    p = {'x' => 4.l}
    assert_equal (3.l * :x.l).subs(p).eval, (3.l % :x.l).subs(p).eval
    assert_equal "3\\cdot x", (3.l * :x.l).latex
    assert_equal "3x", (3.l % :x.l).latex
  end

  def test_comparisons
    assert_equal "x<n", (:x.l < :n.l).latex
    assert_equal "x>n", (:x.l > :n.l).latex
    assert_equal "x\\leqn", (:x.l <= :n.l).latex
    assert_equal "x\\geqn", (:x.l >= :n.l).latex
  end

  def test_parse_comparison
    assert_equal "x<n", parse_unparse("x<n")
    assert_equal "x>n", parse_unparse("x>n")
    assert_equal "x\\leqn", parse_unparse("x\\leqn")
    assert_equal "x\\geqn", parse_unparse("x\\geqn")
    # platform uses <= and >=, so ensure we parse that the same
    assert_equal "x\\leqn", parse_unparse("x<=n")
    assert_equal "x\\geqn", parse_unparse("x>=n")
  end

  def test_string_conversion
    assert_equal "This is a test", "This is a test".l.to_string
    assert_equal "This\\ is\\ a\\ test", "This is a test".l.latex
    assert_equal "This\\ is a test", "This\\ is a test".l.latex
  end

  def test_array_conversion
    assert_equal "\\begin{array}{|c|c|c|}
\\hline 1&2&3\\\\
\\hline 4&5&6\\\\
\\hline 7&8&9\\\\
\\hline 
\\end{array}",
    [[1,2,3],[4,5,6],[7,8,9]].l.latex
    assert_equal "\\begin{array}{|c|c|c|}
\\hline 1&2&3\\\\
\\hline 4&5&6\\\\
\\hline 7&8&9\\\\
\\hline 
\\end{array}",
    [[1,2,3],[4.l,5.l,6.l],[7,8,9]].l.latex
    assert_equal "\\begin{array}{|c|c|c|}
\\hline 1&2&3\\\\
\\hline 
\\end{array}", [[1,2,3]].l.latex
  end

  def test_table_simplification
    assert_equal '\begin{array}{|c|c|c|}
\\hline 1&2&3\\\\
\\hline 
\end{array}', [[1,2,1.l + 2.l]].l.simplify!.latex
  end

  def test_table_sum
    table = [[1,2,3,4,5,6,7,8,9,10].reverse].l
    assert_equal "10+9+8+7+6+5+4+3+2+1", table.sum.latex
    assert_equal "1+2+3+4+5+6+7+8+9+10", table.sum(true).latex
    assert_equal 55, table.sum.eval
  end

  def test_table_mean
    table = [[1,2,3,4,5,6,7,8,9,10]].l
    assert_equal 5.5, table.mean
  end

  def test_table_median
    table = [[1,2,3,4,5,6,7,8,9,10]].l
    assert_equal "\\frac{5+6}{2}", table.median.latex
    assert_equal 5.5, table.median.eval
  end

  def test_occurrences
    h = {"1"=>1, "2"=>2, "3"=>1}
    assert_equal h, [[1,2,3,2]].l.occurrences
  end

  def test_table_mode
    table = [[1,2,3,4,5,6,7,7,9,10]].l
    assert_equal 7, table.mode
  end

  def test_divide_float
    assert_equal 3.2, (32.l / 10.l).eval
    assert_equal 3, (30.l / 10.l).eval
    assert_equal 32, (32.l / 1.l).eval
  end

  def test_empty_table
    assert_equal "\\begin{array}{||}
\\hline \\\\
\\hline 
\\end{array}", [[]].l.latex
    assert_equal "\\begin{array}{|c|}
\\hline \\ \\\\
\\hline 
\\end{array}", [["\\ "]].l.latex
  end

  def test_dot_plot
    assert_equal "\\begin{array}{|cccc|}
\\hline \\ &\\ &\\bigcirc&\\ \\\\
\\bigcirc&\\ &\\bigcirc&\\ \\\\
\\bigcirc&\\bigcirc&\\bigcirc&\\ \\\\
\\bigcirc&\\bigcirc&\\bigcirc&\\bigcirc\\\\
\\hline1&2&3&4\\\\
\\hline 
\\end{array}", [[3,1,3,1,3],[1,2,3,4,2]].l.dot_plot.latex
  end

  def test_bar_chart_latex
    assert_equal "\\begin{array}{|ccccc|}
\\hline ^{4-}&\\ &\\ &\\lceil\\rceil&\\ \\\\[-5pt]
^{3-}&\\lceil\\rceil&\\ &|\\ |&\\ \\\\[-5pt]
^{2-}&|\\ |&\\lceil\\rceil&|\\ |&\\ \\\\[-5pt]
^{1-}&|\\ |&|\\ |&|\\ |&\\lceil\\rceil\\\\
\\hline \\ &1&2&3&4\\\\
\\hline 
\\end{array}", [[3,1,3,1,3],[1,2,3,4,2]].l.bar_chart_latex.latex
  end

  def test_higlight_middle
    assert_equal "\\underline{7}", 7.l.underline.latex
    assert_equal "\\begin{array}{|c|c|c|c|c|c|c|c|c|}
\\hline 1&2&\\underline{3}&\\underline{4}&\\underline{5}&\\underline{6}&7&8&9\\\\
\\hline 
\\end{array}",
    [[1,2,3,4,5,6,7,8,9]].l.highlight_middle.latex
  end

  private
  def parse_unparse(str)
    begin
      str.parse_latex.latex
    rescue SyntaxError
      'syntax error'
    end
  end
end
