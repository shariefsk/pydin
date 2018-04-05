#!/usr/bin/env ruby

# PYDIN (PythonDependencyINstaller)
#
# A ruby tool to install python dependencies. 
# Just does `pip install -requirements.txt` in ruby style with some verbose and control
# 
# Usage
# ==========
# ruby pydin.rb requirements.json
#

require 'json' #json is in stdlib

Signal.trap("INT") do
	shut_down
end

Signal.trap("TERM") do
  shut_down
end

def shut_down
  puts "\nExiting installation gracefully. Bye!"
	sleep 1
	exit
end

if ARGV.length < 1
  abort "Please provide dependencies json file as argument 1"
end

if File.extname(ARGV[0]) != '.json'
	abort "Invalid file format. Require .json"
end

begin
	file = File.read(ARGV[0])
rescue Errno::ENOENT
	abort "File `#{ARGV[0]}` doesn't exist!" 
end

begin
	data = JSON.parse(file)
	dependencies = data["dependencies"] 
rescue JSON::ParserError
	abort "Invalid JSON"
end

abort("Missing dependencies") if dependencies.nil? 

begin
	pythons = []
	IO.popen("ruby -e 'exec(\"which python python3\")'").each do |line|
		pythons << line.chomp
	end 
rescue Exception
end

abort "`Python` installation not found. Please install `python` to continue." if pythons.size == 0

begin
	pips = []
	IO.popen("ruby -e 'exec(\"which pip pip3\")'").each do |line|
		pips << line.chomp
	end 
rescue Exception
end

abort "`Pip` installation not found. Please install `pip` to continue." if pips.size == 0

which_pip = nil
if pips.size > 1
	puts "Multiple pip versions found. Please choose one to continue. Or press enter for default."
	pips.each_with_index do |p, index|
		puts "#{index+1}. #{p.split("/").last}"
	end

	option = $stdin.gets.chomp

	which_pip = pips[option.to_i-1] if (option.to_i - 1) <= pips.size
	which_pip = which_pip.split("/").last if which_pip
end

which_pip = pips.first.split("/").last unless which_pip

puts "Using pip version: #{which_pip}"

puts "Do you want to run as sudo? [Y/n]"

option = $stdin.gets.chomp

sudo = ["n","N"].include?(option) ? "" : "sudo "

puts "Using command format `#{sudo}#{which_pip} install <DEPENDENCY==VERSION>`\n"

success_dependencies = []
failed_dependencies = []
dependencies.each do |dependency|
	begin
		print "Installing `#{dependency}`"
		
		system("#{sudo} #{which_pip} install #{dependency} > /dev/null 2>&1")
		if $? == 0
			puts " ===> [Success]"
			success_dependencies << dependency
		else
			puts " ===> [Failure]"
			failed_dependencies << dependency
		end
	rescue SystemExit
		puts "Rescued a SystemExit Exception"
	end
	sleep 3
end

if failed_dependencies.size != 0
	puts  "\nFailed to install following dependencies"
	puts  "---------------------------------------"
	failed_dependencies.each do |d|
		puts d
	end
else
	puts "\nAll dependencies installed successfully"
end

