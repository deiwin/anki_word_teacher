Gem::Specification.new do |s|
  s.name        = 'anki_word_teacher'
  s.version     = '0.0.1'
  s.date        = '2014-03-01'
  s.summary     = "Anki Word Teacher"
  s.description = "Teach yourself words with Anki!"
  s.authors     = ["Deiwin Sarjas"]
  s.email       = 'deiwin.sarjas@gmail.com'
  s.files       = Dir.glob("lib/**/*.rb")
  s.executables << 'anki_word_teacher_gui'
  s.homepage    = 'https://github.com/deiwin/anki_word_teacher'
  s.license     = 'MIT'
  s.add_runtime_dependency "wordnik", ["~>4.12"]
  s.add_runtime_dependency "evernote", [">=1.2.1", "~>1.2"]
  s.add_runtime_dependency "nokogiri", [">=1.6.1", "~>1.6"]
  s.add_runtime_dependency "htmlentities", [">=4.3.1", "~>4.3"]
  s.add_runtime_dependency "kindle_highlights", [">=0.0.8", "~>0.0"]
  s.add_development_dependency "rspec", [">=2.14.1", "~>2.14"]
end
