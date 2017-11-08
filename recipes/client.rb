#
# Cookbook Name:: b1
# Recipe:: client
#

Chef::Log.info "include seven_zip"
include_recipe "seven_zip"

####################################################################################################
#  --- VARIABLES ---
#
v_archiverepo           = node['b1h']['archiverepo']
v_is_multispan_archive  = node['b1h']['is_multispan_archive']
v_archivename           = node['b1h']['archive']
v_multispan_archives    = node['b1h']['multispan_archives']
v_archive               = node['b1h']['archive']

v_installerfolderbase   = node['b1h']['installerfolder']

v_licenseserver         = node['b1hclient']['licenseserver']
v_licenseserverip       = node['b1hclient']['licenseserverip']

v_dbversion             = node['b1hclient']['dbversion']
v_branch                = node['b1hclient']['branch']
v_patch                 = node['b1hclient']['patch']
v_platform              = node['b1hclient']['platform']
v_changelog             = node['b1hclient']['changelog']

v_plnumber              = v_patch.sub(/_HF[[:digit:]]/, '').sub(/_CL_[[:digit:]]{7}/, '') # Get patch number without HF
v_mv                    = v_dbversion.to_s[0..1]
v_dbversion_part1       = v_dbversion.to_s[0..2]
v_dbversion_part2       = v_dbversion.to_s[3..5]


if v_plnumber.to_i < 10
  # Leading zero
  v_patch_leadingzero = "0#{v_patch}"
  v_plnumber_leadingzero = "0#{v_plnumber}"
else
  v_patch_leadingzero = v_patch
  v_plnumber_leadingzero = v_plnumber
end
  
if(v_archiverepo == nil)
  if v_branch.downcase == "smp"
    v_archiverepo = node['b1h']['patchrepo']
  elsif v_branch.downcase == "rel"
    v_archiverepo = node['b1h']['relproductcdrepo']
  else
    raise "Unsupported B1 Branch."
  end
end

if !v_is_multispan_archive
  if v_archive == nil
    if v_branch.downcase == "smp"
      v_archivename = "B1H#{v_mv}_PL#{v_patch_leadingzero}"
      v_archiveextension        = "zip"
    elsif v_branch.downcase == "rel"
      v_archivename = "Product_#{v_dbversion_part1}.#{v_dbversion_part2}.#{v_plnumber_leadingzero}_CD_#{v_changelog}_HANA" # Archive name does not include any HF# 
      v_archiveextension = "rar"
    else
      raise "Unsupported B1 Branch."
    end
  else
      v_archivename = v_archive.rpartition(".").first 
      v_archiveextension = v_archive.rpartition(".").last
  end
end

if !v_is_multispan_archive
  v_installerfolderextracted = "#{v_installerfolderbase}\\#{v_archivename}"
else
  v_multispan_first_archive = v_multispan_archives[0]
  v_multispan_first_archivename = v_multispan_first_archive.split(".").first
  v_installerfolderextracted = "#{v_installerfolderbase}\\#{v_multispan_first_archivename}"
end

v_platformName          = v_platform == "x86" ? 32 : 64
v_programfiles          = v_platform == "x86" ? node['b1hclient']['programfiles'] : node['b1hclient']['programfiles64']

if v_platform == "x86"
  v_setupExePath = "#{v_installerfolderbase}\\#{v_archivename}\\Packages\\Client\\setup.exe"
  v_setupIssPath = "#{v_installerfolderbase}\\#{v_archivename}\\Packages\\Client\\setup.iss"
else
  v_setupExePath = "#{v_installerfolderbase}\\#{v_archivename}\\Packages.x64\\Client\\setup.exe"
  v_setupIssPath = "#{v_installerfolderbase}\\#{v_archivename}\\Packages.x64\\Client\\setup.iss"
end

v_remotefile            = "#{v_archiverepo}/#{v_archivename}.#{v_archiveextension}"
#
#  --- END VARIABLES ---
####################################################################################################


Chef::Log.info "Variable v_archiverepo: #{v_archiverepo}"
Chef::Log.info "Variable v_licenseserver: #{v_licenseserver}"
Chef::Log.info "Variable v_licenseserverip: #{v_licenseserverip}"
Chef::Log.info "Variable v_dbversion: #{v_dbversion}"
Chef::Log.info "Variable v_branch: #{v_branch}"
Chef::Log.info "Variable v_patch: #{v_patch}"
Chef::Log.info "Variable v_changelog: #{v_changelog}"

Chef::Log.info "Variable v_installerfolderbase: #{v_installerfolderbase}"
Chef::Log.info "Variable v_setupExePath: #{v_setupExePath}"
Chef::Log.info "Variable v_setupIssPath: #{v_setupIssPath}"
Chef::Log.info "Variable v_programfiles: #{v_programfiles}"

