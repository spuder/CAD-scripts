#!/usr/bin/env ruby

require 'yaml'
require 'erb' #https://stackoverflow.com/a/25626629/1626687
include ERB::Util

raise "templates/settings.yaml does not exist, could not load settings" unless File.exists?("templates/settings.yaml")
settings = YAML.load_file('templates/settings.yaml')

# Loop through all files ending in .erb in the templates directory
Dir.glob("templates/*.erb").each do |file|
  # Get the filename without the .erb extension
  filename = File.basename(file, ".erb")
  # Load the file and render it with ERB
    template = ERB.new(File.read(file), nil, '-')
  # Write the rendered file to the output directory
  File.open("#{filename}", 'w') { |f| f.write(template.result(binding)) }
end
