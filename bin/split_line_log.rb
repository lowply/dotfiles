#!/usr/bin/env ruby

require 'date'

def usage
  abort "Usage: \n    env SPLIT_LINE_LOG_DIR=\"/path/to/dir\" #{$PROGRAM_NAME} line_export_file.txt"
end

usage if ENV["SPLIT_LINE_LOG_DIR"].nil?
usage if ARGV.length != 1

class Message
  # Trailing slash adjustment
  @@filedir = File.join(ENV["SPLIT_LINE_LOG_DIR"], "")

  def initialize(match)
    @date = Date.parse("#{match[1]}-#{match[2]}-#{match[3]}")
    @content = @date.strftime("%Y/%m/%d %a") + "\n\n"
    @fullpath = @date.strftime("%Y") + "/" + @date.strftime("%m") + "/" + @date.strftime("%d") + ".txt"
    create_directories
  end

  def create_directories
    year = @@filedir + "/" + @date.strftime("%Y")
    month = year + "/" + @date.strftime("%m")
    Dir.mkdir(year, 0755) if !Dir.exist?(year)
    Dir.mkdir(month, 0755) if !Dir.exist?(month)
  end

  def add(text)
    @content = @content + text
  end

  def read_last_file(dir)
    Dir.chdir(dir)
    files = Dir.glob("*.txt")
    return dir + files.last if ! files.empty?
  end

  def content
    return @content
  end

  def write_to_file
    last_updated = read_last_file(@@filedir)
    if ! File.exist?(@fullpath) || (@fullpath == last_updated)
      #
      # Write to a file only when there's no file yet or it's the latest file
      #
      File.open(@fullpath, "w") do |f|
        f.puts @content
      end
      puts "File created at: " + @fullpath
    end
  end
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
  abort "\"#{ENV["SPLIT_LINE_LOG_DIR"]}\" does not exitst."  if ! Dir.exist?(ENV["SPLIT_LINE_LOG_DIR"])
  abort "\"#{ARGV[0]}\" does not exitst." if ! File.exist?(ARGV[0])
  messages = create_messages(ARGV[0])
  messages.each do |m|
    m.write_to_file
  end
end

main
