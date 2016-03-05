require 'double_bag_ftps'
require 'net/ftp/list'
require 'pp'

def each_file(host, user, password, path='.', pattern = '*')

  ftps = DoubleBagFTPS.new
  ftps.ssl_context = DoubleBagFTPS.create_ssl_context(:verify_mode => OpenSSL::SSL::VERIFY_NONE)
  ftps.passive = true
  ftps.connect(host)
  puts ">>> conectado, log as #{user}"
  ftps.login(user, password)
  puts ">>> logged"
  ftps.chdir(path)
  list = ftps.list
  puts ">>> listed #{list.size} items"
  list.each do |e|
    entry = Net::FTP::List.parse(e)
    next unless entry.file?
    next unless File.fnmatch?(pattern, entry.basename)
    yield entry, ftps
  end
  ftps.close
end

 
pp ARGV.join(', ')
out_dir = ARGV.shift
each_file(*ARGV) do |e, ftps|
  puts ">>> #{e}"
  out_path = File.join(out_dir, e.basename)
  temp_path = out_path + '.part'
  ftps.getbinaryfile(e.basename, temp_path)
  File.rename(temp_path, out_path)
  ftps.delete(e.basename)
end
