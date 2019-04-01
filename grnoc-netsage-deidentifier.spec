Summary: GRNOC NetSage Deidentifier
Name: grnoc-netsage-deidentifier
Version: 1.1.0
Release: 1%{?dist}
License: GRNOC
Group: Measurement
URL: http://globalnoc.iu.edu
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch
Requires: perl >= 5.8.8

Requires: perl-AnyEvent
Requires: perl-Clone
Requires: perl-Data-Dumper
Requires: perl-Data-Validate-IP
Requires: perl-TimeDate
Requires: perl-Digest-SHA
Requires: perl-Getopt-Long
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
Requires: perl-Storable
Requires: perl-TimeDate
Requires: perl-Time-Duration
Requires: perl-Time-HiRes
Requires: perl-Try-Tiny
Requires: perl-Type-Tiny
Requires: wget >= 1.14

%description
GRNOC NetSage Flow Deidentifier Pipeline

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
%{__install} -d -p %{buildroot}/etc/cron.d/
%{__install} -d -p %{buildroot}/etc/logstash/conf.d/
%{__install} -d -p %{buildroot}/etc/logstash/conf.d/ruby/
%{__install} -d -p %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/

%{__install} CHANGES.md %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/CHANGES.md
%{__install} INSTALL.md %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/INSTALL.md

%{__install} conf/logging.conf.example %{buildroot}/etc/grnoc/netsage/deidentifier/logging.conf
%{__install} conf/logging-debug.conf.example %{buildroot}/etc/grnoc/netsage/deidentifier/logging-debug.conf
%{__install} conf/netsage_shared.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_shared.xml
%{__install} conf/netsage_flow_archive.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_flow_archive.xml
%{__install} conf/netsage_flow_cache.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_flow_cache.xml
%{__install} conf/netsage_flow_filter.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_flow_filter.xml
%{__install} conf/netsage_flow_stitcher.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_flow_stitcher.xml
%{__install} conf/netsage_netflow_importer.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml
%{__install} conf/netsage_raw_data_importer.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_raw_data_importer.xml
%{__install} conf-logstash/*.conf  %{buildroot}/etc/logstash/conf.d/
%{__install} conf-logstash/ruby/*  %{buildroot}/etc/logstash/conf.d/ruby/

%{__install} init.d/netsage-flow-archive-daemon %{buildroot}/etc/init.d/netsage-flow-archive-daemon
%{__install} init.d/netsage-flow-cache-daemon %{buildroot}/etc/init.d/netsage-flow-cache-daemon
%{__install} init.d/netsage-flow-filter-daemon %{buildroot}/etc/init.d/netsage-flow-filter-daemon
%{__install} init.d/netsage-flow-stitcher-daemon %{buildroot}/etc/init.d/netsage-flow-stitcher-daemon
%{__install} init.d/netsage-netflow-importer-daemon %{buildroot}/etc/init.d/netsage-netflow-importer-daemon

%{__install} cron.d/netsage-scireg_update %{buildroot}/etc/cron.d/netsage-scireg_update
%{__install} cron.d/netsage-scireg_update %{buildroot}/etc/cron.d/netsage-scireg_update
%{__install} cron.d/netsage-geoip_update %{buildroot}/etc/cron.d/netsage-geoip_update
%{__install} cron.d/netsage-geoip_update %{buildroot}/etc/cron.d/netsage-geoip_update

%{__install} bin/netsage-flow-archive-daemon %{buildroot}/usr/bin/netsage-flow-archive-daemon
%{__install} bin/netsage-flow-cache-daemon %{buildroot}/usr/bin/netsage-flow-cache-daemon
%{__install} bin/netsage-flow-filter-daemon %{buildroot}/usr/bin/netsage-flow-filter-daemon
%{__install} bin/netsage-flow-stitcher-daemon %{buildroot}/usr/bin/netsage-flow-stitcher-daemon
%{__install} bin/netsage-netflow-importer-daemon %{buildroot}/usr/bin/netsage-netflow-importer-daemon
%{__install} bin/netsage-raw-data-importer %{buildroot}/usr/bin/netsage-raw-data-importer

# clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
rm -rf $RPM_BUILD_ROOT

%files

%defattr(640, root, root, -)

%config(noreplace) /etc/grnoc/netsage/deidentifier/logging.conf
%config(noreplace) /etc/grnoc/netsage/deidentifier/logging-debug.conf
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_shared.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_flow_archive.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_flow_cache.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_flow_filter.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_flow_stitcher.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_raw_data_importer.xml
# logstash files with usernames and pws - if there are updates, use .rpmnew files to finish update by hand
%config(noreplace) /etc/logstash/conf.d/01-inputs.conf
%config(noreplace) /etc/logstash/conf.d/99-outputs.conf
# logstash files that can be updated automatically (if there are updates, the old ver will be in .rpmsave)
%config /etc/logstash/conf.d/05-geoip-tagging.conf
%config /etc/logstash/conf.d/06-scireg-tagging-fakegeoip.conf
%config /etc/logstash/conf.d/07-deidentify.conf
%config /etc/logstash/conf.d/08-cleanup.conf
%config /etc/logstash/conf.d/ruby/anonymize_ipv6.rb

%defattr(644, root, root, -)

/usr/share/doc/grnoc/netsage-deidentifier/CHANGES.md
/usr/share/doc/grnoc/netsage-deidentifier/INSTALL.md

%{perl_vendorlib}/GRNOC/NetSage/Deidentifier.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/Pipeline.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/WorkerManager.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowFilter.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/NetflowImporter.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/RawDataImporter.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowArchive.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowCache.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowStitcher.pm

%defattr(754, root, root, -)

/usr/bin/netsage-flow-archive-daemon
/usr/bin/netsage-flow-cache-daemon
/usr/bin/netsage-flow-filter-daemon
/usr/bin/netsage-flow-stitcher-daemon
/usr/bin/netsage-netflow-importer-daemon
/usr/bin/netsage-raw-data-importer

/etc/init.d/netsage-netflow-importer-daemon
/etc/init.d/netsage-flow-archive-daemon
/etc/init.d/netsage-flow-cache-daemon
/etc/init.d/netsage-flow-filter-daemon
/etc/init.d/netsage-flow-stitcher-daemon

%defattr(755, root, root, -)

%config(noreplace) /etc/cron.d/netsage-scireg_update
%config(noreplace) /etc/cron.d/netsage-geoip_update

/var/lib/grnoc/netsage/deidentifier/
/var/cache/netsage/

