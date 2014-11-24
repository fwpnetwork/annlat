
public

def my_json
  to_s
end

def get_type(thing)
  if thing.class.ancestors.include? Concept
    :Concept
  elsif thing.class.ancestors.include? Latex
    :Latex
  elsif thing.class.ancestors.include? AnnLat
    :AnnLat
  else
    thing.class.to_s.to_sym
  end
end

##
# The class AnnLat, short for AnnotatedLatex allows a concept to create step-by-step solutions
# with text, latex, hints, images, and embedded prerequisite concepts (not yet).
#
# That gem is used both at the developer-side and server-side, however usage in the latter is increasingly small.
#
# An instance off AnnLat objects is described by three arrays:
# objects, tags (in future it would be possibly renamed to types) and options.
class AnnLat

  attr_accessor :objects, :tags
  attr_writer :options

  def ==(x)
    return false unless x.class AnnLat
    @objects==x.objects and @tags==x.tags and @options==x.options
  end

  def initialize(objects=[], tags=[], options=[])
    @objects = objects
    @tags = tags
    @options = options
  end

  ##
  # Works just as with arrays, can be provided both with range or just integer.
  def [](range)
    if range.class == Range
      AnnLat.new(@objects[range],@tags[range], @options[range])
    else
      AnnLat.new([@objects[range]],[@tags[range]],[@options[range]])
    end
  end


  def +(x)
    AnnLat.new(@objects + x.objects, @tags + x.tags, @options + x.options)
  end

  def self.empty
    new([],[],[])
  end

  def empty?
    @objects.length==0
  end

  ##
  # Adds arbitrary amount of objects to AnnLat object
  # If you want to provide the whole AnnLat object with options hash
  # it should be the first argument, if you want to provide options
  # for just one object you're going to add wrap it in hash of this form
  # {:object => your_object, :options => {tag: :font, color: 'blue', ...}}
  def add(options, *objs)
    opts = {}
    objects, tags, option_arr = [], [], []
    if objs.empty? or options.class != Hash or options.has_key?(:object)
      opts[:sentence_options] = {}
      objs.unshift(options)
    else
      opts[:sentence_options] = options
    end
    objs.flatten.each do |object|
      case object
        when Hash
          objects << object[:object]
          tags << get_type(object[:object])
          option_arr << object[:options]

        else
          objects << object
          tags << get_type(object)
          option_arr << {}
      end
    end
    opts[:option_array] = option_arr
    @objects << objects
    @tags << tags
    @options << opts
    self
  end

  def add_hint(opts = {}, *objs)
    case opts
      when Hash
        opts[:hint] = true
        add(opts, *objs)
      else
        add({hint: true}, *objs.unshift(opts))
    end
  end

  alias_method :addHint, :add_hint

  def filter_by_option
    raise 'No block given' unless block_given?
    output = []
    @options.each_with_index do |option_hash, i|
      output << self[i] if yield(option_hash[:sentence_options])
    end
    output.inject(:+) || AnnLat.empty
  end

  def hints
    filter_by_option{|option| option[:hint]}
  end

  def not_hints
    filter_by_option{|option| not option[:hint]}
  end

  def multiple
    filter_by_option{|option| option[:multiple]}
  end

  def not_multiple
    filter_by_option{|option| not option[:multiple]}
  end

  def my_json
    obs, tags =[], []
    @objects.each_with_index do |array, external_index|
      arr, tags_arr =[], []
      array.each_with_index do |object, index|
        tag = @tags[external_index][index]
        arr << object.my_json
        tags_arr << tag
      end
      obs << arr unless arr == []
      tags << tags_arr unless arr == []
    end
    {objects: obs, tags: tags, options: @options}
  end

  ##
  # Used at the server side only

  def to_html
    objects = @objects.each_with_index.map do |arr, external_index |
      arr.each_with_index.map do |obj, index|
        tag = @tags[external_index][index]
        case tag
          when 'String', 'Image'
            obj
          when 'Latex'
            ' \(' + obj + '\) '
          else
            obj.to_s
        end
      end
    end
    AnnLat.new(objects, @tags, @options)
  end

  def self.wrap(hash)
      hash[:objects] ? new(hash[:objects], hash[:tags], hash[:options]) : empty
    end

  def to_hash
    {objects: @objects, tags: @tags, options: @options}
  end

  ##
  # This method it used for back-compatibility it will be removed once all concept at
  # the working platform would be updated to use new API
  def update
    return self if @options.empty?
    if @options[0].has_key?(:multiple_answer)
      @options[-1][:sentence_options] = {:multiple => true}
      @options.shift
    end
    self
  end

end
