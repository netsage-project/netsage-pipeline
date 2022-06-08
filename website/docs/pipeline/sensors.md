---
id: sensors
title: Sflow/Netflow Data Export
sidebar_label: Sflow/Netflow Data
---

Sflow and Netflow (including IPFIX) export can be configured on appropriate network devices. Routers and switches have flow export capabililties built in, although they can somtimes be buggy.
We have assumed that each sensor sends flow data to a different port on the pipeline host. Certainly if different sensors use different sampling rates, this needs to be adhered to. 

Sflow collects samples of packets passing through the device and sends them to a collector. The sampling rate can be configured, eg, 1 out of every 100 packets. It is assumed that, in our example, each observed packet represents 100 similar packets. To approximately correct for sampling, the number of bytes in the packet is multiplied by 100. The sampling rate compared to the number of packets per second flowing through the device determines how accurate this approximation is. It is of course, least accurate for very short flows.

Netflow may also sample packets, and the same sampling corrections apply, but it also keeps track of the flows and aggregates by the so-called 5-tuple (source and destination IPs, ports, and protocol). The "active timeout" determines how often netflow sends out an "update" on the flows it is aggregating. The "inactive timeout" determines how long to wait for another matching packet, that is when to declare that a flow has ended. 
Typically, the active timeout is 1 minute and the inactive timeout 15 seconds. For flows longer than 1 minute, an "update" is sent out every minute. The tricky thing is that these updates all have the same start time (the time the first packet was observed), although the end time (the time the last packet was observed) and duration change, and the number of bytes and packets reported corresponds only to the period since the last update. 
The netsage pipeline attempts to combine the updates to aggregate (and also break up) long flows correctly.
