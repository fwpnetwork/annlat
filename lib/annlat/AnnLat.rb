# The class AnnLat, short for AnnotatedLatex, allows a concept to create 
# step-by-step solutions with text, latex, hints, more hints, and embedded prerequisite concepts. 
# It also allows for the creation of questions with text, latex, hints, and suggestions.
# The communication between the engine and the concepts is faciliated by AnnLat 
# by the agreement that all communication from a concept back to the engine that is intended
# to be displayed to the user is an AnnLat object.

# An instance object maintains an array of objects to be presented on the screen together
# with an array indicating the type of each object. The engine can then access both arrays 
# and decide how to encode each object, and which ones to present on the screen.
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

class AnnLat #just the scafolds, the idea is to implement this so it will support the example concepts

  attr_accessor :objects, :tags
  attr_reader :options

  def options=(opt)
    @options.unshift(opt)
  end

  def initialize(objects=[], tags=[], options=[])
    @objects = objects
    @tags = tags
    @options = options
  end

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
    case options
      when Hash
        if objs.empty?                # It's the case when you only pass a hash
          objects << options[:object] # then it's definitely just one object (in form of hash) to be added
          tags << get_type(options[:object])
          option_arr << options[:options] || {}
          opts[:sentence_options] = {}
        else
          opts[:sentence_options] = options
        end
      else
        opts[:sentence_options] = {}
        objs.unshift(options)
    end
    objs.each do |object|
      case object
        when Hash
          objects << object[:object]
          tags << get_type(object[:object])
          option_arr << object[:options]
        when Array
          add(options, *object)
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
            '\(' + obj + '\)'
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

end
