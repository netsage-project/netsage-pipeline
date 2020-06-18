Summary: GRNOC NetSage Flow-Processing Pipeline
Name: grnoc-netsage-deidentifier
Version: 1.2.4
Release: 1%{?dist}
License: GRNOC
Group: Measurement
URL: http://globalnoc.iu.edu
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch
Requires: perl >= 5.8.8
# these are part of perl with centos6, not with centos7. Could just require perl-core package?
%if 0%{?rhel} >= 7
Requires: perl-Data-Dumper
Requires: perl-Getopt-Long
Requires: perl-Storable
%endif
Requires: perl-AnyEvent
Requires: perl-Clone
Requires: perl-Data-Validate-IP
Requires: perl-TimeDate
Requires: perl-Digest-SHA
Requires: perl-GRNOC-Config
Requires: perl-GRNOC-Log
Requires: perl-GRNOC-RabbitMQ
Requires: perl-Hash-Merge
Requires: perl-IPC-ShareLite
Requires: perl-JSON-SL
Requires: perl-JSON-XS
Requires: perl-List-MoreUtils
Requires: perl-Math-Round
Requires: perl-Moo
Requires: perl-Net-AMQP-RabbitMQ
Requires: perl-Net-IP
Requires: perl-Number-Bytes-Human
Requires: perl-Parallel-ForkManager
Requires: perl-Path-Class
Requires: perl-Path-Tiny
Requires: perl-Proc-Daemon
Requires: perl-TimeDate
Requires: perl-Time-Duration
Requires: perl-Time-HiRes
Requires: perl-Try-Tiny
Requires: perl-Type-Tiny
Requires: wget 
# logstash 7.4.1 includes a needed fix to the aggregate filter. 
Requires: logstash >= 7.4.2
Requires: rubygem-ipaddress

%description
GRNOC NetSage Flow-Processing Pipeline

%prep
%setup -q -n grnoc-netsage-deidentifier-%{version}

%build
%{__perl} Makefile.PL PREFIX="%{buildroot}%{_prefix}" INSTALLDIRS="vendor"
make

%install
rm -rf $RPM_BUILD_ROOT
make pure_install

%{__install} -d -p %{buildroot}/etc/grnoc/netsage/deidentifier/
%{__install} -d -p %{buildroot}/var/lib/grnoc/netsage/deidentifier/
%{__install} -d -p %{buildroot}/var/cache/netsage/
%{__install} -d -p %{buildroot}/usr/bin/
%{__install} -d -p %{buildroot}/etc/init.d/
%{__install} -d -p %{buildroot}/etc/systemd/system/
%{__install} -d -p %{buildroot}/etc/cron.d/
%{__install} -d -p %{buildroot}/etc/logstash/conf.d/
%{__install} -d -p %{buildroot}/etc/logstash/conf.d/ruby/
%{__install} -d -p %{buildroot}/etc/logstash/conf.d/support/
%{__install} -d -p %{buildroot}/usr/share/logstash/config/
%{__install} -d -p %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/

%{__install} CHANGES.md %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/CHANGES.md
%{__install} docs/INSTALL.md %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/INSTALL.md

