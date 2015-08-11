class InputTable
  # require params are:
  # rows: number of rows
  # cols: number of columns
  # optional params:
  # col_labels: array of cols (or cols+1) column labels
  #   if cols+1, the extra label goes above the row labels
  # row_labels: array of rows row labels
  # data: row-major 2D array of data, nils for empty spaces
  def initialize(params)
    @params = params
    # symbolize keys
    @params.keys.each do |k|
      s = k.to_sym
      if s != k
        @params[s] = @params[k]
        @params.delete(k)
      end
    end
    @params[:type] = :table
  end

  def to_html
    @answer_number = -1
    html = "<table>"
    r = rows
    c = cols
    r += 1 unless col_labels.nil?
    c += 1 unless row_labels.nil?
    if col_labels
      array = col_labels
      array = [nil] + array unless array.size == c
      header = array_to_td(array, 'th')
      html = add_row(html, header)
    end
    i = 0
    data.each do |row|
      array = row
      array = [row_labels[i]] + row unless array.size == c
      html = add_row(html, array_to_td(array))
      i += 1
    end
    html += "</table>"
    html
  end

  def to_json(*a)
    @params.to_json(*a)
  end

  def self.from_json(string)
    params = JSON.parse(string)
    self.new(params)
  end

  def method_missing(name)
    @params[name]
  end

  def parameters
    @params
  end

  private
  def add_row(html, row)
    "#{html}<tr>#{row}</tr>"
  end

  def array_to_td(array, td="td")
    html = "<#{td}>"
    label = row_labels.nil? ? false : true
    html += array.map do |a|
      if td == "td" and a.nil?
        @answer_number += 1
        "<input type=\"text\" name=\"answers[#{@answer_number}]\" />"
      elsif td == "td" and !label
        # do not wrap labels in span
        "<span>#{a}</span>"
      else
        # after the first label, wrap in span
        label = false
        a
      end
    end.join("</#{td}><#{td}>")
    html += "</#{td}>"
    html
  end
end
