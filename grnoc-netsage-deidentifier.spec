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
%{__install} -d -p %{buildroot}/usr/share/logstash/config/
%{__install} -d -p %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/

%{__install} CHANGES.md %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/CHANGES.md
%{__install} INSTALL.md %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/INSTALL.md

%{__install} conf/logging.conf.example %{buildroot}/etc/grnoc/netsage/deidentifier/logging.conf
%{__install} conf/logging-debug.conf.example %{buildroot}/etc/grnoc/netsage/deidentifier/logging-debug.conf
%{__install} conf/netsage_shared.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_shared.xml
%{__install} conf/netsage_flow_filter.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_flow_filter.xml
%{__install} conf/netsage_netflow_importer.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml
%{__install} conf/netsage_raw_data_importer.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_raw_data_importer.xml
%{__install} conf-logstash/*.conf  %{buildroot}/etc/logstash/conf.d/
%{__install} conf-logstash/ruby/*  %{buildroot}/etc/logstash/conf.d/ruby/

%{__install} init.d/netsage-flow-filter-daemon %{buildroot}/etc/init.d/netsage-flow-filter-daemon
%{__install} init.d/netsage-netflow-importer-daemon %{buildroot}/etc/init.d/netsage-netflow-importer-daemon

%{__install} cron.d/netsage-scireg_update %{buildroot}/etc/cron.d/netsage-scireg_update
%{__install} cron.d/netsage-geoip_update %{buildroot}/etc/cron.d/netsage-geoip_update

%{__install} bin/netsage-flow-filter-daemon %{buildroot}/usr/bin/netsage-flow-filter-daemon
%{__install} bin/netsage-netflow-importer-daemon %{buildroot}/usr/bin/netsage-netflow-importer-daemon
%{__install} bin/netsage-raw-data-importer %{buildroot}/usr/bin/netsage-raw-data-importer

# clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
rm -rf $RPM_BUILD_ROOT

%files

%defattr(644, root, root, 755)

%config(noreplace) /etc/grnoc/netsage/deidentifier/logging.conf
%config(noreplace) /etc/grnoc/netsage/deidentifier/logging-debug.conf
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_shared.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_flow_filter.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_raw_data_importer.xml

# logstash files to not overwrite. If there are updates, use .rpmnew files to finish update by hand
%config(noreplace) /etc/logstash/conf.d/01-inputs.conf
%config(noreplace) /etc/logstash/conf.d/99-outputs.conf
# logstash files that can be updated automatically (if there are updates, the old ver will be in .rpmsave)
%config /etc/logstash/conf.d/02-convert.conf
%config /etc/logstash/conf.d/04-stitching.conf
%config /etc/logstash/conf.d/05-geoip-tagging.conf
%config /etc/logstash/conf.d/06-scireg-tagging-fakegeoip.conf
%config /etc/logstash/conf.d/07-deidentify.conf
%config /etc/logstash/conf.d/08-cleanup.conf
%config /etc/logstash/conf.d/ruby/anonymize_ipv6.rb

/usr/share/doc/grnoc/netsage-deidentifier/CHANGES.md
/usr/share/doc/grnoc/netsage-deidentifier/INSTALL.md

%{perl_vendorlib}/GRNOC/NetSage/Deidentifier.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/Pipeline.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/WorkerManager.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowFilter.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/NetflowImporter.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/RawDataImporter.pm

%config(noreplace) /etc/cron.d/netsage-scireg_update
%config(noreplace) /etc/cron.d/netsage-geoip_update

%defattr(754, root, root, -)

/usr/bin/netsage-flow-filter-daemon
/usr/bin/netsage-netflow-importer-daemon
/usr/bin/netsage-raw-data-importer

/etc/init.d/netsage-netflow-importer-daemon
/etc/init.d/netsage-flow-filter-daemon

%defattr(-, root, root, 755)

/var/lib/grnoc/netsage/deidentifier/
/var/cache/netsage/

%post
echo "--------------------"
echo "After installing or upgrading..."
echo "** Be sure the logstash keystore contains input and output rabbitmq usernames and passwords.**"
echo "Check to see if 01-inputs.conf or 99-outputs.conf need any updates."
echo "If you have pipelines set up, check those."
echo "** Be sure the number of logstash pipeline workers is 1, or flow stitching won't work right.**"
echo "See /usr/share/doc/grnoc/netsage-deidentifier/INSTALL.md for more information."
echo "[Re]start netsage-netflow-importer and logstash services."
echo "--------------------"

