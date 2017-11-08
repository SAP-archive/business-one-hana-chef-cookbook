#Default attributes for b1h (HANA)

default['b1h']['archiverepo']           = nil

default['b1h']['patchrepo']             = nil
default['b1h']['relproductcdrepo']      = nil
default['b1h']['additional_repo']       = nil

default['b1h']['siteuserpassword']      = nil
default['b1h']['systempassword']        = nil
default['b1h']['installerfolder']       = "C:\\temp\\b1"

default['b1h']['is_multispan_archive']   = false
default['b1h']['archive']                = nil # e.g. "B1H92_PL02.zip"
default['b1h']['multispan_archives']     = nil # e.g. [ "B1H9200_2-80000480_P1.EXE", "B1H9200_2-80000480_P2.RAR", "B1H9200_2-80000480_P3.RAR", ... ]

default['b1h']['targetdbversion']       = nil # e.g. "920150"
default['b1h']['targetpatch']           = nil # e.g. "5"
default['b1h']['targetbranch']          = "SMP"
default['b1h']['targetchangelog']       = ""

default['b1hclient']['platform']        = "x64"
default['b1hclient']['programfiles']    = "C:\\Program Files (x86)"
default['b1hclient']['programfiles64']  = "C:\\Program Files"
default['b1hclient']['licenseserver'] 	= nil
default['b1hclient']['licenseserverip']	= nil
default['b1hclient']['dbversion']		= nil
default['b1hclient']['branch']			= nil
default['b1hclient']['patch']			= nil
default['b1hclient']['changelog']		= nil
