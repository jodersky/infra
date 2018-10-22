## Quasi-Immutable Infrastructure for Small-Scale Deployments

This project combines [terraform](https://www.terraform.io) with
[debian configuration packages](https://wiki.debian.org/Packaging) to
manage infrastructure automatically.

It has a very opinionated structure, ideal for managing a small amount
of (personal) servers.

It is used to manage the crashbox.io services.

## Overview

Management of infrastructure revolves around two central concepts:

1. Provisioning of infrastructure, such as virtual private
   servers and DNS entries, with terraform.

2. Configuration of servers with debian packages. Custom debian
   packages integrate easily into the debian ecosystem and provide a
   robust way of managing files.

These two concepts are brought together by *roles* which aggregate DNS
entries and packages.

**In a nutshell, all infrastructure is configured by assigning sets of
roles to servers. A role will apply a debian configuration package to
a server and create a CNAME to the server's A record.**

For example, assigning the `ip` role to server `server.crashbox.io` will:

1. Create the server and A record if it isn't already there.
2. Install the package `crashbox-ip-config` on the server.
3. Create a DNS CNAME, aliasing `ip.crashbox.io` to `server.crashbox.io`.

In the given example, the ip-config package will ensure a webserver is
installed and configure it to serve an ip address echo website.

## Structure

- Provisioning scripts are in `terraform/`.

- Configuration package sources are in `packages/`. Note that for a
  given role `<role>`, the corresponding debian package is
  `crasbox-<role>-config`.

## Running

### Bootstrap

Before infrastructure configuration can be automated, a couple of
bootstrapping steps need to be performed manually:

0. Create accounts for the various providers specified in the
terraform configuration.

1. Provision a storage space for the terraform state file.

2. Install dependencies for this project:
   - make
   - debhelper
   - debuild
   - terraform
   - pass

### Apply

Run `make` to apply configuration.

## Note about immutability

This project uses debian packages for stronger consistency guarantees
when removing packages. Nevertheless, it is recommended to completely
reprovision a server if a role is removed.

Keeping in mind that the goal of this project is to automate
deployments, regular reprovisions are encouraged.
