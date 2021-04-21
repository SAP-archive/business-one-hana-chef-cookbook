#
# Cookbook Name:: b1h
# Recipe:: server
#

require "net/http"
require "uri"
require "json"

include_recipe "zypper"

####################################################################################################
#  --- VARIABLES ---
#
v_archiverepo           = node['b1h']['archiverepo']
v_is_multispan_archive  = node['b1h']['is_multispan_archive']
v_archivename           = node['b1h']['archive']
v_multispan_archives    = node['b1h']['multispan_archives']
v_archive               = node['b1h']['archive']

v_dbversion             = node[:b1h][:targetdbversion]
v_branch                = node[:b1h][:targetbranch]
v_patch                 = node[:b1h][:targetpatch]
v_changelog             = node[:b1h][:targetchangelog]
v_siteuserpassword      = node[:b1h][:siteuserpassword]
v_systempassword        = node[:b1h][:systempassword]
v_plnumber              = v_patch.sub(/_HF[[:digit:]]/, '').sub(/_CL_[[:digit:]]{7}/, '') # Get patch number without HF
v_mv                    = v_dbversion.to_s[0..1]
v_dbversion_part1       = v_dbversion.to_s[0..2]
v_dbversion_part2       = v_dbversion.to_s[3..5]
v_additional_repo       = node[:b1h][:additional_repo]

v_os_platform           = node['platform']
v_os_platform_version   = node['platform_version']


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
            v_archiveextension = "zip"
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
    v_installerlocalfolder = "/usr/sap/installers/#{v_archivename}"
else
    v_multispan_first_archive = v_multispan_archives[0]
    v_multispan_first_archivename = v_multispan_first_archive.split(".").first
    v_installerlocalfolder = "/usr/sap/installers/#{v_multispan_first_archivename}"
end

if v_dbversion.to_i >= 920003
    v_installerlocalsubfolder = "#{v_installerlocalfolder}/Packages.Linux/ServerComponents"
    v_installfilename = "install"
else
    v_installerlocalsubfolder = "#{v_installerlocalfolder}"
    v_installfilename = "install.bin"
end
#
#  --- END VARIABLES ---
####################################################################################################

Chef::Log.info "Variable v_additional_repo: #{ v_additional_repo }"

Chef::Log.info "Variable v_dbversion: #{ v_dbversion }"
Chef::Log.info "Variable v_branch: #{ v_branch }"
Chef::Log.info "Variable v_patch: #{ v_patch }"
Chef::Log.info "Variable v_siteuserpassword: #{ v_siteuserpassword }"
Chef::Log.info "Variable v_systempassword: #{ v_systempassword }"

Chef::Log.info "Variable v_is_multispan_archive: #{ v_is_multispan_archive }"
Chef::Log.info "Variable v_multispan_first_archive: #{ v_multispan_first_archive }"
Chef::Log.info "Variable v_multispan_first_archivename: #{ v_multispan_first_archivename }"

Chef::Log.info "Variable v_installerlocalfolder: #{ v_installerlocalfolder }"
Chef::Log.info "Variable v_installerlocalsubfolder: #{ v_installerlocalsubfolder }"
Chef::Log.info "Variable v_installfilename: #{ v_installfilename }"

Chef::Log.info "Variable v_os_platform: #{ v_os_platform }"
Chef::Log.info "Variable v_os_platform_version: #{ v_os_platform_version }"



if v_additional_repo != nil
  zypper_repository 'b1h-additional-repo' do
    baseurl v_additional_repo
    type 'rpm-md'
    autorefresh false 
    gpgcheck false
  end
end

execute "zypper refresh" do
    command "zypper --non-interactive --no-gpg-checks refresh"
end

directory "#{v_installerlocalfolder}" do
  owner "root"
  group "root"
  mode 0777
  recursive true
  not_if { ::File.exist?("#{v_installerlocalfolder}") }
end

