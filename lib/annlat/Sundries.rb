def final?
  instance_methods(false).include? :showHow
end

public :final?

class Fixnum
  def prettify
    self
  end
end

class Float
  def prettify
    to_i == self ? to_i : self
  end
end

class Rational
  def prettify
    if self.denominator==1
      self.numerator 
    else
      self
    end
  end
end

class Concept

  attr_accessor :images
  attr_accessor :uuid


  def move_image(img)
      uuid=img.uuid
      path=img.path
      if !img.options[:dynamic]
        begin
          FileUtils.mv("engine/concepts/#{path}", "public/images/#{self.class}/static/#{path}")
        rescue Errno::ENOENT
        end
        img.path = "#{self.class}/static/#{path}"
      else
        img.path= "#{self.class}/#{uuid}"
        FileUtils.mv("#{path}", "public/images/#{self.class}/#{uuid}")
      end    
      img
  end

  def move_images
    concept=self
    @images=[] if @images.nil?
    begin
      Dir.mkdir("public/images/#{self.class}")
    rescue Errno::EEXIST
    end
    begin
      Dir.mkdir("public/images/#{self.class}/static")
    rescue Errno::EEXIST
    end
    @images.map {|x| move_image(x)}
  end

  def addImage(img)
    @images=[] if @images.nil?
    raise "You tried to add not an image" if img.class!=Image
    @images << img
  end


end
