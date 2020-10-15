---
id: docker_install
title: Docker Installation Guide
sidebar_label: Docker Install
---

The docker pattern is provided as much simpler and easier to use pattern that allows you to process and send data without having to deal with all
the nuances of getting the pipeline setup.

Before we start, you may have a read over the [developer docker guide](../devel/docker) it contains several notes such as how to select the docker version and likely other bits of information you may find useful.

## Nfdump

Note that no matter if you use a localized version or take advantage of the docker container already built. You will need to configure your routers to send nfdump stats to the process collecting data on the host:port that you'll be defining.

More info of nfdump can be found [here](https://github.com/phaag/nfdump/)

### External Nfdump

In this case you have nfdump running in your network somewhere and would like to keep on using it rather then relying on the container provided.

You'll need to update your scripts to output to ` ` `$PROJECT/data/input_data` ` ` . Naturally all the paths are configurable but you'll have a much easier if you stick to the defaults.

If you do choose to store the data elsewhere, the location may still need to be inside of the \$PROJECT or a docker volume location in order for docker to be able to reference it.

You will also need to configure your routers to point to the nfdump hostname and port in order for nfdump to collect data.

### Dockerized nfdump

We'll explore this in a later chapter. Depending on your use case please follow the simple or advanced docker guide.

### Choose your Docker Adventure

At this point, the instruction are going to diverge. To keep the documentation easier to understand we're going to split the advanced instruction into a different set.

- If you only need 1 collector of each type (netflow/sflow) at most, then the default adventure will work. Please click [here](docker_install_simple.md) to continue
- If you are an advanced user. You need more then 1 collector or just want an indepth understanding of the pipeline please click [here](docker_install_advanced.md) to continue on your special adventure.
