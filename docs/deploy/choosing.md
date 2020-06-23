---
id: choose_install
title: Choosing Install
sidebar_label: Choose Install
---

## BareMetal

The baremetal installation Guide will walk you through installing the pipeline using your own infrastructure and requires you to maintain all the components involved.

It will likely be a bit better when it comes to performance, but also has more complexity involved in configuring and setting up.

If you are the ultimate consumer of the data then setting up a baremetal version might be worth doing. Or at least the final rabbitMQ that will be holding the data since it'll like need to handle a large dataset.

## Dockerized Version

The docker version makes it trivial to bring up the pipeline for both a developer and consumer. All the work is mostly already done for you and it's should be a simple matter of configuring a few env settings and everything should 'just' work.

If you are simply using the pipeline to deliver the anonymized network stats for someone else's consumption, then using the docker pipeline would be preferred.

## Choose your adventure

- [Docker](docker_install)
- [BareMetal](install)
