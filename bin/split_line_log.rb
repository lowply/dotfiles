#!/usr/bin/env ruby

require 'date'

class Message
  # Trailing slash adjustment
  @@filedir = File.join(ENV["SPLIT_LINE_LOG_DIR"], "")

  def initialize(match)
    @date = Date.parse("#{match[1]}-#{match[2]}-#{match[3]}")
    @content = @date.strftime("%Y/%m/%d %a") + "\n\n"
    @path = @@filedir + @date.strftime("%Y_%m_%d") + ".txt"
  end

  def add(text)
    @content = @content + text
  end

  def write_to_file
    last_updated = read_last_file(@@filedir)
    if ! File.exist?(@path) || (@path == last_updated)
      #
      # Write to a file only when there's no file yet or it's the latest file
      #
      File.open(@path, "w") do |f|
        f.puts @content
      end
      puts "File created at: " + @path
    end
  end
end

def usage
  abort "Usage: \n    env SPLIT_LINE_LOG_DIR=\"/path/to/dir\" #{$PROGRAM_NAME} line_export_file.txt"
end

def read_last_file(dir)
  Dir.chdir(dir)
  files = Dir.glob("*.txt")
  return dir + files.last if ! files.empty?
end

def create_messages(src_file)
  messages = []
  File.open(src_file) do |file|
    reading = false
    text_date_regex = "^([0-9]{4})\/([0-9]{2})\/([0-9]{2}) ([A-Z][a-z]{2})$"
    file.each_line do |l|
      l = l.gsub("\r\n", "\n")
      if md = l.match(/#{text_date_regex}/)
        reading = true
        messages.push(Message.new(md))
      else
        messages.last.add(l) if reading
      end
    end
  end
  return messages
end

def main
  usage if ENV["SPLIT_LINE_LOG_DIR"].nil?
  usage if ARGV.length != 1
  src_file = ARGV[0]
  abort "\"#{src_file}\" does not exitst." if ! File.exist?(src_file)

  messages = create_messages(src_file)
  messages.each do |m|
    m.write_to_file
  end
end

main
