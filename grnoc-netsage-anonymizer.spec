Summary: GRNOC NetSage Anonymizer 
Name: grnoc-netsage-anonymizer
Version: 0.0.1
Release: 1%{?dist}
License: GRNOC
Group: Measurement
URL: http://globalnoc.iu.edu
Source0: %{name}-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch: noarch
Requires: perl >= 5.8.8
Requires: perl-Try-Tiny
Requires: perl-GRNOC-Log
Requires: perl-GRNOC-Config
Requires: perl-Proc-Daemon
Requires: perl-List-MoreUtils
Requires: perl-Net-AMQP-RabbitMQ
Requires: perl-JSON-XS
Requires: perl-Time-HiRes
Requires: perl-Moo
#Requires: perl-Types-XSD-Lite
Requires: perl-Parallel-ForkManager
#Requires: perl-GRNOC-WebService-Client
Requires: perl-Math-Round

%description
GRNOC NetSage Flow Anonymizer Pipeline Workers

%prep
%setup -q -n grnoc-netsage-anonymizer-%{version}

%build
%{__perl} Makefile.PL PREFIX="%{buildroot}%{_prefix}" INSTALLDIRS="vendor"
make

%install
rm -rf $RPM_BUILD_ROOT
make pure_install

%{__install} -d -p %{buildroot}/etc/grnoc/netsage/anonymizer/
%{__install} -d -p %{buildroot}/var/lib/grnoc/netsage/anonymizer/
%{__install} -d -p %{buildroot}/usr/bin/
%{__install} -d -p %{buildroot}/etc/init.d/
%{__install} -d -p %{buildroot}/usr/share/doc/grnoc/netsage-anonymizer/

%{__install} CHANGES.md %{buildroot}/usr/share/doc/grnoc/netsage-anonymizer/CHANGES.md
%{__install} INSTALL.md %{buildroot}/usr/share/doc/grnoc/netsage-anonymizer/INSTALL.md

%{__install} conf/netsage_anonymizer.xml.example %{buildroot}/etc/grnoc/netsage/anonymizer/netsage_anonymizer.xml
%{__install} conf/netsage_tagger.xml.example %{buildroot}/etc/grnoc/netsage/anonymizer/netsage_tagger.xml
%{__install} conf/netsage_finished_flow_mover.xml.example %{buildroot}/etc/grnoc/netsage/anonymizer/netsage_finished_flow_mover.xml
%{__install} conf/logging.conf.example %{buildroot}/etc/grnoc/netsage/anonymizer/logging.conf

%{__install} init.d/netsage-anonymizer-daemon  %{buildroot}/etc/init.d/netsage-anonymizer-daemon
%{__install} init.d/netsage-tagger-daemon %{buildroot}/etc/init.d/netsage-tagger-daemon
%{__install} init.d/netsage-finished-flow-mover-daemon %{buildroot}/etc/init.d/netsage-finished-flow-mover-daemon

%{__install} bin/netsage-anonymizer-daemon  %{buildroot}/usr/bin/netsage-anonymizer-daemon
%{__install} bin/netsage-tagger-daemon %{buildroot}/usr/bin/netsage-tagger-daemon
%{__install} bin/netsage-finished-flow-mover-daemon %{buildroot}/usr/bin/netsage-finished-flow-mover-daemon

# clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;

%{_fixperms} $RPM_BUILD_ROOT/*

%clean
rm -rf $RPM_BUILD_ROOT

%files

%defattr(640, root, root, -)

%config(noreplace) /etc/grnoc/netsage/anonymizer/config.xml
%config(noreplace) /etc/grnoc/netsage/anonymizer/logging.conf

%defattr(644, root, root, -)

/usr/share/doc/grnoc/netsage-anonymizer/CHANGES.md
/usr/share/doc/grnoc/netsage-anonymizer/INSTALL.md

%{perl_vendorlib}/GRNOC/NetSage/Anonymizer.pm
%{perl_vendorlib}/GRNOC/NetSage/Anonymizer/Pipeline.pm
%{perl_vendorlib}/GRNOC/NetSage/Anonymizer/WorkerManager.pm
%{perl_vendorlib}/GRNOC/NetSage/Anonymizer/FlowAnonymizer.pm
%{perl_vendorlib}/GRNOC/NetSage/Anonymizer/FlowTagger.pm
%{perl_vendorlib}/GRNOC/NetSage/Anonymizer/FlowMover.pm
%{perl_vendorlib}/GRNOC/NetSage/Anonymizer/Aggregator/Message.pm

%defattr(754, root, root, -)

/usr/bin/netsage-anonymizer-daemon
/usr/bin/netsage-tagger-daemon
/usr/bin/netsage-finished-flow-mover-daemon

/etc/init.d/netsage-anonymizer-daemon
/etc/init.d/netsage-tagger-daemon
/etc/init.d/netsage-finished-flow-mover-daemon

%defattr(755, root, root, -)

%dir /var/lib/grnoc/netsage/anonymizer/
