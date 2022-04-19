Summary: GRNOC NetSage Flow-Processing Pipeline
Name: grnoc-netsage-pipeline
Version: 2.0.0
  # update Version here, in Makefile.PL, conf-logstash/98-post-process.conf
Release: 1%{?dist}
License: GRNOC
Group: Measurement
URL: http://globalnoc.iu.edu
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch
#Requires: perl >= 5.8.8
# these are part of perl with centos6, not with centos7. Could just require perl-core package?
#%if 0%{?rhel} >= 7
#Requires: perl-Data-Dumper
#Requires: perl-Getopt-Long
#Requires: perl-Storable
#%endif
#Requires: perl-AnyEvent
#Requires: perl-Clone
#Requires: perl-Data-Validate-IP
#Requires: perl-TimeDate
#Requires: perl-Digest-SHA
#Requires: perl-GRNOC-Config
#Requires: perl-GRNOC-Log
#Requires: perl-GRNOC-RabbitMQ
#Requires: perl-Hash-Merge
#Requires: perl-IPC-ShareLite
#Requires: perl-JSON-SL
#Requires: perl-JSON-XS
#Requires: perl-List-MoreUtils
#Requires: perl-Math-Round
#Requires: perl-Moo
#Requires: perl-Net-AMQP-RabbitMQ
#Requires: perl-Net-IP
#Requires: perl-Number-Bytes-Human
#Requires: perl-Parallel-ForkManager
#Requires: perl-Path-Class
#Requires: perl-Path-Tiny
#Requires: perl-Proc-Daemon
#Requires: perl-TimeDate
#Requires: perl-Time-Duration
#Requires: perl-Time-HiRes
#Requires: perl-Try-Tiny
#Requires: perl-Type-Tiny
Requires: wget 
Requires: logstash >= 7.16.2
Requires: rubygem-ipaddress
#Requires: pmacct = 1.7.7 (Not installed by rpm; see post section below for a check. Update ver num there!)

%description
GRNOC NetSage Flow-Processing Pipeline

%prep
%setup -q -n grnoc-netsage-pipeline-%{version}

%build
%{__perl} Makefile.PL PREFIX="%{buildroot}%{_prefix}" INSTALLDIRS="vendor"
make

%install
rm -rf $RPM_BUILD_ROOT
make pure_install

# for lookup files (maxmind, etc)
%{__install} -d -p %{buildroot}/var/lib/grnoc/netsage/

#%{__install} -d -p %{buildroot}/var/cache/netsage/
#%{__install} -d -p %{buildroot}/etc/init.d/

%{__install} -d -p %{buildroot}/usr/bin/
%{__install} -d -p %{buildroot}/etc/cron.d/
%{__install} -d -p %{buildroot}/etc/systemd/system/
%{__install} -d -p %{buildroot}/etc/logstash/conf.d/
%{__install} -d -p %{buildroot}/etc/logstash/conf.d/ruby/
%{__install} -d -p %{buildroot}/etc/logstash/conf.d/support/
%{__install} -d -p %{buildroot}/usr/share/logstash/config/
%{__install} -d -p %{buildroot}/usr/share/doc/grnoc/netsage-pipeline/

%{__install} bin/restart-logstash.sh %{buildroot}/usr/bin/restart-logstash.sh

%{__install} cron.d/netsage-scireg-update.cron %{buildroot}/etc/cron.d/netsage-scireg-update.cron
%{__install} cron.d/netsage-maxmind-update.cron %{buildroot}/etc/cron.d/netsage-maxmind-update.cron
%{__install} cron.d/netsage-caida-update.cron %{buildroot}/etc/cron.d/netsage-caida-update.cron
%{__install} cron.d/netsage-memberlists-update.cron %{buildroot}/etc/cron.d/netsage-memberlists-update.cron
%{__install} cron.d/netsage-logstash-restart.cron %{buildroot}/etc/cron.d/netsage-logstash-restart.cron

%{__install} systemd/logstash.service %{buildroot}/etc/systemd/system/logstash.service

