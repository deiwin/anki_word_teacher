require 'htmlentities'

module StringUtils
  @@htmle = HTMLEntities.new

  class Canonizer
    def self.form_of(w)
      (w =~ /(((alternative)|(plural)|(tense)|(participle)|(variant)|(manner)|(characteristic)|(spelling))[^.;]*of)/i) &&
      StringUtils.cleanup($')
    end 

    def self.a_something(w)
      (w =~ /^a\s([\w\-]+)[.;]/i) && StringUtils.cleanup($1)
    end 

    def self.in_manner(w)
      (w =~ /in.*?\s([\w\-]+)\smanner/i) && StringUtils.cleanup($1)
    end 

    def self.trait(w)
      (w =~ /a(?:n)?.*?\s([\w\-]+)\s(?:(?:trait)|(?:mannerism))/i) && StringUtils.cleanup($1)
    end 

    def self.cond(w)
      (w =~ /(?:condition)|(?:state)\sof\sbeing\s([\w\-]+)/i) && StringUtils.cleanup($1)
    end 

    def self.one(w)
      (w =~ /one\swho(?:\shas)?\s([\w\-]+)/i) && StringUtils.cleanup($1)
    end 
  end 

  def self.getCanonicalForm(w)
    (can = Canonizer.form_of(w) || Canonizer.a_something(w) || Canonizer.in_manner(w) || Canonizer.trait(w) || Canonizer.cond(w) || Canonizer.one(w)) && !can.empty? && can
  end 

  def self.cleanup(s)
    @@htmle.decode(s).downcase.strip.gsub(/([,.:"“”()!?;])|(^')|(^‘)/, '').gsub(/(’$)|('$)/, '') 
  end 

end

