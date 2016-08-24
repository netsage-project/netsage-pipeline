Summary: GRNOC NetSage Deidentifier 
Name: grnoc-netsage-deidentifier
Version: 0.0.3
Release: 1%{?dist}
License: GRNOC
Group: Measurement
URL: http://globalnoc.iu.edu
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch
Requires: GeoIP-GeoLite-data
Requires: GeoIP-GeoLite-data-extra
Requires: perl >= 5.8.8
Requires: perl-Clone
Requires: perl-Data-Validate-IP
Requires: perl-File-Find-Rule
Requires: perl-File-Find-Rule-Age
Requires: perl-Geo-IP
Requires: perl-GRNOC-Config
Requires: perl-GRNOC-Log
Requires: perl-IPC-ShareLite
Requires: perl-JSON-XS
Requires: perl-List-MoreUtils
Requires: perl-Math-Round
Requires: perl-Moo
Requires: perl-Net-AMQP-RabbitMQ
Requires: perl-Net-IP
Requires: perl-Number-Bytes-Human
Requires: perl-Parallel-ForkManager
Requires: perl-Path-Class
Requires: perl-Proc-Daemon
Requires: perl-Socket6
Requires: perl-Text-Unidecode
Requires: perl-Time-Duration
Requires: perl-Time-HiRes
Requires: perl-Try-Tiny

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
%{__install} -d -p %{buildroot}/usr/bin/
%{__install} -d -p %{buildroot}/etc/init.d/
%{__install} -d -p %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/

%{__install} CHANGES.md %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/CHANGES.md
%{__install} INSTALL.md %{buildroot}/usr/share/doc/grnoc/netsage-deidentifier/INSTALL.md

%{__install} conf/netsage_deidentifier.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_deidentifier.xml
%{__install} conf/netsage_tagger.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_tagger.xml
%{__install} conf/netsage_finished_flow_mover.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_finished_flow_mover.xml
%{__install} conf/netsage_flow_cache.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_flow_cache.xml
%{__install} conf/netsage_flow_stitcher.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_flow_stitcher.xml
%{__install} conf/netsage_netflow_importer.xml.example %{buildroot}/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml
%{__install} conf/logging.conf.example %{buildroot}/etc/grnoc/netsage/deidentifier/logging.conf

%{__install} init.d/netsage-deidentifier-daemon  %{buildroot}/etc/init.d/netsage-deidentifier-daemon
%{__install} init.d/netsage-tagger-daemon %{buildroot}/etc/init.d/netsage-tagger-daemon
%{__install} init.d/netsage-netflow-importer-daemon %{buildroot}/etc/init.d/netsage-netflow-importer-daemon
%{__install} init.d/netsage-finished-flow-mover-daemon %{buildroot}/etc/init.d/netsage-finished-flow-mover-daemon
%{__install} init.d/netsage-flow-cache-daemon %{buildroot}/etc/init.d/netsage-flow-cache-daemon
%{__install} init.d/netsage-flow-stitcher-daemon %{buildroot}/etc/init.d/netsage-flow-stitcher-daemon

%{__install} bin/netsage-deidentifier-daemon  %{buildroot}/usr/bin/netsage-deidentifier-daemon
%{__install} bin/netsage-tagger-daemon %{buildroot}/usr/bin/netsage-tagger-daemon
%{__install} bin/netsage-netflow-importer-daemon %{buildroot}/usr/bin/netsage-netflow-importer-daemon
%{__install} bin/netsage-finished-flow-mover-daemon %{buildroot}/usr/bin/netsage-finished-flow-mover-daemon
%{__install} bin/netsage-flow-cache-daemon %{buildroot}/usr/bin/netsage-flow-cache-daemon
%{__install} bin/netsage-flow-stitcher-daemon %{buildroot}/usr/bin/netsage-flow-stitcher-daemon

# clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
rm -rf $RPM_BUILD_ROOT

%files

%defattr(640, root, root, -)

%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_deidentifier.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_tagger.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_finished_flow_mover.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/logging.conf
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_flow_cache.xml
%config(noreplace) /etc/grnoc/netsage/deidentifier/netsage_flow_stitcher.xml

%defattr(644, root, root, -)

/usr/share/doc/grnoc/netsage-deidentifier/CHANGES.md
/usr/share/doc/grnoc/netsage-deidentifier/INSTALL.md

%{perl_vendorlib}/GRNOC/NetSage/Deidentifier.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/Pipeline.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/WorkerManager.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowDeidentifier.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowTagger.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowMover.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/NetflowImporter.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowCache.pm
%{perl_vendorlib}/GRNOC/NetSage/Deidentifier/FlowStitcher.pm

%defattr(754, root, root, -)

/usr/bin/netsage-deidentifier-daemon
/usr/bin/netsage-tagger-daemon
/usr/bin/netsage-finished-flow-mover-daemon
/usr/bin/netsage-netflow-importer-daemon
/usr/bin/netsage-flow-cache-daemon
/usr/bin/netsage-flow-stitcher-daemon

/etc/init.d/netsage-deidentifier-daemon
/etc/init.d/netsage-tagger-daemon
/etc/init.d/netsage-finished-flow-mover-daemon
/etc/init.d/netsage-netflow-importer-daemon
/etc/init.d/netsage-flow-cache-daemon
/etc/init.d/netsage-flow-stitcher-daemon