%{__install} conf-logstash/*.conf  %{buildroot}/etc/logstash/conf.d/
%{__install} conf-logstash/*.conf.disabled  %{buildroot}/etc/logstash/conf.d/
%{__install} conf-logstash/ruby/*  %{buildroot}/etc/logstash/conf.d/ruby/
%{__install} conf-logstash/support/*  %{buildroot}/etc/logstash/conf.d/support/

%{__install} CHANGES.md %{buildroot}/usr/share/doc/grnoc/netsage-pipeline/CHANGES.md
%{__install} website/docs/deploy/bare_metal_install.md %{buildroot}/usr/share/doc/grnoc/netsage-pipeline/INSTALL.md


# clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
rm -rf $RPM_BUILD_ROOT

%files

%defattr(644, root, root, 755)

# Don't overwrite cron files. Create .rpmnew files if needed.
%config(noreplace) /etc/cron.d/netsage-scireg-update.cron
%config(noreplace) /etc/cron.d/netsage-maxmind-update.cron
%config(noreplace) /etc/cron.d/netsage-caida-update.cron
%config(noreplace) /etc/cron.d/netsage-memberlists-update.cron
%config(noreplace) /etc/cron.d/netsage-logstash-restart.cron

# Don't overwrite these .confs. Create .rpmnew files if needed.
%config(noreplace) /etc/logstash/conf.d/01-input-rabbit.conf
%config(noreplace) /etc/logstash/conf.d/15-sensor-specific-changes.conf
%config(noreplace) /etc/logstash/conf.d/40-aggregation.conf
%config(noreplace) /etc/logstash/conf.d/99-output-rabbit.conf
# logstash files that can be updated automatically (if there are updates, the old ver will be in .rpmsave)
%config(noreplace) /etc/logstash/conf.d/01-input-jsonfile.conf.disabled
%config(noreplace) /etc/logstash/conf.d/01-input-multiline-json-file.conf.disabled
%config(noreplace) /etc/logstash/conf.d/99-output-jsonlog.conf.disabled
%config(noreplace) /etc/logstash/conf.d/99-output-multiline-json.conf.disabled
%config(noreplace) /etc/logstash/conf.d/99-output-elastic.conf.disabled
%config /etc/logstash/conf.d/10-preliminaries.conf
%config /etc/logstash/conf.d/20-add-id.conf
%config /etc/logstash/conf.d/45-geoip-tagging.conf
%config /etc/logstash/conf.d/50-asn.conf
%config /etc/logstash/conf.d/53-caida-org.conf
%config /etc/logstash/conf.d/55-member-orgs.conf
%config /etc/logstash/conf.d/60-scireg-tagging-fakegeoip.conf
%config /etc/logstash/conf.d/70-deidentify.conf
%config /etc/logstash/conf.d/80-privatize-org.conf
%config /etc/logstash/conf.d/88-preferred-location-org.conf
%config /etc/logstash/conf.d/90-additional-fields.conf
%config /etc/logstash/conf.d/95-cleanup.conf
%config /etc/logstash/conf.d/98-post-process.conf
%config /etc/logstash/conf.d/99-output-stdout.conf.disabled
%config /etc/logstash/conf.d/ruby/anonymize_ipv6.rb
%config /etc/logstash/conf.d/ruby/domestic.rb
%config /etc/logstash/conf.d/support/sensor_groups.json
%config /etc/logstash/conf.d/support/sensor_types.json
%config /etc/logstash/conf.d/support/networkA-members-list.rb.example

/usr/share/doc/grnoc/netsage-pipeline/CHANGES.md
/usr/share/doc/grnoc/netsage-pipeline/INSTALL.md

%defattr(754, root, root, -)
/usr/bin/restart-logstash.sh

%defattr(644, root, root, -)
/etc/systemd/system/logstash.service

%defattr(-, root, root, 755)
/var/lib/grnoc/netsage/
#/var/cache/netsage/

%post
# make sure pmacct is installed (no rpm so can't just require it)
echo " "
echo "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
if [ -f /usr/local/sbin/nfacctd ]; then
    echo "PLEASE CHECK: "
    echo "It looks like pmacct has been installed."
    echo "Check the version with  sfacctd -V  and  nfacctd -V."
    echo "The Netage Pipeline has been tested with version 1.7.7."
else
    echo "WARNING: "
    echo "Required package pmacct does not appear to have been installed. "
    echo "See the NDCA doc or pmacct on github for instructions."
    echo "The Netage Pipeline has been tested with version 1.7.7."
fi

echo " "
echo "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
echo "AFTER UPGRADING..."
echo " "
echo " *  Check config and cron files with .rpmnew and .rpmsave versions to see if any need manual updates."
echo " *  Logstash configs 01, 15, 40, and 99 are not replaced by updated versions, so check to see if there are changes. "
echo " *  If using 55-member-orgs.conf, make sure you have the required files in support/. See comments in the conf file. "
echo " "
echo " *  Note that this rpm puts logstash config files in /etc/logstash/conf.d/ and doesn't manage multiple pipelines in pipelines.yml."
echo " "
echo " *  IMPORTANT: Be sure the number of logstash pipeline workers is 1, or flow stitching (aggregation) won't work right. **"
echo " *      and be sure logstash configs are specified by *.conf in the right directory."
echo " "
echo " *  [Re]start logstash and pmacct processes "
echo "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
echo " "