Chef::Log.info "Variable v_is_multispan_archive: #{ v_is_multispan_archive }"
Chef::Log.info "Variable v_multispan_first_archive: #{ v_multispan_first_archive }"
Chef::Log.info "Variable v_multispan_first_archivename: #{ v_multispan_first_archivename }"

Chef::Log.info "Variable v_archivename: #{v_archivename}"
Chef::Log.info "Variable v_archiveextension: #{v_archiveextension}"
Chef::Log.info "Variable v_remotefile: #{v_remotefile}"


directory "#{v_installerfolderbase}" do
  action :create
  recursive true
end

if !v_is_multispan_archive
  remote_file 'Copy Patch Archive' do
    path "#{v_installerfolderbase}\\#{v_archivename}.#{v_archiveextension}"
    source "#{v_archiverepo}/#{v_archivename}.#{v_archiveextension}"
    action :create_if_missing
    not_if { ::File.exists?("#{v_installerfolderextracted}\\UNZIP_COMPLETE")}
  end
else
  v_multispan_archives.each do |file|
    remote_file 'Copy Patch Archive' do
      path "#{v_installerfolderbase}\\#{file}"
      source "#{v_archiverepo}/#{file}"
      action :create_if_missing
      not_if { ::File.exists?("#{v_installerfolderextracted}\\UNZIP_COMPLETE")}
    end
  end
end

if !v_is_multispan_archive
  batch 'unzip_installer' do
    code <<-EOH
      7z.exe x #{v_installerfolderbase}\\#{v_archivename}.#{v_archiveextension}  -o#{v_installerfolderextracted} -r -y
    EOH
    not_if { ::File.exists?("#{v_installerfolderextracted}\\UNZIP_COMPLETE")}
  end
else
  batch 'unzip_installer' do
    code <<-EOH
      7z.exe x #{v_installerfolderbase}\\#{v_multispan_first_archive}  -o#{v_installerfolderextracted} -r -y
    EOH
    not_if { ::File.exists?("#{v_installerfolderextracted}\\UNZIP_COMPLETE")}
  end
end

batch 'record unzip complete' do
  cwd "#{v_installerfolderbase}\\#{v_archivename}"
  code <<-EOH
    echo > UNZIP_COMPLETE
    EOH
end

if !v_is_multispan_archive
  batch 'delete installer zip' do
    code <<-EOH
    del "#{v_installerfolderbase}\\#{v_archivename}.#{v_archiveextension}"
    EOH
    only_if { ::File.exists?("#{v_installerfolderbase}\\#{v_archivename}.#{v_archiveextension}")}
  end
else
  v_multispan_archives.each do |file|
    batch 'delete installer zip' do
      code <<-EOH
      del "#{v_installerfolderbase}\\#{file}"
      EOH
      only_if { ::File.exists?("#{v_installerfolderbase}\\#{file}")}
    end
  end
end

Chef::Log.info "Create setup.iss"
template 'setup.iss' do
  path "#{v_setupIssPath}"
  source "setup.iss.erb"
  action :create
end

Chef::Log.info "Install B1 Client"
if v_licenseserver.to_s.strip.empty?
  v_installerZOptions = "/z\"#{v_programfiles}\\SAP\\SAP Business One\""
else
  v_installerZOptions = "/z\"#{v_programfiles}\\SAP\\SAP Business One*#{v_licenseserver}:40000\""
end

# %W[...] is rudy for making an array. Using this method of passing options so that #{v_licenseserver} gets evaluated correctly
#
windows_package 'B1H Client' do
  package_name "SAP Business One Client (#{v_platformName}-bit)"
  source "#{v_setupExePath}"
  #options '/s /z"C:\Program Files (x86)\SAP\SAP Business One*#{v_licenseserver}:40000"'
  options %W[
            /s
            #{v_installerZOptions}
            ].join(' ')

  timeout 2700
  action :install
end

Chef::Log.info "Update b1-local-machine.xml with licenseserver address"

if !v_licenseserver.to_s.strip.empty?

  #Replace "C:\Program Files (x86)\SAP\SAP Business One\Conf\b1-local-machine.xml"
  template 'b1-local-machine.xml' do
     path "#{v_programfiles}\\SAP\\SAP Business One\\Conf\\b1-local-machine.xml"
     source "b1-local-machine.xml.erb"
    variables(
      :v_licenseserver => node[:b1hclient][:licenseserver],
      :v_licenseserverip => node[:b1hclient][:v_licenseserverip]
    )
    action :create
  end

  #Replace "C:\Program Files (x86)\SAP\SAP Business One DI API\Conf\b1-local-machine.xml"
  template 'b1-local-machine.xml' do
      path "#{v_programfiles}\\SAP\\SAP Business One DI API\\Conf\\b1-local-machine.xml"
      source "b1-local-machine.xml.erb"
      variables(
      :v_licenseserver => node[:b1hclient][:licenseserver],
      :v_licenseserverip => node[:b1hclient][:v_licenseserverip]
    )
    action :create
  end
  
end

