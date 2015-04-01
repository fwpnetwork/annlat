class Concept

  attr_accessor :images
  attr_accessor :uuid

  def move_image(img)
    ext = File.extname(img.path)
    if !img.options[:dynamic]
      begin
        FileUtils.mv("engine/concepts/#{img.path}", "public/images/#{self.class}/static/#{img.path}")
      rescue Errno::ENOENT
      end
      img.path = "#{self.class}/static/#{img.path}"
    else
      FileUtils.mv("#{img.path}", "public/images/#{self.class}/#{img.uuid}#{ext}")
      img.path= "#{self.class}/#{img.uuid}#{ext}"
    end
    img
  end

  def move_images
    @images=[] if @images.nil?
    begin
      Dir.mkdir("public/images/#{self.class}")
    rescue Errno::EEXIST
    end
    begin
      Dir.mkdir("public/images/#{self.class}/static")
    rescue Errno::EEXIST
    end
    @subconcepts.each{|sc| sc.move_images} if @subconcepts
    @images.map {|x| move_image(x)}
  end

  def addImage(img)
    @images=[] if @images.nil?
    raise "You tried to add not an image" unless  img.class <= Image
    @images << img
  end

  alias_method :add_image, :addImage

  def add_subconcept(subconcept)
    @subconcepts ||= []
    @subconcepts << subconcept
  end

  def mastery=(m)
    @mastery = m
  end

  def mastery
    @mastery.nil? ? 0 : @mastery
  end

end

