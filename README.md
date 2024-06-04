# OpenConfig Neighbor Discovery protocol (gNDP)

## Objective

Define services for interacting with on box services for neighbor interactions.

* Define an RPC service for injecting metadata into the LLDP process running on box.  
The current requirements for device neighbor discovery require the use of packet io for a very limited set of functions. LLDP and traceroute packets. These both could be off loaded into the box. For LLDP there still needs to be metadata delivered to neighbors to discover routing readiness.  This document describes the RPC service for this implementation. Other projects (e.g., dSDN/dTE) also use LLDP for discovery between nodes and would benefit from a generic means to program custom LLDP TLVs.

Additionally this service can be expanded to support neighbor discovery for IPv6 as well for equivalent capability advertisment.

## Background

[LLDP Specification](https://en.wikipedia.org/wiki/Neighbor_Discovery_Protocol)
[ICMPv6 Specification](https://en.wikipedia.org/wiki/ICMPv6)

### Current design with PacketIO

Currently LLDP packets are matched by PacketIO and punted to the controller for processing from all ports on the device via a punt rule.  The controller then handles all LLDP neighbor processing. The one additional note is that the "routing readiness" TLV is the most important feature we are focused on processing.
Overview
Workflows supported
Controller wants to advertise routing readiness to connected neighbors
The controller has determined that the router is converged and ready to accept packets.  The routing readiness TLV is then set for the device via the gndp.Set() rpc with the TLV for routing readiness set to true.  

Controller wants to withdraw routing readiness to connected neighbors
The controller has determined that the router is no longer able to process packets and wants to remove the "routing readiness".  The controller will then send a `gndp.LLDP.Set()` with the TLV for routing readiness set to false.  

Controller wants to validate TLVs received from LLDP neighbors.
Controller subscribes to the gNMI path for LLDP.

Model: openconfig-lldp
Path: /lldp/interfaces/interface/neighbors/neighbor/custom-tlvs/tlv/

The controller can then via Set configure the custom TLV's and Get to validate they are properly set. The gNMI stream can then be used for validation of peer state.

Control card stateless failover should reset advertised neighbor data.
When the device has a failover which does not maintain all controller state, the neighbor data must be reset.  For device reset the following propagation of data should be expected:

* Cold boot: all neighbor data should be reset
* NSF reboot: all neighbor data should be reset
* Stateful switchover: all neighbor data should be persisted. This requires that all controller state is maintained as well, if this is not the case the
  neighbor data should be reset.

## Non-goals

This protocol is not meant to replace or supersede the need for packetIO only to provide direct access to the LLDP service running on a device.
Detailed Design
Option 1 Creation of gNDP Service - Preferred

## Protocol buffer implementation

```proto

service LLDP {
  // Set sets the list of TLV's to be advertised to LLDP neighbors.
  Set(SetRequest) (returns SetResponse)
  // Get gets the currently advertised TLV's to LLDP neighbors.
  Get(GetRequest) (returns GetResponse)
}

// SetRequest contains the list of TLV's to be set to be advertised to LLDP neighbors.  Every call to set is a replace operation for the set of TLV's to be advertised to neighbors.
message SetRequest {
  repeated TLV tlvs = 1;
}

message TLV {
  string OUI = 1;
  string subtype = 2;
  string value = 3;
}

message GetRequest {}

message GetResponse {
  string chassis_id = 1;
  string system_name = 2;
  string system_description = 3;
  string system_capabilities = 4;
  string management_address = 5;
  repeated TLV tlvs = 7;
}

```

### gNMI proto changes

We will add a leaf in OC for supporting LLDP TLV's received. This will allow the controller to subscribe to these endpoints and react to any data changes.

Provided by:
<https://openconfig.net/projects/models/schemadocs/yangdoc/openconfig-lldp.html#lldp-interfaces-interface-neighbors-neighbor-custom-tlvs-tlv>
