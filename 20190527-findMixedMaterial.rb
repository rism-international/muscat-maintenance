class Mix
  def initialize
    @res = []
  end
  def findMix
    pp "Procedure initiated"
    Source.all.each do |s|
      pp "Source: #{s.id}"
      marc = MarcSource.new(s.marc_source).by_tags("=593")
      if not marc.combination(2).all? {|x,y| x.children[0].to_s == y.children[0].to_s}
        @res << s.id
        pp "Source contains mixed material: #{s.id}"
      end
    end
  end
  def getRes
    return @res
  end
end
#a = MarcSource.new(Source.first.marc_source).by_tags("=593")
#a.combination(2).any? {|x,y| pp x.children[0].to_s == y.children[0].to_s}
