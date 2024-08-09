require 'nokogiri'
require 'fileutils'

## Update XMLs
def update_config(file_path)
  doc = Nokogiri::XML(File.read(file_path)) { |config| config.default_xml.noblanks }

  ## Disable all Jenkins jobs
  disabled = doc.at_xpath('//disabled')
  if disabled
    disabled.content = 'true'
  else
    project = doc.at_xpath('//project')
    if project
      project.add_chile(Nokogiri::XML::Node.new('disabled', doc).tap {|node| node.content = 'true'})
    end
  end

  ## Check if log rotation is set.
  unless doc.at_xpath('//jenkins.model.BuildDiscarderProperty')
    build_discarder = Nokogiri::XML::Node.new('jenkins.model.BuildDiscarderProperty', doc)
    strategy = Nokogiri::XML::Node.new('strategy', doc)
    strategy['class'] = 'hudson.tasks.LogRotator'

    days_to_keep = Nokogiri::XML::Node.new('daysToKeep', doc)
    days_to_keep.content = '-1'
    num_to_keep = Nokogiri::XML::Node.new('numToKeep', doc)
    num_to_keep.content = '30'
    artifact_days_to_keep = Nokogiri::XML::Node.new('artifactDaysToKeep', doc)
    artifact_days_to_keep.content = '-1'
    artifact_num_to_keep = Nokogiri::XML::Node.new('artificatNumToKeep', doc)
    artifact_num_to_keep.content = '-1'

    strategy.add_child(days_to_keep)
    strategy.add_child(num_to_keep)
    strategy.add_child(artifact_days_to_keep)
    strategy.add_child(artifact_num_to_keep)
    build_discarder.add_child(strategy)

    doc.root.add_child(build_discarder)
  end
  ## Write all changes back to XML
  File.write(file_path, doc.to_xml(indent: 2))
end

## Find XML paths
def scan_directory(directory)
  Dir.glob("#{directory}/**/config.xml").each do |file_path|
    update_config_xml(file_path)
  end
end

## CHECK IT
directory = ARGV[0]
if directory.nil? || !Dir.exist?(directory)
  puts "Please provide a job directory"
  exit 1
end

## DO IT
scan_directory(directory)
puts "All jobs have been updated."
