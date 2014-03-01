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
end