# if copying source file uing chef remote_file resource, the staged file is saved to /tmp which may not have enough capacity. Use wget instead.
if !v_is_multispan_archive
  execute "Copy B1 Archive" do
    command "wget #{v_archiverepo}/#{v_archivename}.#{v_archiveextension} -O #{v_installerlocalfolder}/#{v_archivename}.#{v_archiveextension}"
    not_if { ::File.exists?("#{v_installerlocalfolder}/#{v_archivename}.#{v_archiveextension}") || ::File.exists?("#{v_installerlocalfolder}/UNZIP_COMPLETE")}
  end
else
  v_multispan_archives.each do |file|
    execute "Copy B1 Archive" do
      command "wget #{v_archiverepo}/#{file} -O #{v_installerlocalfolder}/#{file}"
      not_if { ::File.exists?("#{v_installerlocalfolder}/#{file}") || ::File.exists?("#{v_installerlocalfolder}/UNZIP_COMPLETE")}
    end
  end
end

bash 'set permissions of copied folder' do
  cwd ::File.dirname("#{v_installerlocalfolder}")
  code <<-EOH
    # ensure all files are owned by root
	sudo chown root -R .

	# assign all folders 755 or lower
	sudo find . -type d -print0 | xargs -0 chmod 0755

	# assign all files 644 or lower
	sudo find . -type f -print0 | xargs -0 chmod 0644
    EOH
  only_if { ::File.exists?("#{v_installerlocalfolder}") }
end

#additinal permissions due to 'b1service0' user change in HANA revision 97
bash 'set permissions of B1 log folder' do
  cwd ::File.dirname("/usr/sap/SAPBusinessOne/logs")
  code <<-EOH
    chmod -R 755 .
    EOH
  only_if { ::File.exists?("/usr/sap/SAPBusinessOne/logs") }
end

package 'p7zip' do
  action :install
end

if !v_is_multispan_archive
  bash 'Uncompress' do
    cwd "#{v_installerlocalfolder}"
    code <<-EOH
      7z x -y #{v_archivename}.#{v_archiveextension}
      EOH
    not_if {::File.exist?("#{v_installerlocalfolder}/UNZIP_COMPLETE")}
  end
else
  bash 'Uncompress' do
    cwd "#{v_installerlocalfolder}"
    code <<-EOH
      7z x -y #{v_multispan_first_archive}
      EOH
    not_if {::File.exist?("#{v_installerlocalfolder}/UNZIP_COMPLETE")}
  end
end

bash 'record unzip complete' do
  cwd "#{v_installerlocalfolder}"
  code <<-EOH
    echo > UNZIP_COMPLETE
  EOH
end

bash 'set permissions for extracted files' do
  cwd ::File.dirname("#{v_installerlocalfolder}")
  code <<-EOH
    # ensure all files are owned by root
	sudo chown root -R .

	# assign all folders 755 or lower
	sudo find . -type d -print0 | xargs -0 chmod 0755

	# assign all files 644 or lower
	sudo find . -type f -print0 | xargs -0 chmod 0644
    EOH
  only_if { ::File.exists?("#{v_installerlocalfolder}") }
end

if !v_is_multispan_archive
  bash 'delete compressed archive' do
    code <<-EOH
      rm -f "#{v_installerlocalfolder}\\#{v_archivename}.#{v_archiveextension}"
    EOH
    only_if { ::File.exists?("#{v_installerlocalfolder}\\#{v_archivename}.#{v_archiveextension}")}
  end
else
  v_multispan_archives.each do |file|
    bash 'delete compressed archive' do
      code <<-EOH
        rm -f "#{v_installerlocalfolder}\\#{file}"
      EOH
      only_if { ::File.exists?("#{v_installerlocalfolder}\\#{file}")}
    end
  end
end

# Add silent upgrade config file
# 'no-backupSer' versions used due to SAP Note 2697569 (https://sapjira.wdf.sap.corp/browse/B1TEC-1230)
# 'no-backupSer' versions used due to https://sapjira.wdf.sap.corp/browse/B1TEC-1233
if v_dbversion.to_i >= 930000 
  template "#{v_installerlocalsubfolder}/silentInstallConfig" do
    source "silentInstallConfig-[no-backupSer]-9.3PL0.erb"
    variables(
      :host => node['fqdn'],
      :v_siteuserpassword => v_siteuserpassword,
      :v_systempassword => v_systempassword,
      :v_installerlocalfolder => v_installerlocalfolder
    )
    mode 0777
  end
