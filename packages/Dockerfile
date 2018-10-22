# Bare image for testing config packages.
#
# This image is configured to use apt-cacher-ng running on the host
# machine, and hence is designed to not require an internet connection
# to build and run (assuming the base image is cached).
#
# To enable access from a running container to the host's
# apt-cacher-ng, the following firewall rule is required:
#
# iptables -A INPUT -i docker0 -p tcp --dport 3142 -j ACCEPT

FROM crashbox-config-base:latest

RUN echo 'Acquire::http::Proxy "http://172.17.0.1:3142";' \
	> /etc/apt/apt.conf.d/00aptproxy

COPY target/archive/ /usr/local/share/archive/
RUN echo "deb [trusted=yes] file:/usr/local/share/archive ./" \
	> /etc/apt/sources.list.d/local-archive.list
RUN apt-get update \
	-o Dir::Etc::sourcelist="sources.list.d/local-archive.list" \
	-o Dir::Etc::sourceparts="-" \
	-o APT::Get::List-Cleanup="0"

CMD ["bash"]
