##
# Author:     ASHWIN RAMESH
# Copyright:  This file is created by Ashwin Ramesh for a test conducted by Carnegie Technologies, Canada for a coding
#             challenge multi-get at source http://dist.pravala.com/coding/CarnegieCodingCheckMultiGet.pdf. This file
#             cannot be shared or copied for commercial use. This file can be used as a reference.
#
# Description: This file can be used to download part of a file in chunks using the Net::HTTP Range header. Help is
#              provided by the -h or -help argument passed through command line.
#

# Requiring the standard libraries
require 'optparse'
require 'net/http'

# Initializing all the required parameters
options = {}
chunk_size = 1
file_size = 4
source_uri = ""
partial_content = ""
sample_uri = "http://f39bf6aa.bwtest-aws.pravala.com/384MB.jar"

# Initializing the Options parser for command line options
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: This file can be used to download part of a file in chunks using the Net::HTTP Range header.
       Help is provided by the -h or -help argument passed through command line.
       #{$0} -u URI -c CHUNK -s FILESIZE -n FILENAME ...\n\n"

  opts.on("-u", "--uri URI", "[REQUIRED] Source URI to download (Example: #{sample_uri}) ") do |u|
    options[:source] = u
  end

  opts.on("-c", "--chunk CHUNK", "Chunk size to download in MiB (Example: 2 | Default: 1 MiB) ") do |c|
    options[:chunk] = c
  end

  opts.on("-s", "--filesize FILESIZE", "Total file size to download in MiB (Example: 4 | Default: 4 MiB) ") do |s|
    options[:filesize] = s
  end

  opts.on("-n", "--filename FILENAME", "Name of the File (Example: File.jar | Default: Source file name) ") do |n|
    options[:filename] = n
  end

  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end
end

optparse.parse!

# Checking Option Parser for source URL, Mandating -s, --source
if options[:source].nil?
  abort(optparse.help)
end

source_uri = options[:source]
uri = URI(source_uri)
chunk_size = (options[:chunk].to_i) if options[:chunk]
file_size = (options[:filesize].to_i) if options[:filesize]
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri.path)

start_byte = 0
chunk_converted = chunk_size * 1024 * 1024
end_byte = chunk_converted
count = file_size / chunk_size
file_size_converted = file_size * 1024 * 1024
response_header = http.request_head(uri)
actual_file_size = response_header['content-length'].to_i

if file_size_converted >= actual_file_size
  file_size_converted = actual_file_size
  puts (" Actual file size on server is: #{actual_file_size} MiB")
end

puts (" Source URI provided by the user is: #{source_uri}
 Chunk size provided by the user is: #{chunk_size} MiB
 File size provided by the user is: #{file_size} MiB")

count.times do |n|
  if start_byte < end_byte
    puts ("\n Fetching chunk #{n + 1} using range #{start_byte} - #{end_byte}")
    request['Range'] = "bytes=#{start_byte}-#{end_byte}"
    response = http.request(request)
    partial_content << response.body
    puts (" Total file size downloaded : #{partial_content.length} bytes")
    start_byte = end_byte + 1
    end_byte = start_byte + chunk_converted
    if end_byte >= file_size_converted
      end_byte = file_size_converted
    end
  end
end

# Write out to a file
file_name = options[:filename] ? options[:filename] : File.basename(source_uri)
open(file_name, "wb") do |fout|
  fout.write partial_content
  puts ("\n Output file is available in #{Dir.pwd + "/" + file_name} with size: #{fout.size}")
end