elsif v_dbversion.to_i >= 920003 
  template "#{v_installerlocalsubfolder}/silentInstallConfig" do
    source "silentInstallConfig-[no-backupSer]-9.2PL0.erb"
    variables(
      :host => node['fqdn'],
      :v_siteuserpassword => v_siteuserpassword,
      :v_systempassword => v_systempassword
    )
    mode 0777
  end
else
  block do
    raise "B1 version #{v_dbversion} not supported"
  end
end

# install samba
package 'samba' do
  action :install
end

#enable samba service
service "smb" do 
  pattern "smb"
  action [:enable, :start]
end

# Prerequisites needed for 9.2 PL3 and up
if v_dbversion.to_i >= 920130 
  # SuSEfirewall2
  bash "install SuSEfirewall2 " do
    user "root"
    code <<-EOH
      zypper install -y SuSEfirewall2
    EOH
    not_if {::File.exist?("/sbin/SuSEfirewall2")}
  end

  package 'nfs-kernel-server' do
    action :install
  end
end

# Prerequisites needed for 9.3 PL0 and up
if v_dbversion.to_i >= 930000 
  package 'python-cryptography' do
    action :install
  end

  if v_os_platform.downcase == "suse" 
    if v_os_platform_version == "11.3" || v_os_platform_version == "11.4"
      package 'python-openssl' do
        action :install
      end
    end
  end
end

# Prerequisites needed for 9.2 PL07 and up (see SAP Note 2418458)
# Required versions should be made available yast repositories (e.g. additional_repo) 
if v_os_platform.downcase == "suse" 
  if v_os_platform_version == "11.3" || v_os_platform_version == "11.4"
    if v_dbversion.to_i >= 920170 
      # required libgcc_s1 > 4.8.3
      package 'libgcc_s1' do 
        action :upgrade
      end

      # required libstdc++6 > 4.8.3
      package 'libstdc++6' do
        action :upgrade
      end
    end
  end
end

# Prerequisites needed for 9.3 PL07 and up
if v_os_platform.downcase == "suse" 
  if v_os_platform_version == "11.4"
    if v_dbversion.to_i >= 930170 
      # required liblua5_1 
      package 'liblua5_1' do 
        action :install
      end
    end
  end
end

# Prerequisites needed for SLES12 SP1 (see SAP Note 2458610) 
# Required packages should be made available yast repositories (e.g. additional_repo) 
if v_os_platform.downcase == "suse" 
  if v_os_platform_version == "12.1" || v_os_platform_version == "12.3" 
    package 'rpm-build' do
      action :install
    end

    package 'compat-libgcrypt11' do
      action :install
    end

    package 'libopenssl0_9_8' do
      action :install
    end
  end
end


#Execute install command
execute "install-b1h" do
  cwd "#{v_installerlocalsubfolder}"
  user "root"
  command "PATH=$PATH:~/bin:.:/sbin/usr/sbin ; ./#{v_installfilename} -i silent -f silentInstallConfig --debug 2> /tmp/b1_server_install_error.log > /tmp/b1_server_install_run.log"
  returns [0, 24, 25]
  action :run
  not_if { ::File.exists?("#{v_installerlocalfolder}/SERVER_INSTALLED_#{v_dbversion}")}
end

template "#{v_installerlocalfolder}/getServerDbVersion.sh" do
  source "getServerDbVersion.sh.erb"
  mode 0777
end

execute "Validate B1 Server Install" do
  cwd "#{v_installerlocalfolder}"
  command "sh ./getServerDbVersion.sh"
  not_if { ::File.exists?("#{v_installerlocalfolder}/SERVER_INSTALLED_#{v_dbversion}")}
end

ruby_block "Validate B1 Server Install" do
  block do
      raise "Server (B1ServerToolsSLD) is not installed or is not on the expected version"
  end
  not_if { ::File.exists?("#{v_installerlocalfolder}/SERVER_INSTALLED_#{v_dbversion}")}
end
