(window.webpackJsonp=window.webpackJsonp||[]).push([[38],{100:function(e,t,n){"use strict";n.d(t,"a",(function(){return u})),n.d(t,"b",(function(){return h}));var o=n(0),a=n.n(o);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function l(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function r(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?l(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):l(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function s(e,t){if(null==e)return{};var n,o,a=function(e,t){if(null==e)return{};var n,o,a={},i=Object.keys(e);for(o=0;o<i.length;o++)n=i[o],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(o=0;o<i.length;o++)n=i[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var c=a.a.createContext({}),p=function(e){var t=a.a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):r(r({},t),e)),n},u=function(e){var t=p(e.components);return a.a.createElement(c.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},d=a.a.forwardRef((function(e,t){var n=e.components,o=e.mdxType,i=e.originalType,l=e.parentName,c=s(e,["components","mdxType","originalType","parentName"]),u=p(n),d=o,h=u["".concat(l,".").concat(d)]||u[d]||b[d]||i;return n?a.a.createElement(h,r(r({ref:t},c),{},{components:n})):a.a.createElement(h,r({ref:t},c))}));function h(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var i=n.length,l=new Array(i);l[0]=d;var r={};for(var s in t)hasOwnProperty.call(t,s)&&(r[s]=t[s]);r.originalType=e,r.mdxType="string"==typeof e?e:o,l[1]=r;for(var c=2;c<i;c++)l[c]=n[c];return a.a.createElement.apply(null,l)}return a.a.createElement.apply(null,n)}d.displayName="MDXCreateElement"},95:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return l})),n.d(t,"metadata",(function(){return r})),n.d(t,"rightToc",(function(){return s})),n.d(t,"default",(function(){return p}));var o=n(2),a=n(6),i=(n(0),n(100)),l={id:"bare_metal_install",title:"NetSage Flow Processing Pipeline Installation Guide",sidebar_label:"Server Installation Guide"},r={unversionedId:"deploy/bare_metal_install",id:"deploy/bare_metal_install",isDocsHomePage:!1,title:"NetSage Flow Processing Pipeline Installation Guide",description:"This document covers installing the NetSage Flow Processing Pipeline on a new machine. Steps should be followed below in order unless you know for sure what you are doing. This document assumes a RedHat Linux environment or one of its derivatives.",source:"@site/docs/deploy/bare_metal_install.md",slug:"/deploy/bare_metal_install",permalink:"/netsage-pipeline/docs/next/deploy/bare_metal_install",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/docs/deploy/bare_metal_install.md",version:"current",sidebar_label:"Server Installation Guide",sidebar:"Pipeline",previous:{title:"Choosing Install",permalink:"/netsage-pipeline/docs/next/deploy/choose_install"},next:{title:"Docker Default Installation Guide",permalink:"/netsage-pipeline/docs/next/deploy/docker_install_simple"}},s=[{value:"Data sources",id:"data-sources",children:[]},{value:"Installing the Prerequisites",id:"installing-the-prerequisites",children:[{value:"Installing nfdump",id:"installing-nfdump",children:[]},{value:"Installing RabbitMQ",id:"installing-rabbitmq",children:[]},{value:"Installing the EPEL repo",id:"installing-the-epel-repo",children:[]},{value:"Installing the GlobalNOC Open Source repo",id:"installing-the-globalnoc-open-source-repo",children:[]}]},{value:"Installing the Pipeline (Importer and Logstash)",id:"installing-the-pipeline-importer-and-logstash",children:[]},{value:"Importer Configuration",id:"importer-configuration",children:[{value:"Setting up the shared config file",id:"setting-up-the-shared-config-file",children:[]},{value:"Setting up the Importer config file",id:"setting-up-the-importer-config-file",children:[]}]},{value:"Logstash Setup Notes",id:"logstash-setup-notes",children:[]},{value:"Start Logstash",id:"start-logstash",children:[]},{value:"Start the Importer",id:"start-the-importer",children:[]},{value:"Cron jobs",id:"cron-jobs",children:[]}],c={rightToc:s};function p(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(i.b)("wrapper",Object(o.a)({},c,n,{components:t,mdxType:"MDXLayout"}),Object(i.b)("p",null,"This document covers installing the NetSage Flow Processing Pipeline on a new machine. Steps should be followed below in order unless you know for sure what you are doing. This document assumes a RedHat Linux environment or one of its derivatives."),Object(i.b)("h2",{id:"data-sources"},"Data sources"),Object(i.b)("p",null,"The Processing pipeline needs data to ingest in order to do anything. There are two types of data that can be consumed."),Object(i.b)("ol",null,Object(i.b)("li",{parentName:"ol"},"sflow or netflow"),Object(i.b)("li",{parentName:"ol"},"tstat")),Object(i.b)("p",null,"At least one of these must be set up on a sensor to provide the incoming flow data."),Object(i.b)("p",null,"Sflow and netflow data should be sent to ports on the pipeline host where nfcapd and/or sfcapd are ready to receive it."),Object(i.b)("p",null,"Tstat data should be sent directly to the logstash input RabbitMQ queue (the same one that the Importer writes to, if it is used). From there, the data will be processed the same as sflow/netflow data."),Object(i.b)("h2",{id:"installing-the-prerequisites"},"Installing the Prerequisites"),Object(i.b)("h3",{id:"installing-nfdump"},"Installing nfdump"),Object(i.b)("p",null,"Sflow and netflow data and the NetFlow Importer use nfdump tools. If you are only collecting tstat data, you do not need nfdump. "),Object(i.b)("p",null,"nfdump is ",Object(i.b)("em",{parentName:"p"},"not")," listed as a dependency of the Pipeline RPM package, as in a lot cases people are running special builds of nfdump -- but make sure you install it before you try running the Netflow Importer. If in doubt, ",Object(i.b)("inlineCode",{parentName:"p"},"yum install nfdump")," should work. Flow data exported by some routers require a newer version of nfdump than the one in the CentOS repos; in these cases, it may be necessary to manually compile and install the lastest nfdump."),Object(i.b)("h3",{id:"installing-rabbitmq"},"Installing RabbitMQ"),Object(i.b)("p",null,"The pipeline requires a RabbitMQ server. Typically, this runs on the same server as the pipeline itself, but if need be, you can separate them (for this reason, the Rabbit server is not automatically installed with the pipeline package)."),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{className:"language-sh"}),"[root@host ~]# yum install rabbitmq-server\n\n")),Object(i.b)("p",null,"Typically, the default configuration will work. Perform any desired Rabbit configuration, then, start RabbitMQ:"),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{className:"language-sh"}),"[root@host ~]# /sbin/service rabbitmq-server start \n          or # systemctl start rabbitmq-server.service\n")),Object(i.b)("h3",{id:"installing-the-epel-repo"},"Installing the EPEL repo"),Object(i.b)("p",null,"Some of our dependencies come from the EPEL repo. To install this:"),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{}),"[root@host ~]# yum install epel-release\n")),Object(i.b)("h3",{id:"installing-the-globalnoc-open-source-repo"},"Installing the GlobalNOC Open Source repo"),Object(i.b)("p",null,"The Pipeline package (and its dependencies that are not in EPEL) are in the GlobalNOC Open Source Repo."),Object(i.b)("p",null,"For Red Hat/CentOS 6, create ",Object(i.b)("inlineCode",{parentName:"p"},"/etc/yum.repos.d/grnoc6.repo")," with the following content."),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{}),"[grnoc6]\nname=GlobalNOC Public el6 Packages - $basearch\nbaseurl=https://repo-public.grnoc.iu.edu/repo/6/$basearch\nenabled=1\ngpgcheck=1\ngpgkey=https://repo-public.grnoc.iu.edu/repo/RPM-GPG-KEY-GRNOC6\n")),Object(i.b)("p",null,"For Red Hat/CentOS 7, create ",Object(i.b)("inlineCode",{parentName:"p"},"/etc/yum.repos.d/grnoc7.repo")," with the following content."),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{}),"[grnoc7]\nname=GlobalNOC Public el7 Packages - $basearch\nbaseurl=https://repo-public.grnoc.iu.edu/repo/7/$basearch\nenabled=1\ngpgcheck=1\ngpgkey=https://repo-public.grnoc.iu.edu/repo/RPM-GPG-KEY-GRNOC7\n")),Object(i.b)("p",null,"The first time you install packages from the repo, you will have to accept the GlobalNOC repo key."),Object(i.b)("h2",{id:"installing-the-pipeline-importer-and-logstash"},"Installing the Pipeline (Importer and Logstash)"),Object(i.b)("p",null,"Install it like this:"),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{}),"[root@host ~]# yum install grnoc-netsage-deidentifier\n")),Object(i.b)("p",null,"Pipeline components:"),Object(i.b)("ol",null,Object(i.b)("li",{parentName:"ol"},"Flow Filter - GlobalNOC uses this for Cenic data to filter out some flows. Not needed otherwise."),Object(i.b)("li",{parentName:"ol"},"Netsage Netflow Importer - required to read nfcapd files from sflow and netflow importers. (If using tstat flow sensors only, this is not needed.)"),Object(i.b)("li",{parentName:"ol"},"Logstash - be sure the number of logstash pipeline workers is set to 1 (if you have removed the aggregation logstash conf).!"),Object(i.b)("li",{parentName:"ol"},"Logstash configs - these are executed in alphabetical order.  See the Logstash doc.")),Object(i.b)("p",null,"Nothing will automatically start after installation as we need to move on to configuration. "),Object(i.b)("h2",{id:"importer-configuration"},"Importer Configuration"),Object(i.b)("p",null,"Configuration files of interest are"),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"/etc/grnoc/netsage/deidentifier/netsage_shared.xml - Shared config file allowing configuration of collections, and Rabbit connection information"),Object(i.b)("li",{parentName:"ul"},"/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml - other settings"),Object(i.b)("li",{parentName:"ul"},"/etc/grnoc/netsage/deidentifier/logging.conf - logging config"),Object(i.b)("li",{parentName:"ul"},"/etc/grnoc/netsage/deidentifier/logging-debug.conf - logging config with debug enabled")),Object(i.b)("h3",{id:"setting-up-the-shared-config-file"},"Setting up the shared config file"),Object(i.b)("p",null,Object(i.b)("inlineCode",{parentName:"p"},"/etc/grnoc/netsage/deidentifier/netsage_shared.xml")),Object(i.b)("p",null,"There used to be many perl-based pipeline components and daemons. At this point, only the importer is left, the rest having been replaced by logstash.  The shared config file, which was formerly used by all the perl components, is read before reading the individual importer config file."),Object(i.b)("p",null,"The most important part of the shared configuration file is the definition of collections. Each sflow or netflow sensor will have its own collection stanza. Here is one such stanza, a netflow example. Instance and router-address can be left commented out."),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{}),'<collection>\n     \x3c!-- Top level directory of the nfcapd files for this sensor (within this dir are normally year directories, etc.) --\x3e\n         <flow-path>/path/to/netflow-files/</flow-path>\n\n     \x3c!-- Sensor name - can be the hostname or any string you like --\x3e\n         <sensor>Netflow Sensor 1d</sensor>\n\n     \x3c!-- Flow type - sflow or netflow (defaults to netflow) --\x3e\n         <flow-type>netflow</flow-type>\n\n     \x3c!-- "instance" goes along with sensor.  This is to identify various instances if a sensor has --\x3e\n     \x3c!-- more than one "stream" / data collection.  Defaults to 0. --\x3e\n     \x3c!-- <instance>1</instance> --\x3e\n\n     \x3c!-- Used in Flow-Filter. Defaults to sensor, but you can set it to something else here --\x3e\n     \x3c!-- <router-address></router-address> --\x3e\n</collection>\n')),Object(i.b)("p",null,"Having multiple collections in one importer can sometimes cause issues for aggregation, as looping through the collections one at a time adds to the time between the flows, affecting timeouts. You can also set up multiple Importers with differently named shared and importer config files and separate init.d files. "),Object(i.b)("p",null,"There is also RabbitMQ connection information in the shared config, though queue names are set in the Importer config. (The Importer does not read from a rabbit queue, but other old components did, so both input and output are set.) "),Object(i.b)("p",null,"Ideally, flows should be deidentified before they leave the host on which the data is stored. If flows that have not be deidentified need to be pushed to another node for some reason, the Rabbit connection must be encrypted with SSL."),Object(i.b)("p",null,"If you're running a default RabbitMQ config, which is open only to 'localhost' as guest/guest, you won't need to change anything here."),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{}),"  \x3c!-- rabbitmq connection info --\x3e\n  <rabbit_input>\n    <host>127.0.0.1</host>\n    <port>5672</port>\n    <username>guest</username>\n    <password>guest</password>\n    <ssl>0</ssl>\n    <batch_size>100</batch_size>\n    <vhost>/</vhost>\n    <durable>1</durable> \x3c!-- Whether the rabbit queue is 'durable' (don't change this unless you have a reason) --\x3e\n  </rabbit_input>\n\n  <rabbit_output>\n    <host>127.0.0.1</host>\n    <port>5672</port>\n    <username>guest</username>\n    <password>guest</password>\n    <ssl>0</ssl>\n    <batch_size>100</batch_size>\n    <vhost>/</vhost>\n    <durable>1</durable> \x3c!-- Whether the rabbit queue is 'durable' (don't change this unless you have a reason) --\x3e\n  </rabbit_output>\n")),Object(i.b)("h3",{id:"setting-up-the-importer-config-file"},"Setting up the Importer config file"),Object(i.b)("p",null,Object(i.b)("inlineCode",{parentName:"p"},"/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml")),Object(i.b)("p",null,"This file has a few more setting specific to the Importer component which you may like to adjust.  "),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"Rabbit_output has the name of the output queue. This should be the same as that of the logstash input queue.  "),Object(i.b)("li",{parentName:"ul"},'(The Importer does not actually use an input rabbit queue, so we add a "fake" one here.)'),Object(i.b)("li",{parentName:"ul"},"Min-bytes is a threshold applied to flows aggregated within one nfcapd file. Flows smaller than this will be discarded."),Object(i.b)("li",{parentName:"ul"},"Min-file-age is used to be sure files are complete before being read. "),Object(i.b)("li",{parentName:"ul"},"Cull-enable and cull-ttl can be used to have nfcapd files older than some number of days automatically deleted. "),Object(i.b)("li",{parentName:"ul"},"Pid-file is where the pid file should be written. Be sure this matches what is used in the init.d file."),Object(i.b)("li",{parentName:"ul"},"Keep num-processes set to 1.")),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{className:"language-xml"}),'<config>\n  \x3c!--  NOTE: Values here override those in the shared config --\x3e\n\n  \x3c!-- rabbitmq queues --\x3e\n  <rabbit_input>\n    <queue>netsage_deidentifier_netflow_fake</queue>\n    <channel>2</channel>\n  </rabbit_input>\n\n  <rabbit_output>\n    <channel>3</channel>\n    <queue>netsage_deidentifier_raw</queue>\n  </rabbit_output>\n\n  <worker>\n    \x3c!-- How many flows to process at once --\x3e\n        <flow-batch-size>100</flow-batch-size>\n\n    \x3c!-- How many concurrent workers should perform the necessary operations --\x3e\n        <num-processes>1</num-processes>\n\n    \x3c!-- path to nfdump executable (defaults to /usr/bin/nfdump) --\x3e\n    \x3c!--   <nfdump-path>/path/to/nfdump</nfdump-path>  --\x3e\n\n    \x3c!-- Where to store the cache, where it tracks what files it has/hasn\'t read --\x3e\n        <cache-file>/var/cache/netsage/netflow_importer.cache</cache-file>\n\n    \x3c!-- The minium flow size threshold - will not  import any flows smaller than this --\x3e\n    \x3c!-- Defaults to 500M  --\x3e\n        <min-bytes>100000000</min-bytes> \n\n    \x3c!-- Do not import nfcapd files younger than min-file-age\n        The value must match /^(\\d+)([DWMYhms])$/ where D, W, M, Y, h, m and s are\n        "day(s)", "week(s)", "month(s)", "year(s)", "hour(s)", "minute(s)" and "second(s)", respectively"\n        See http://search.cpan.org/~pfig/File-Find-Rule-Age-0.2/lib/File/Find/Rule/Age.pm\n        Default: 0 (no minimum age) \n    --\x3e\n        <min-file-age>10m</min-file-age> \n\n    \x3c!-- cull-enable: whether to cull processed flow data files --\x3e\n    \x3c!-- default: no culling; set to 1 to turn culling on --\x3e\n    \x3c!--    <cull-enable>1</cull-enable>  --\x3e\n\n    \x3c!-- cull-tty: cull time to live, in days --\x3e\n    \x3c!-- number of days to retain imported data files before deleting them; default: 3 --\x3e\n    \x3c!--    <cull-ttl>5</cull-ttl>  --\x3e\n  </worker>\n\n  <master>\n    \x3c!-- where should we write the daemon pid file to --\x3e\n        <pid-file>/var/run/netsage-netflow-importer-daemon.pid</pid-file>\n  </master>\n\n</config>\n')),Object(i.b)("h2",{id:"logstash-setup-notes"},"Logstash Setup Notes"),Object(i.b)("p",null,"Standard logstash filter config files are provided with this package. Most should be used as-is, but the input and output configs may be modified for your use."),Object(i.b)("p",null,"The aggregation filter also has settings that may be changed as well - check the two timeouts and the aggregation maps path. "),Object(i.b)("p",null,"When upgrading, these logstash configs will not be overwritten. Be sure any changes get copied into the production configs."),Object(i.b)("p",null,'FOR FLOW STITCHING/AGGREGATION - IMPORTANT!\nFlow stitching (ie, aggregation) will NOT work properly with more than ONE logstash pipeline worker!\nBe sure to set "pipeline.workers: 1" in /etc/logstash/logstash.yml and/or /etc/logstash/pipelines.yml. When running logstash on the command line, use "-w 1".'),Object(i.b)("h2",{id:"start-logstash"},"Start Logstash"),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{className:"language-sh"}),"[root@host ~]# /sbin/service logstash start \n          or # systemctl start logstash.service\n")),Object(i.b)("p",null,"It will take couple minutes to start. Log files are normally /var/log/messages and /var/log/logstash/logstash-plain.log."),Object(i.b)("p",null,'When logstash is stopped, any flows currently "in the aggregator" will be written out to /tmp/logstash-aggregation-maps (or the path/file set in 40-aggregation.conf). These will be read in and deleted when logstash is started again. '),Object(i.b)("h2",{id:"start-the-importer"},"Start the Importer"),Object(i.b)("p",null,"Typically, the daemons are started and stopped via init script (CentOS 6) or systemd (CentOS 7). They can also be run manually. The daemons all support these flags:"),Object(i.b)("p",null,Object(i.b)("inlineCode",{parentName:"p"},"--config [file]")," - specify which config file to read"),Object(i.b)("p",null,Object(i.b)("inlineCode",{parentName:"p"},"--sharedconfig [file]")," - specify which shared config file to read"),Object(i.b)("p",null,Object(i.b)("inlineCode",{parentName:"p"},"--logging [file]")," - the logging config"),Object(i.b)("p",null,Object(i.b)("inlineCode",{parentName:"p"},"--nofork")," - run in foreground (do not daemonize)"),Object(i.b)("pre",null,Object(i.b)("code",Object(o.a)({parentName:"pre"},{className:"language-sh"}),"[root@host ~]# /sbin/service netsage-netflow-importer start \n          or # systemctl start netsage-netflow-importer.service\n")),Object(i.b)("p",null,"The Importer will create a deamon process and a worker process. When stopping the service, the worker process might take a few minutes to quit. If it does not quit, kill it by hand. "),Object(i.b)("h2",{id:"cron-jobs"},"Cron jobs"),Object(i.b)("p",null,"Sample cron files are provided. Please review and uncomment their contents. These periodically download MaxMind, CAIDA, and Science Registry files, and also restart logstash daily. Logstash needs to be restarted in order for any updated files to be read in. "))}p.isMDXComponent=!0}}]);