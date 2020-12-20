## cielli.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "cielli"
  spec.version = "4.2.4"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "cielli"
  spec.description = "description: cielli kicks the ass"
  spec.license = "Ruby"

  spec.files =
["README.md",
 "README.md.erb",
 "Rakefile",
 "bin",
 "bin/cielli",
 "cielli.gemspec",
 "lib",
 "lib/cielli",
 "lib/cielli.rb",
 "lib/cielli/_lib.rb",
 "lib/cielli/slug.rb",
 "lib/cielli/utils.rb",
 "samples",
 "samples/a.rb"]

  spec.executables = ["cielli"]
  
  spec.require_path = "lib"

  spec.test_files = nil

  

  spec.extensions.push(*[])

  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/cielli"
end
