---
id: choose_install
title: Choosing an Installation Procedure
sidebar_label: Choose Install
---

## Manual or BareMetal Installation

The Manual (baremetal) Installation Guide will walk you through installing the pipeline using your own server infrastructure and requires you to maintain all the components involved.

It will likely be a bit better when it comes to performance, and have greater flexibility, but there is also more complexity involved in configuring and setting up.

If you are the ultimate consumer of the data then setting up a baremetal version might be worth doing. Or at least the final rabbitMQ that will be holding the data since it'll like need to handle a large dataset.

## Dockerized Version

The Docker version makes it trivial to bring up the pipeline for both a developer and consumer. The work is mostly already done for you. It should be a simple matter of configuring a few env settings and everything should 'just' work.

If you are simply using the pipeline to deliver the anonymized network stats for someone else's consumption, then using the docker pipeline would be preferred.

## Choose your adventure

- [Manual/Server Installation](bare_metal_install)
- [Simple Docker](docker_install_simple.md) - 1 netflow sensor and/or 1 sflow sensor
- [Advanced Docker](docker_install_advanced.md) - options that allow for more complex configurations
