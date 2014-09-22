API-M_Cluster_without_ELB
=========================

What the script can do.
-----------------------
# The script can spawn an API-M cluster without ELB fronting.
# Supports both mysql and Oracle DB types.
# Can copy patches and DB drivers automatically to all the nodes.

What the Script can't do.
-------------------------

# Create new databases.
# Automatically spawning to remote nodes.

How to use the script
---------------------

Install Puppet agent (do not need puppet master) make sure you install version 3+.
Clone the repository and do the necessary parameter changes in the params class.
Execute the script "puppet apply init_2.pp"

Note:

If you do not want to spawn any of the nodes just simply remove following lines accordingly from the main deployment class.

include km_deploy
include store_deploy
include publisher_deploy
include gw_deploy

If the deployment target has any previous deploys the script will override the existing content. So its better to make sure you cean the deployment folder before executing the script.
