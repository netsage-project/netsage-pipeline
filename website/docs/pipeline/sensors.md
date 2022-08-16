---
id: sensors
title: Sflow/Netflow Data Export
sidebar_label: Sflow/Netflow Data
---

Export of sflow and netflow/IPFIX data can be configured on appropriate network devices. Routers and switches will have at least one of these capabililties built in, although implementations can somtimes be buggy.

We have assumed that each exporter/sensor is configured to send flow data to a different port on the pipeline host. Certainly if different sensors use different sampling rates, this needs to be adhered to. The pipeline uses the port number to recognize which sensor the flows are coming from and tag them with the name of that sensor.

Sflow exporters simply collect individual **samples** of packets passing through the device and send them to a collector (pmacct in our case). The netsage pipeline then looks for matching packets to aggregate into flows. The sampling rate can be configured, eg, 1 out of every 100 packets. 

>To approximately correct for the fact that most packets are not detected, one assumes that each sampled packet represents N others and multiplies the number of bytes in the sampled packet by the sampling rate N, eg, 100. The sampling rate compared to the number of packets per second flowing through the device determines how accurate this approximation is. Sampling is least accurate for shorter flows since their packets will be more likely to be missed and the correction applied may overestimate the number of bytes in the flow. Discussions of accuracy and sampling rates can be found online. 

Netflow also commonly samples packets, and the same sampling corrections must be appled, but it also keeps track of the flows and aggregates by the 5-tuple (source and destination IPs, ports, and protocol) *on the router*. The **active timeout** determines how often netflow sends out an "update" on the flows it is aggregating. The **inactive timeout** determines how long to wait for another matching packet before declaring that a flow has ended.   

>Typically, the active timeout is set to 1 minute and the inactive timeout to 15 seconds. This means that for flows longer than 1 minute, a "netflow update" is sent out every minute. The tricky thing is that these update-flows all have the same start time (the time the first packet was observed). The end time (the time the last packet was observed) and duration change, but the number of bytes and packets reported corresponds only to the period since the last update.  The netsage pipeline attempts to combine these updates to aggregate long flows correctly.
>
>Netflow exporters also periodically send "templates" which describe the contents of the flow data datagrams. Before the first template is sent, the flow collector won't know what the sampling rate is, so templates should be sent frequently, eg, every minute.