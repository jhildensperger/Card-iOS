project_name = File.basename(Dir.pwd)
$pbxproj_sort_path = './Scripts/pbxproj-sort.pl'
$install_charles_path = './Scripts/install-charles-cert-for-iphone-simulator.sh'

def system_or_exit(cmd, stdout = nil)
  puts "Executing #{cmd}"
  cmd += " >#{stdout}" if stdout
  system(cmd) or raise "******** Build failed ********"
end

task :default => [:trim_whitespace, :sort_pbxproj]

task :trim_whitespace do
  system_or_exit(%Q[git status --short | awk '{if ($1 != "D" && $1 != "R") print $2}' | grep -e '.*\.[mh]$' | xargs sed -i '' -e 's/  /    /g;s/ *$//g;'])
end

task :sort_pbxproj do  
  download_pbxproj_sort_if_neccesary
  system_or_exit("#{$pbxproj_sort_path} #{project_name}.xcodeproj/project.pbxproj")
end

# Install Charles certs for iOS simulator

task :install_charles do
  download_charles_certs_if_neccesary
  system_or_exit("#{$install_charles_path}")
end

# Pony Debugger

task :start_pony do
  download_pony_if_neccesary
  machine_ip = `ipconfig getifaddr en0`.gsub(/\s+/, "")
  start_pony_cmd = "ponyd serve --listen-interface=#{machine_ip}"
  pony_web_url = "http://#{machine_ip}:9000"
  system_or_exit(`open #{pony_web_url} | #{start_pony_cmd}`)
end

def make_scripts_directory_if_neccesary
  if !File.directory?("./Scripts")
   Dir.mkdir("./Scripts", 0777)
 end
end

def download_charles_certs_if_neccesary
  make_scripts_directory_if_neccesary
  if !File.exists?($install_charles_path)
    system_or_exit("curl https://gist.githubusercontent.com/jhildensperger/d74288ca9a9db03ccfea/raw/4a99269e5fd54e6d7de45f89ff3e26e6c32d19ce/install-charles-cert-for-iphone-simulator.sh -o #{$install_charles_path} && chmod 755 #{$install_charles_path}")
  end
end

def download_pbxproj_sort_if_neccesary
  make_scripts_directory_if_neccesary
  if !File.exists?($pbxproj_sort_path)
    system_or_exit("curl https://gist.githubusercontent.com/jhildensperger/28e82bb711f69f2e3b05/raw/ac26e824a8a8344ad30c3ee9440892d7fd88577b/pbxproj-sort.pl -o #{$pbxproj_sort_path}")
  end
end

def download_pony_if_neccesary
  system_or_exit("curl -sk https://cloud.github.com/downloads/square/PonyDebugger/bootstrap-ponyd.py | python - --ponyd-symlink=/usr/local/bin/ponyd ~/Library/PonyDebugger")
end