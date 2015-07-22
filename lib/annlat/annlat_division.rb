class AnnLatDivision
  def initialize(numer, denom)
    @n = numer
    @d = denom
  end

  def add_to_annlat(l, use_remainder = false)
    @use_remainder = use_remainder
    l.add_step "Begin the division algorithm"
    convert_to_integer
    digit_count = @n_i.to_s.split('').size
    dot_found = false
    dot_index = nil
    remainder_i = @n_i
    steps.each_with_index do |step, i|
      if step == :dot
        dot_found = true
        dot_index = i
        next
      elsif step[0] == :repeat
        l.add_step "Recognize repeated remainder"
        l.add "Because you've already seen the remainder #{remainder_i}, you know that you have a repeating decimal."
        repeat_count = i - step[1] - 1
        if dot_found and dot_index > step[1]
          repeat_count -= 1
        end
        if repeat_count == 1
          l.add "The last digit repeats."
          l.add "You can indicate this with a bar over that digit"
        else
          l.add "The last #{repeat_count} digits repeat."
          l.add "You can indicate this with a bar over those digits"
        end
        l.add answer_table(repeat_count)
        next
      end
      digit, start, subtract, remainder = step
      digit_i, start_i, subtract_i, remainder_i = step.map do |part|
        part.to_i
      end
      l.add "Use mental math to find that #{@d_i}, goes into #{start_i}, #{digit_i} time#{digit_i == 1 ? '' : 's'}."
      l.add "First, multiply, #{digit_i} times #{@d_i} is #{subtract_i}."
      l.add "Then, subtract, #{start_i} minus #{subtract_i} is #{remainder_i}."
      if dot_found
        table_index = 2*(i-1)
      else
        table_index = 2*i
      end
      l.add tables[table_index]
      if not(dot_found) and steps[i+1] and steps[i+1] != :dot
        l.add_step "Bring down the next digit and continue"
      elsif use_remainder
        l.add "The remainder is #{remainder_i}"
        break
      elsif remainder.to_i == 0
        l.add "Since the remainder is 0, we end the division."
        l.add "The division result is #{@answer}"
        break
      else
        l.add_step "Add a 0"
        new_n = "#{@n_i}."
        new_n += "0"*(dot_found ? i-1 : i)
        l.add "Remember that #{@n_i} can be written #{new_n} and bring down the 0."
        remainder_i *= 10
      end
      l.add tables[table_index + 1]
    end
    l
  end

  def test(use_remainder = false)
    self.add_to_annlat(AnnLat.new, use_remainder).objects.each do |sentence|
      sentence.each do |word|
        if word.class <= Latex
          puts "\\[#{word.latex}\\]"
        else
          puts "#{word}<br />"
        end
      end
    end
  end

  def steps
    @steps ||= calculate_steps
  end

  private
  def answer_table(repeat_count)
    array = @answer.to_s.split('')
    table = array[-repeat_count..-1]
    table[0] = "\\hline #{table[0]}"
    under_table = [table].l
    under_table.set_lines :none
    before_table = [array[0..-(repeat_count+1)]].l
    before_table.set_lines :none
    before_table.glue(under_table)
  end

  def calculate_steps
    # result digit, start, subtract, remainder
    raw_steps = []
    convert_to_integer
    n_s = @n_i.to_s
    d_s = @d_i.to_s
    d = @d_i
    d_digit_count = d_s.split('').size
    n_array = n_s.split('')
    first = true
    if n_array.size > d_digit_count
      n = n_array[0..d_digit_count - 1].join.to_i
      remaining_digits = n_array[d_digit_count..-1]
      n_s = n_array[0..d_digit_count - 1].join
    else
      n = @n_i
      remaining_digits = []
    end
    dot_added = false
    seen = {}
    begin
      digit = (n/d).to_i
      subtract = d*digit
      remainder = (n - subtract)
      start = n_s
      digit_s = digit.to_s
      if first
        first = false
        while digit_s.size < start.size
          digit_s = "0#{digit_s}"
        end
      end
      raw_steps << [digit_s, start, subtract.to_s, remainder.to_s]
      if dot_added
        key = raw_steps[-1].join(',')
        unless seen[key].nil?
          raw_steps << [:repeat, seen[key]]
          break
        end
        seen[key] = raw_steps.size - 1
      end
      if remaining_digits.empty?
        n_s = "#{remainder}0"
        unless dot_added
          dot_added = true
          raw_steps << :dot
        end
      else
        n_s = "#{remainder}#{remaining_digits.shift}"
      end
      n = n_s.to_i
    end until remainder == 0
    digit, start, subtract, remainder = raw_steps[0]
    starting_digit_count = [start.size,
                            subtract.size, remainder.size].max
    dot_seen = false
    raw_steps.each_with_index.map do |step, i|
      if step == :dot
        dot_seen = true
        step
      elsif step[0] == :repeat
        step
      else
        digit_count = starting_digit_count + i
        digit_count -= 1 if dot_seen
        digit, start, subtract, remainder = step
        while subtract.size < digit_count
          subtract = "0#{subtract}"
        end
        while start.size < digit_count
          start = "0#{start}"
        end
        while remainder.size < digit_count
          remainder = "0#{remainder}"
        end
        [digit, start, subtract, remainder]
      end
    end
  end

  def tables
    @tables ||= generate_tables
  end

  def generate_tables
    tables = []
    digits = @n_i.to_s.split('')
    digit_count = digits.size
    answer_digits = []
    decimal_index = nil
    steps.each_with_index do |step, i|
      if step == :dot and @use_remainder
        break
      end
      next if step == :dot or step[0] == :repeat
      digit_s, start_s, subtraction_s, remainder_s = step
      digit, start, subtraction, remainder = step.map do |part|
        part.to_i
      end
      [false, true].each do |carry|
        if carry
          if steps[i+1] == :dot
            decimal_index = i + 1
            answer_digits << '.'
            digits << '.'
            digits << '0'
          elsif not(decimal_index.nil?) and i > decimal_index
            digits << '0'
          end
        else
          if digit_s.size > 1
            new_digits = digit_s.split('').map do |digit|
              digit == '0' ?
                '' : digit
            end
            new_digits[-1] = '0' if new_digits[-1] == ''
            answer_digits += new_digits
          else
            answer_digits << digit_s
          end
        end
        enclose_table = [digits].l
        enclose_table.align = "r"
        enclose_table.set_lines :none
        enclose_table = Atom.new("\\kern -6pt\\rlap{\\enclose{longdiv}{#{enclose_table.latex}}}")
        raw_table = [
          [''] + answer_digits,
          [@d_i, enclose_table]
        ]
        remainder_digits = digits.dup
        # display intermediate steps
        carry_start = steps[0][0].size
        (0..i).each do |j|
          next if steps[j] == :dot
          subtraction_digits = steps[j][2].to_s.split('')
          subtraction = ['-'] + subtraction_digits
          if decimal_index and j + 1 > decimal_index
            subtraction = subtraction[0..digit_count] + ['.'] + subtraction[digit_count + 1..-1]
          end
          nonzero_found = false
          subtraction = subtraction.map do |digit|
            if nonzero_found or digit == '-'
              digit
            elsif digit == '0' or digit == '.'
              "\\phantom{0}"
            else
              nonzero_found = true
              digit
            end
          end
          unless nonzero_found
            subtraction[-1] = '0'
          end
          raw_table << subtraction
          remainder_digits = steps[j][3].to_s.split('')
          if carry or j < i
            if digits[j+carry_start].latex == '.'
              remainder_digits += [digits[j+carry_start+1]]
            else
              remainder_digits += [digits[j+carry_start]]
            end
          end
          if (carry and steps[j+1] == :dot) or
            remainder_digits.size > digit_count
            remainder_digits = remainder_digits[0..digit_count-1] + ['.'] + remainder_digits[digit_count..-1]
          end
          nonzero_found = false
          remainder_digits = remainder_digits.map do |digit|
            if nonzero_found
              digit
            elsif digit == '0' or digit == '.'
              "\\phantom{0}"
            else
              nonzero_found = true
              digit
            end
          end
          unless nonzero_found
            remainder_digits[-1] = '0'
          end
          remainder_digits[0] = "\\hline #{remainder_digits[0]}"
          remainder_table = [remainder_digits].l
          remainder_table.align = "r"
          remainder_table.set_lines :none
          raw_table << ['', Atom.new("\\kern -6pt\\rlap{#{remainder_table.latex}}")]
        end
        table = raw_table.l
        table.align = 'l'
        table.set_lines :none
        tables << table
      end
    end
    while ['0', ''].include? answer_digits[0]
      answer_digits.shift
    end
    @answer = answer_digits.join
    tables
  end

  def convert_to_integer
    @n_i = @n
    @d_i = @d
    shift = 0
    while @n_i.round(5) != @n_i.round or
          @d_i.round(5) != @d_i.round
      shift += 1
      @n_i *= 10
      @d_i *= 10
    end
    @n_i = @n_i.round
    @d_i = @d_i.round
  end
end