%{__install} conf/logging.conf.example %{buildroot}/etc/grnoc/netsage/deidentifier/logging.conf
%{__install} conf/logging-debug.conf.example %{buildroot}/etc/grnoc/netsage/deidentifier/logging-debug.conf
%{__install} conf/netsage_shared.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_shared.xml
%{__install} conf/netsage_flow_filter.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_flow_filter.xml
%{__install} conf/netsage_netflow_importer.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml
%{__install} conf-logstash/*.conf  %{buildroot}/etc/logstash/conf.d/
%{__install} conf-logstash/ruby/*  %{buildroot}/etc/logstash/conf.d/ruby/
%{__install} conf-logstash/support/*  %{buildroot}/etc/logstash/conf.d/support/

%if 0%{?rhel} >= 7
%{__install} systemd/netsage-flow-filter.service %{buildroot}/etc/systemd/system/netsage-flow-filter.service
%{__install} systemd/netsage-netflow-importer.service %{buildroot}/etc/systemd/system/netsage-netflow-importer.service
%else
%{__install} init.d/netsage-flow-filter-daemon %{buildroot}/etc/init.d/netsage-flow-filter-daemon
%{__install} init.d/netsage-netflow-importer-daemon %{buildroot}/etc/init.d/netsage-netflow-importer-daemon
%endif

%{__install} cron.d/netsage-scireg_update %{buildroot}/etc/cron.d/netsage-scireg_update
%{__install} cron.d/netsage-geoip_update %{buildroot}/etc/cron.d/netsage-geoip_update
%{__install} cron.d/netsage-logstash_restart %{buildroot}/etc/cron.d/netsage-logstash_restart

%{__install} bin/netsage-flow-filter-daemon %{buildroot}/usr/bin/netsage-flow-filter-daemon
%{__install} bin/netsage-netflow-importer-daemon %{buildroot}/usr/bin/netsage-netflow-importer-daemon

# clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
rm -rf $RPM_BUILD_ROOT

%files

%defattr(644, root, root, 755)

# Don't overwrite importer configs. Create .rpmnew files if needed.
%config(noreplace) /etc/grnoc/netsage/deidentifier/logging.conf
%config(noreplace) /etc/grnoc/netsage/deidentifier/logging-debug.conf
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_shared.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_flow_filter.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml

# We don't want to overwrite these .confs. Create .rpmnew files if needed.
%config(noreplace) /etc/logstash/conf.d/01-inputs.conf
%config(noreplace) /etc/logstash/conf.d/99-outputs.conf
%config(noreplace) /etc/logstash/conf.d/40-aggregation.conf
# logstash files that can be updated automatically (if there are updates, the old ver will be in .rpmsave)
%config /etc/logstash/conf.d/10-preliminaries.conf
%config /etc/logstash/conf.d/20-add-id.conf
%config /etc/logstash/conf.d/50-geoip-tagging.conf
%config /etc/logstash/conf.d/55-member-orgs.conf
%config /etc/logstash/conf.d/60-scireg-tagging-fakegeoip.conf
%config /etc/logstash/conf.d/65-preferred-location-org.conf
%config /etc/logstash/conf.d/70-deidentify.conf
%config /etc/logstash/conf.d/80-privatize-org.conf
%config /etc/logstash/conf.d/90-additional-fields.conf
%config /etc/logstash/conf.d/95-cleanup.conf
%config /etc/logstash/conf.d/ruby/anonymize_ipv6.rb
%config /etc/logstash/conf.d/ruby/domestic.rb
%config /etc/logstash/conf.d/support/sensor_groups.json
%config /etc/logstash/conf.d/support/sensor_types.json
%config /etc/logstash/conf.d/support/networkA-members-list.rb.example

/usr/share/doc/grnoc/netsage-deidentifier/CHANGES.md
/usr/share/doc/grnoc/netsage-deidentifier/INSTALL.md

%{perl_vendorlib}/GRNOC/NetSage/Deidentifier.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/Pipeline.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/WorkerManager.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowFilter.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/NetflowImporter.pm

# will not overwrite
%config(noreplace) /etc/cron.d/netsage-scireg_update
%config(noreplace) /etc/cron.d/netsage-geoip_update
%config(noreplace) /etc/cron.d/netsage-logstash_restart

%defattr(754, root, root, -)
/usr/bin/netsage-flow-filter-daemon
/usr/bin/netsage-netflow-importer-daemon

%if 0%{?rhel} >= 7
%defattr(644, root, root, -)
/etc/systemd/system/netsage-flow-filter.service
/etc/systemd/system/netsage-netflow-importer.service
%else
%defattr(754, root, root, -)
/etc/init.d/netsage-flow-filter-daemon
/etc/init.d/netsage-netflow-importer-daemon
%endif

%defattr(-, root, root, 755)
/var/lib/grnoc/netsage/deidentifier/
/var/cache/netsage/

%post
echo "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
echo "AFTER UPGRADING..."
echo " "
echo " *  Check config and cron files with .rpmnew and .rpmsave versions to see if any need manual updates."
echo " *  Logstash configs 10, 40, and 99 are not replaced by updated versions, so check to see if there are changes. "
echo " *  If using 55-member-orgs.conf, make sure you have the required files in support/. See comments in the conf file. "
echo " "
echo " *  Note that this rpm puts logstash config files in /etc/logstash/conf.d/ and doesn't manage multiple pipelines in pipelines.yml."
echo " *  Nor does it manage multiple init.d files for sensor- or network-specific importers."
echo " "
echo " *  IMPORTANT: Be sure the number of logstash pipeline workers is 1, or flow stitching (aggregation) won't work right. **"
echo " "
echo " *  [Re]start logstash, netsage-netflow-importer (and netsage-flow-filter for cenic sensors only) "
echo "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"

