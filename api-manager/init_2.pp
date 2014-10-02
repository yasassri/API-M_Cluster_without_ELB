
# Parameter Class - Define all the parameters in this class
class params {

# General Settings

# File Locations
  $deployment_target  = '/home/yasassri/Desktop/QA_Resources/puppet/DEPLOY/deploy2'
  $pack_location      = '/home/yasassri/Desktop/soft/WSO2_Products/API_Manager/new'
  $script_base_dir    = inline_template("<%= Dir.pwd %>") #location will be automatically picked up

# DB Configurations
  $db_type = "mysql" #add keyword "oracle" or "mysql"

# MySQL configuration details
  $mysql_server         = 'localhost'
  $mysql_port           = '3306'

# Oracle DB detailes
  $oracle_server         = '192.168.10'
  $oracle_port           = '3306'

# General Database details

#Registry WSO2REGISTRY_DB
  $registry_db_name   	= 'apiregdbpuppet' # For oracle this would be the main DB name
  $registry_db_username = 'apimuser2'       # For oracle this is the user schema
  $registry_db_password = 'wso2root'        # For oracle this schema password

# user db WSO2UM_DB
  $users_mgt_db_name    = 'apiuserdbpuppet'
  $usermgt_db_username  = 'apimuser2'
  $usermgt_db_password  = 'wso2root'

  # Config Registry - WSO2CONFIGREG_DB

  $config_registry_db_name = 'apim_configdb_puppet'
  $config_db_username  = 'apimuser2'
  $config_db_password  = 'wso2root'

  # Stat DB WSO2AM_STATS_DB

  $stat_registry_db_name = 'apim_statDB_puppet'
  $stat_db_username  = 'apimuser2'
  $stat_db_password  = 'wso2root'

# APIM DB WSO2AM_DB
  $apim_db_name       = 'apimgtdbpuppet'
  $apim_db_username		= 'apimuser2'
  $apim_db_password   = 'wso2root'

##################################
#### KM Related Configs ##########

  # Manager Nodes Parameters only configure following if clustering true for the KM
  $km_manager_offsets             = ['1']
  $km_manager_hosts               = ['apim.180.km.com']
  $km_manager_ips                 = ['10.100.5.112']
  $km_manager_local_member_ports  = ['4001']


######################################
##### GateWay Related Configs ########

  $gw_manager_offsets            = ['2']
  $gw_manager_hosts              = ["apim.180.gw.com"] # Number of Nodes are determined from the array length
  $gw_manager_ips                = ['10.100.5.112']
  $gw_manager_local_member_ports = ['4003']

################################################
###### Publisher Related Configs ########

  $publisher_offsets            = ['3']
  $publisher_hosts              = ['apim.180.publisher.com']
  $publisher_ips                = ['10.100.5.112']
  $publisher_local_member_ports = ['4004']

#############################################
######## Store Related Configs ###########

  $store_offsets            = ['4']
  $store_hosts              = ['apim.180.store.com']
  $store_ips                = ['10.100.5.112']
  $store_local_member_ports = ['4005']

#######cluster details#########
  $pub_store_domain = "apim.qa.storepub.180"

############################################

  $admin_role_name ="Administrator"
  $admin_user_name = "Administrator"
  $admin_passwd = "admin123#"


#########Do Not Change#######

  $configchanges = ['conf/datasources/master-datasources.xml','conf/carbon.xml','conf/registry.xml','conf/user-mgt.xml','conf/axis2/axis2.xml','conf/api-manager.xml']
  $gate_way_deployment_configs = ['deployment/server/synapse-configs/default/api/_TokenAPI_.xml','deployment/server/synapse-configs/default/api/_RevokeAPI_.xml','deployment/server/synapse-configs/default/api/_AuthorizeAPI_.xml']

}

# Deployment Class
class deploy inherits params {

include km_deploy
include store_deploy
include publisher_deploy
include gw_deploy

}

class publisher_deploy inherits params {

 loop{"301":
    count=>301,
    setupnode => "publisher",
    deduct => 300
  }

}

class store_deploy inherits params{

  loop{"201":
    count=>201,
    setupnode => "store",
    deduct => 200
  }
}

class gw_deploy inherits params {

    # Configuring Manager Nodes
      loop{"101":
        count=>101,
        setupnode => "gw",
        deduct => 100
      }
}

class km_deploy inherits params {

   # Configuring Manager Nodes
    loop{"1":
      count=>1,
      setupnode => "km",
      deduct => 0
    }
}

# Loop for Spawning Members
define loop($count,$setupnode,$deduct) {

  if ($name > $count) {
    notice("Loop Iteration Finished!!!\n")
  }
  else
  {
    notice("########## Configuring ${setupnode} Nodes!!##############\n")

    $number = $name - $deduct
    file {"${params::deployment_target}/$setupnode-$number":
      ensure => directory;
    }

  #copying the Files (packs)
    exec { "Copying_$setupnode-$number":

      path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin', # The search path used for command execution.
      command => "cp -r ${params::pack_location}/wso2am-*/* ${params::deployment_target}/$setupnode-$number/",
      require => File["${params::deployment_target}/$setupnode-$number"],
    }

    # Copying Patches
    copy_files{"Cpy_patches_$setupnode-$number":
    from => "${params::script_base_dir}/libs/patches/",
    to   => "${params::deployment_target}/$setupnode-$number/repository/components/patches/",
    node_name=> "$setupnode-$number",
    unq_id=> "patches"
          }
  # Copying DB Drivers
    copy_files{"Cpy_drivers_$setupnode-$number":
      from => "${params::script_base_dir}/libs/db_drivers/",
      to   => "${params::deployment_target}/$setupnode-$number/repository/components/lib/",
      node_name=> "$setupnode-$number",
      unq_id=> "db_drivers"
    }

   $local_names = regsubst($params::configchanges, '$', "-$name")

    pushTemplates {$local_names:
      node_number => $number,
      nodes => $setupnode
    }

    if($setupnode == "gw"){

     $local_names2 = regsubst($params::gate_way_deployment_configs, '$', "-$name")
      pushTemplates {$local_names2:
        node_number => $number,
        nodes => $setupnode
      }
}

  $next = $name + 1
    loop { $next:
    count => "${count}",
    setupnode => "${setupnode}",
    deduct=>"${deduct}",
    }
  }
}

define copy_files($from,$to,$node_name,$unq_id){

  exec { "Cpy_${unq_id}_$node_name":
    path    => '/usr/bin:/bin',
    command => "rsync -r $from $to",
    require => [
      File["${params::deployment_target}/$node_name"],
      Package['rsync'],
      Exec["Copying_$node_name"]
    ],

  }
}

define pushTemplates($node_number,$nodes) {

  $orig_name = regsubst($name, '-[0-9]+$', '')

  file {"$params::deployment_target/${nodes}-${node_number}/repository/${orig_name}":

    ensure => present,
    mode    => '0755',
    content => template("${params::script_base_dir}/templates/${nodes}/${orig_name}.erb"),
    require => Exec["Copying_${nodes}-${node_number}"],
  }
}

# Package dependencies
package { 'rsync': ensure => 'installed' }

include deploy