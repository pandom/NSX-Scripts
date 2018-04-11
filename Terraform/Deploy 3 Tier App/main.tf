## Connect to NSX Manager.
provider "nsxt" {
    host = "nsxmgr-01a.corp.local"
    username = "admin"
    password = "VMware1!"
    insecure = true
}
## Collect data
data "nsxt_transport_zone" "TZ1" {
    display_name = "TZ1"
}

data "nsxt_logical_tier0_router" "T0" {
  display_name = "T0"
}

data "nsxt_edge_cluster" "EC1" {
  display_name = "EC1"
}

## Create T1 Router.
resource "nsxt_logical_tier1_router" "T1" {
  description = "T1 provisioned by Terraform"
  display_name = "T1-TF"
  failover_mode =  "PREEMPTIVE"
  high_availability_mode = "ACTIVE_STANDBY"
  edge_cluster_id = "${data.nsxt_edge_cluster.EC1.id}"
  enable_router_advertisement = "true"
  advertise_connected_routes = "true"
  

  tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}

## Connect T1 to T0.
resource "nsxt_logical_router_link_port_on_tier0" "T0-RP" {
    # description = "${nsxt_logical_router_link_port_on_tier0.T0-RP.display_name} to ${nsxt_logical_router_link_port_on_tier1.T1-RP.display_name}"
    display_name = "T0-RP"
    logical_router_id =  "${data.nsxt_logical_tier0_router.T0.id}"
    tags = [{
        scope = "princeps"
        tag = "augustus"}
    ]
}


resource "nsxt_logical_router_link_port_on_tier1" "T1-RP" {
    # description = "${nsxt_logical_router_link_port_on_tier0.T0-RP.display_name} to ${nsxt_logical_router_link_port_on_tier1.T1-RP.display_name}"
    display_name = "T1-RP"
    logical_router_id =  "${nsxt_logical_tier1_router.T1.id}"
    linked_logical_router_port_id = "${nsxt_logical_router_link_port_on_tier0.T0-RP.id}"
    tags = [{
        scope = "princeps"
        tag = "augustus"}
    ]
}
## Create Logical Switches
resource "nsxt_logical_switch" "WEBLS" {
  count = 1
  admin_state = "UP"
  description = "Web LS provisioned by Terraform"
  display_name = "Web LS"
  transport_zone_id = "${data.nsxt_transport_zone.TZ1.id}"
  replication_mode = "MTEP"

  tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}
resource "nsxt_logical_switch" "APPLS" {
  count = 1
  admin_state = "UP"
  description = "App LS provisioned by Terraform"
  display_name = "App LS"
  transport_zone_id = "${data.nsxt_transport_zone.TZ1.id}"
  replication_mode = "MTEP"

  tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}
resource "nsxt_logical_switch" "DBLS" {
  count = 1
  admin_state = "UP"
  description = "Db LS provisioned by Terraform"
  display_name = "Db LS"
  transport_zone_id = "${data.nsxt_transport_zone.TZ1.id}"
  replication_mode = "MTEP"

  tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}
## Create ports on respective LS.
resource "nsxt_logical_port" "LPWEB" {
  count = 1
  admin_state = "UP"
  description = "LP-WEB provisioned by Terraform"
  display_name = "LP-WEB"
  logical_switch_id = "${nsxt_logical_switch.WEBLS.id}"
  tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}

resource "nsxt_logical_port" "LPAPP" {
  count = 1
  admin_state = "UP"
  description = "LP-WEB provisioned by Terraform"
  display_name = "LP-APP"
  logical_switch_id = "${nsxt_logical_switch.APPLS.id}"
  tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}

resource "nsxt_logical_port" "LPDB" {
  count = 1
  admin_state = "UP"
  description = "LP-WEB provisioned by Terraform"
  display_name = "LP-DB"
  logical_switch_id = "${nsxt_logical_switch.DBLS.id}"
  tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}
## Create LIFs on T1 DLR.
resource "nsxt_logical_router_downlink_port" "DP1" {
  count = 1
  description = "LIF-WEB provisioned by Terraform"
  display_name = "LIF-WEB"
  logical_router_id = "${nsxt_logical_tier1_router.T1.id}"
  linked_logical_switch_port_id = "${nsxt_logical_port.LPWEB.id}"
  subnets = [{ip_addresses = ["172.16.10.1"], prefix_length = 24}
    ]
    tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}

resource "nsxt_logical_router_downlink_port" "DP2" {
  count = 1
  description = "LIF-APP provisioned by Terraform"
  display_name = "LIF-APP"
  logical_router_id = "${nsxt_logical_tier1_router.T1.id}"
  linked_logical_switch_port_id = "${nsxt_logical_port.LPAPP.id}"
  subnets = [{ip_addresses = ["172.16.20.1"], prefix_length = 24}
    ]
    tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}

resource "nsxt_logical_router_downlink_port" "DP3" {
  count = 1
  description = "LIF-DB provisioned by Terraform"
  display_name = "LIF-DB"
  logical_router_id = "${nsxt_logical_tier1_router.T1.id}"
  linked_logical_switch_port_id = "${nsxt_logical_port.LPDB.id}"
  subnets = [{ip_addresses = ["172.16.30.1"], prefix_length = 24}
    ]
    tags = [{ scope = "princeps"
            tag = "augustus"}
  ]
}





