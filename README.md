![](https://img.shields.io/badge/STATUS-NOT%20CURRENTLY%20MAINTAINED-red.svg?longCache=true&style=flat)

# Important Notice
This public repository is read-only and no longer maintained.

# Description
This cookbook will install SAP Business One for SAP HANA.
It contains the following recipes:
* b1::server
Recipe installs the SAP Business One server (SBO-Common, Server Tools, etc.).
* b1::client
Recipe installs the SAP Business One client.

SAP Business One Partners can find tutorials on how to use these cookbooks and setup Business One test environments with Chef on the [SAP PartnerEdge](https://partneredge.sap.com/en/products/business-one/support.html).

# Limitations

**_The SAP Business One Cookbooks do not follow the Business One installation process as described in the Business One Admin Guide.
It is recommended to use these Chef Cookbooks to only create SAP Business One Test and Demo environments. 
The SAP Business One Support Organization will not support Productive environment created with these Chef Cookbooks._**

* B1 versions from 9.2 Patch 4 are supported. The default version is the 'B1 9.2 PL5'.

# Requirements

Supported B1 Server platforms:

* SUSE 

The b1::server cookbook requires a HANA Server, HANA Client and AFL to be already installed.

Supported B1 Client platforms:

* Windows 

SAP HANA server must be installed first.

# Download and Installation

## Download

This Cookbook is meant to be used in conjonction with a Chef server.
You can use Knife or Berkshelf for example to add this Cookbook to a Chef Repository.

For example, you can add this line to the Berksfile of your wrapper cookbook:

	source 'https://supermarket.chef.io'
	metadata
	cookbook 'b1', git: 'https://github.com/SAP/business-one-hana-chef-cookbook.git'


## Usage 

#### b1h::server
This will install the B1 Server components, including the B1 Server, SLD, License Server, etc. You need to define the archive location, the version and the passwords.



`recipe[b1h::server]`

Attributes: 

	{
		"b1h":{
				"archiverepo": "http://myfileserver/b1-software/hana",
				"archive": "B1H92_PL05.zip",
				"targetdbversion": "920150",
				"targetpatch": "5",
				"systempassword": "MyPassword1",
				"siteuserpassword": "MyPassword1"
		}
	}


#### b1h::client
This will install the B1 Client. You need to define the archive location, the version and the passwords.

`recipe[b1h::client]`

Attributes: 

	{	
		"b1h":{
				"archiverepo": "http://myfileserver/b1-software/hana",
				"archive": "B1H92_PL05.zip"
		}
		"b1hclient":{
				"platform": "x86",
				"dbversion": "920150",
				"patch": "5"
		}
	}
	

# Configuration

## List of cookbook attributes
| Key | Type | Description | Default |
| --------------------------------- | ---- | ----------- | ------- |
| ['b1h']['archiverepo'] | String | **[Required]** Location of the compressed B1 installation archive | nil |
| ['b1h']['archive'] | String | Name of the B1 installation archive file | nil |
| ['b1h']['is_multispan_archive'] | Boolean | Specify if the compressed archive is a multispan archive | false |
| ['b1h']['multispan_archives'] | String array | Names of all the files in the B1 installation multispan archive  | nil |
| ['b1h']['targetdbversion'] | String | **[Required]** B1 Database Version  | nil |
| ['b1h']['targetpatch'] | String | **[Required]** B1 Patch Number | nil |
| ['b1h']['systempassword'] | String | **[Required]** SYSTEM password for the HANA server | nil |
| ['b1h']['siteuserpassword'] | String | **[Required]** B1SiteUser password for the SLD | nil |
| ['b1h']['additional_repo'] | String | Additional RPM Zypper repository | nil |
| ['b1h']['installerfolder'] | String | Temporary folder for the installation files| "C:\\temp\\b1" |
| ['b1hclient']['platform']  | String | Specifies if the 32 or 64 bits version of the client will be installed	| "x64" |
| ['b1hclient']['programfiles']  | String | The installation path of SAP Business One 32 bits | "C:\\Program Files (x86)" |
| ['b1hclient']['programfiles64']  | String | The installation path of SAP Business One 64 bits | "C:\\Program Files" |
| ['b1hclient']['licenseserver'] | String | The SLD server hostname | nil |
| ['b1hclient']['licenseserverip'] | String | The SLD server IP address | nil |
| ['b1hclient']['dbversion'] | String | [Required] For B1 Client. B1 Database Version. e.g. "920120" | nil |
| ['b1hclient']['patch'] | String | [Required] For B1 Client. B1 Patch Number. e.g. "2" | nil |
	
# How to obtain support
This project allows and expects users to post questions or bug reports in the [GitHub bug tracking system](../../issues).

# Contributing
If you would like to contribute, please fork this project and post pull requests.

# License
Copyright (c) 2017 SAP SE or an SAP affiliate company. All rights reserved.
This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the [LICENSE](LICENSE.txt) file.










