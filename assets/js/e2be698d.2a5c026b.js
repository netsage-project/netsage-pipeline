(window.webpackJsonp=window.webpackJsonp||[]).push([[91],{162:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return s})),n.d(t,"metadata",(function(){return r})),n.d(t,"toc",(function(){return l})),n.d(t,"default",(function(){return p}));var o=n(3),i=n(7),a=(n(0),n(171)),s={id:"install",title:"NetSage Flow Processing Pipeline Install Guide",sidebar_label:"Installation Guide"},r={unversionedId:"deploy/install",id:"version-1.2.6/deploy/install",isDocsHomePage:!1,title:"NetSage Flow Processing Pipeline Install Guide",description:"This document covers installing the NetSage Flow Processing Pipeline on a new machine. Steps should be followed below in order unless you know for sure what you are doing. This document assumes a RedHat Linux environment or one of its derivatives.",source:"@site/versioned_docs/version-1.2.6/deploy/install.md",slug:"/deploy/install",permalink:"/netsage-pipeline/docs/1.2.6/deploy/install",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/versioned_docs/version-1.2.6/deploy/install.md",version:"1.2.6",sidebar_label:"Installation Guide",sidebar:"version-1.2.6/Pipeline",previous:{title:"Choosing Install",permalink:"/netsage-pipeline/docs/1.2.6/deploy/choose_install"},next:{title:"Docker Installation Guide",permalink:"/netsage-pipeline/docs/1.2.6/deploy/docker_install"}},l=[{value:"Components",id:"components",children:[]},{value:"Prerequirements",id:"prerequirements",children:[{value:"nfdump",id:"nfdump",children:[]}]},{value:"Installing the Prerequisites",id:"installing-the-prerequisites",children:[{value:"RabbitMQ",id:"rabbitmq",children:[]},{value:"Installing the EPEL repo",id:"installing-the-epel-repo",children:[]},{value:"Installing the GlobalNOC Open Source repo",id:"installing-the-globalnoc-open-source-repo",children:[]}]},{value:"Installing the Pipeline",id:"installing-the-pipeline",children:[]},{value:"Configuration",id:"configuration",children:[{value:"Setting up the shared config file",id:"setting-up-the-shared-config-file",children:[]},{value:"Configuring the Pipeline Stages",id:"configuring-the-pipeline-stages",children:[]},{value:"Shared config file listing",id:"shared-config-file-listing",children:[]}]},{value:"Running the daemons",id:"running-the-daemons",children:[{value:"Daemon Listing",id:"daemon-listing",children:[]}]},{value:"Setup Notes",id:"setup-notes",children:[]}],c={toc:l};function p(e){var t=e.components,n=Object(i.a)(e,["components"]);return Object(a.b)("wrapper",Object(o.a)({},c,n,{components:t,mdxType:"MDXLayout"}),Object(a.b)("p",null,"This document covers installing the NetSage Flow Processing Pipeline on a new machine. Steps should be followed below in order unless you know for sure what you are doing. This document assumes a RedHat Linux environment or one of its derivatives."),Object(a.b)("h2",{id:"components"},"Components"),Object(a.b)("p",null,"Minimum components"),Object(a.b)("ul",null,Object(a.b)("li",{parentName:"ul"},"Data Injestion Source (nfdump, tstat or both)"),Object(a.b)("li",{parentName:"ul"},"RabbitMQ"),Object(a.b)("li",{parentName:"ul"},"LogStash"),Object(a.b)("li",{parentName:"ul"},"Importer (If you use nfdump)")),Object(a.b)("h2",{id:"prerequirements"},"Prerequirements"),Object(a.b)("p",null,"The Processing pipeline needs data to injest in order to do anything.  There are two types of data that are consumed."),Object(a.b)("ol",null,Object(a.b)("li",{parentName:"ol"},"nfdump "),Object(a.b)("li",{parentName:"ol"},"tstat")),Object(a.b)("p",null,"You'll need to have at least one of them setup in order to be able to process the data"),Object(a.b)("h3",{id:"nfdump"},"nfdump"),Object(a.b)("p",null,"The NetFlow Importer daemon requires nfdump. If you are only using tstat, you do not need nfdump. nfdump is ",Object(a.b)("em",{parentName:"p"},"not")," listed as a dependency of the Pipeline RPM package, as in a lot cases people are running special builds of nfdump -- but make sure you install it before you try running the Netflow Importer. If in doubt, ",Object(a.b)("inlineCode",{parentName:"p"},"yum install nfdump")," should work. Flow data exported by some routers require a newer version of nfdump than the one in the CentOS repos; in these cases, it may be necessary to manually compile and install the lastest nfdump."),Object(a.b)("p",null,"Once nfdump is setup you'll need to configures your routers to send nfdump to the running process that will save data to a particular location on disk. "),Object(a.b)("h2",{id:"installing-the-prerequisites"},"Installing the Prerequisites"),Object(a.b)("h3",{id:"rabbitmq"},"RabbitMQ"),Object(a.b)("p",null,"The pipeline requires a RabbitMQ server. Typically, this runs on the same server as the pipeline itself, but if need be, you can separate them (for this reason, the Rabbit server is not automatically installed with the pipeline package)."),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-sh"},"[root@host ~]# yum install rabbitmq-server\n`\n\n")),Object(a.b)("p",null,"Typically, the default configuration will work. Perform any desired Rabbit configuration, if any. Then, start RabbitMQ:"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-sh"},"[root@host ~]# /sbin/service rabbitmq-server start or # systemctl start rabbitmq-server.service\n")),Object(a.b)("h3",{id:"installing-the-epel-repo"},"Installing the EPEL repo"),Object(a.b)("p",null,"Some of our dependencies come from the EPEL repo. To install this:"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"[root@host ~]# yum install epel-release\n")),Object(a.b)("h3",{id:"installing-the-globalnoc-open-source-repo"},"Installing the GlobalNOC Open Source repo"),Object(a.b)("p",null,"The Pipeline package (and its dependencies that are not in EPEL) are in the GlobalNOC Open Source Repo."),Object(a.b)("p",null,"For Red Hat/CentOS 6, create ",Object(a.b)("inlineCode",{parentName:"p"},"/etc/yum.repos.d/grnoc6.repo")," with the following content."),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"[grnoc6]\nname=GlobalNOC Public el6 Packages - $basearch\nbaseurl=https://repo-public.grnoc.iu.edu/repo/6/$basearch\nenabled=1\ngpgcheck=1\ngpgkey=https://repo-public.grnoc.iu.edu/repo/RPM-GPG-KEY-GRNOC6\n")),Object(a.b)("p",null,"For Red Hat/CentOS 7, create ",Object(a.b)("inlineCode",{parentName:"p"},"/etc/yum.repos.d/grnoc7.repo")," with the following content."),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"[grnoc7]\nname=GlobalNOC Public el7 Packages - $basearch\nbaseurl=https://repo-public.grnoc.iu.edu/repo/7/$basearch\nenabled=1\ngpgcheck=1\ngpgkey=https://repo-public.grnoc.iu.edu/repo/RPM-GPG-KEY-GRNOC7\n")),Object(a.b)("p",null,"The first time you install packages from the repo, you will have to accept the GlobalNOC repo key."),Object(a.b)("h2",{id:"installing-the-pipeline"},"Installing the Pipeline"),Object(a.b)("p",null,"Pipeline components:"),Object(a.b)("ol",null,Object(a.b)("li",{parentName:"ol"},"Flow Filter - GlobalNOC uses this for Cenic data as we do not want to process all of it. Not needed otherwise."),Object(a.b)("li",{parentName:"ol"},"Netflow Importer - required to read nfcapd files from sflow and netflow importers. (If using tstat flow sensors, have them")),Object(a.b)("p",null,"send directly to the appropriate rabbit queue. "),Object(a.b)("ol",{start:3},Object(a.b)("li",{parentName:"ol"},"Logstash configs - These are executed in alphabetical order. They read events from a rabbit queue, aggregate (ie stitch flows ")),Object(a.b)("p",null,"that were split between different nfcapd files), add information from geoIP and Science Registry data, and write to a final rabbit queue.\nThe final rabbit queue is read by an independent logstash instance and events are put into elasticsearch. One could also modify the\nlast logstash conf here to write to elasticsearch."),Object(a.b)("p",null,"Nothing will automatically start after installation as we need to move on to configuration. Install it like this:"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"[root@host ~]# yum install grnoc-netsage-deidentifier\n")),Object(a.b)("h2",{id:"configuration"},"Configuration"),Object(a.b)("h3",{id:"setting-up-the-shared-config-file"},"Setting up the shared config file"),Object(a.b)("p",null,"Theshared config file, used by all the non-logstash pipeline components, is read before reading the individual config files ","[THERE USED TO BE MANY DAEMONS INSTEAD OF LOGSTASH. We should redo this]",". This allows you to easily configure values that apply to all stages, while allowing you to override them in the individual config files, if desired. A default shared config file is included: ",Object(a.b)("inlineCode",{parentName:"p"},"/etc/grnoc/netsage/deidentifier/netsage_shared.xml")," "),Object(a.b)("p",null,"The first, and most important, part of the configuration is the collection(s) this host will import. These are defined as follows:"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},'<collection>\n    <flow-path>/path/to/flow-files</flow-path>\n    <sensor>hostname.tld</sensor>\n\x3c!--  "instance" goes along with sensor\n       This is to identify various instances if a sensor has more than one "stream" / data collection\n       Defaults to 0.\n    <instance>1</instance>\n--\x3e\n  \x3c!--\n       Defaults to sensor, but you can set it to something else here\n      <router-address></router-address>\n  --\x3e\n \x3c!--\n    Flow type: type of flow data (defaults to netflow)\n --\x3e\n \x3c!--\n    <flow-type>sflow</flow-type>\n --\x3e\n</collection>\n')),Object(a.b)("p",null,"Notice that ",Object(a.b)("inlineCode",{parentName:"p"},"instance")," , ",Object(a.b)("inlineCode",{parentName:"p"},"router-address")," , and ",Object(a.b)("inlineCode",{parentName:"p"},"flow-type")," are commented out. You only need these if you need an something other than the default values, as described in the comments in the default shared config file."),Object(a.b)("p",null,"You can have multiple ",Object(a.b)("inlineCode",{parentName:"p"},"collection")," stanzas, to import multiple collections on one host."),Object(a.b)("p",null,"The shared config looks like this. Note that RabbitMQ connection information is listed, but not the queue or channel, as these will vary per daemon. If you're running a default RabbitMQ config, which is open only to 'localhost' as guest/guest, you won't need to change anything here. Note that you will need to change the rabbit_output for the Finished Flow Mover Daemon regardless (see below)."),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"<config>\n  <collection>\n    <flow-path>/path/to/flow-files1</flow-path>\n    <sensor>hostname1.tld</sensor>\n  </collection>\n  <collection>\n    <flow-path>/path/to/flow-files2</flow-path>\n    <sensor>hostname2.tld</sensor>\n  </collection>\n\n  \x3c!-- rabbitmq connection info --\x3e\n  <rabbit_input>\n    <host>127.0.0.1</host>\n    <port>5671</port>\n    <username>guest</username>\n    <password>guest</password>\n    <batch_size>100</batch_size>\n    <vhost>netsage</vhost>\n    <ssl>0</ssl>\n    <cacert>/path/to/cert.crt</cacert> \x3c!-- required if ssl is 1 --\x3e\n  </rabbit_input>\n\n  \x3c!-- The cache does not output to a rabbit queue (shared memory instead) but we still need something here --\x3e\n  <rabbit_output>\n    <host>127.0.0.1</host>\n    <port>5671</port>\n    <username>guest</username>\n    <password>guest</password>\n    <batch_size>100</batch_size>\n    <vhost>netsage</vhost>\n    <ssl>0</ssl>\n    <cacert>/path/to/cert.crt</cacert> \x3c!-- required if ssl is 1 --\x3e\n  </rabbit_output>\n</config>\n")),Object(a.b)("h3",{id:"configuring-the-pipeline-stages"},"Configuring the Pipeline Stages"),Object(a.b)("p",null,"Each stage must be configured with Rabbit input and output queue information. The intention here is that flows should be deidentified before they leave the original node the flow data is collected on. If flows that have not be deidentified need to be pushed to another node for some reason, the Rabbit connection must be encrypted with SSL."),Object(a.b)("p",null,'The username/password are both set to "guest" by default, as this is the default provided by RabbitMQ. This works fine if the localhost is processing all the data. The configs look something like this (some have additional sections).'),Object(a.b)("p",null,"Notice that the only Rabbit connection information that's provided here is that which is not specific in the shared config file. This way if we need to change the credentials throughout the entire pipeline, it's easy to do."),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-xml"},"   <config>\n     \x3c!-- rabbitmq connection info --\x3e\n     <rabbit_input>\n       <queue>netsage_deidentifier_raw</queue>\n       <channel>2</channel>\n     </rabbit_input>\n   \n     \x3c!-- The cache does not output to a rabbit queue (shared memory instead) but we still need something here --\x3e\n     <rabbit_output>\n       <queue>netsage_deidentifier_cached</queue>\n       <channel>3</channel>\n     </rabbit_output>\n     <worker>\n         \x3c!-- How many concurrent workers should perform the necessary operations --\x3e\n         \x3c!-- for stitching, we can only use 1 --\x3e\n       <num-processes>1</num-processes>\n   \n       \x3c!-- where should we write the cache worker pid file to --\x3e\n       <pid-file>/var/run/netsage-cache-workers.pid</pid-file>\n   \n     </worker>\n   </config>\n")),Object(a.b)("p",null,"The defaults should work unless the pipeline stages need to be reordered for some reason, or if SSL or different hosts/credentials are needed. However, the very endpoints should be checked. At the moment that means the flow cache (which is the first stage in the pipeline) and the flow mover (the last stage)."),Object(a.b)("h3",{id:"shared-config-file-listing"},"Shared config file listing"),Object(a.b)("p",null,"The shared configuration files and logging configuration files are listed below (all of the pipeline components use these):"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"/etc/grnoc/netsage/deidentifier/netsage_shared.xml - Shared config file allowing configuration of collections, and Rabbit connection information\n/etc/grnoc/netsage/deidentifier/logging.conf - logging config\n/etc/grnoc/netsage/deidentifier/logging-debug.conf - logging config with debug enabled\n")),Object(a.b)("h2",{id:"running-the-daemons"},"Running the daemons"),Object(a.b)("p",null,"Typically, the daemons are started and stopped via init script (CentOS 6) or systemd (CentOS 7). They can also be run manually. The daemons all support these flags:"),Object(a.b)("p",null,Object(a.b)("inlineCode",{parentName:"p"},"--config [file]")," - specify which config file to read"),Object(a.b)("p",null,Object(a.b)("inlineCode",{parentName:"p"},"--sharedconfig [file]")," - specify which shared config file to read"),Object(a.b)("p",null,Object(a.b)("inlineCode",{parentName:"p"},"--logging [file]")," - the logging config"),Object(a.b)("p",null,Object(a.b)("inlineCode",{parentName:"p"},"--nofork")," - run in foreground (do not daemonize)"),Object(a.b)("p",null,"For more details on each individual daemon, use the ",Object(a.b)("inlineCode",{parentName:"p"},"--help")," flag."),Object(a.b)("h3",{id:"daemon-listing"},"Daemon Listing"),Object(a.b)("h4",{id:"netsage-netflow-importer-daemon"},"netsage-netflow-importer-daemon"),Object(a.b)("p",null,"This is a daemon that reads raw netflow data, reads it, and pushes it to a Rabbit queue for processing."),Object(a.b)("p",null,"Config file: ",Object(a.b)("inlineCode",{parentName:"p"},"/etc/grnoc/netsage/deidentifier/netsage_netflow_importer.xml")," "),Object(a.b)("h2",{id:"setup-notes"},"Setup Notes"),Object(a.b)("p",null,"INPUT AND OUTPUT LOGSTASH FILTERS\nStandard logstash filter config files are provided with this package. Most should be used as-is, but the input and output configs (01-inputs.conf and 99-outputs.conf) may be modified for your use.\nTo use the provided 01-inputs.conf and 99-outputs.conf versions, fill in the IP of the final rabbit host in 99-outputs.conf, and put the rabbitmq usernames and passwords into the logstash keystore.\nYour 01 and 99 conf files should not be overwritten by upgrades."),Object(a.b)("p",null,"To set up the keystore:  (note that logstash-keystore takes a minute to come back with a prompt)\nBe sure /usr/share/logstash/config exists\n(the full path, in case you need it: /usr/share/logstash/bin/logstash-keystore)\nCreate logstash.keystore in /etc/logstash/: (use the same directory as logstash.yml)"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-sh"},"  $ sudo -E logstash-keystore --path.settings /etc/logstash/ create\n    You can set a password for the keystore itself if you want to investigate that; otherwise skip it.\n  $ sudo -E logstash-keystore --path.settings /etc/logstash/ add rabbitmq_input_username     (enter username when prompted)\n  $ sudo -E logstash-keystore --path.settings /etc/logstash/ add rabbitmq_input_pw           (enter password when prompted)\n  $ sudo -E logstash-keystore --path.settings /etc/logstash/ add rabbitmq_output_username    (enter username when prompted)\n  $ sudo -E logstash-keystore --path.settings /etc/logstash/ add rabbitmq_output_pw          (enter password when prompted)\n```sh\nTo list the keys:\n")),Object(a.b)("p",null,"  $ sudo -E logstash-keystore list"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-sh"},"To remove a key-value pair:\n\n```sh\n  $ sudo -E logstash-keystore remove <key name>\n")),Object(a.b)("p",null,'FLOW STITCHING - IMPORTANT!\nFlow stitching (ie, aggregation) will NOT work properly with more than ONE logstash pipeline worker!\nBe sure to set "pipeline.workers: 1" in /etc/logstash/logstash.yml (default settingss) and/or /etc/logstash/pipelines.yml (settings take precedence). When running logstash on the command line, use "-w 1".'),Object(a.b)("p",null,"See the comments in 04-stitching.conf to learn more about how complete flows are defined."))}p.isMDXComponent=!0},171:function(e,t,n){"use strict";n.d(t,"a",(function(){return u})),n.d(t,"b",(function(){return b}));var o=n(0),i=n.n(o);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function s(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function r(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?s(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):s(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,o,i=function(e,t){if(null==e)return{};var n,o,i={},a=Object.keys(e);for(o=0;o<a.length;o++)n=a[o],t.indexOf(n)>=0||(i[n]=e[n]);return i}(e,t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(o=0;o<a.length;o++)n=a[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(i[n]=e[n])}return i}var c=i.a.createContext({}),p=function(e){var t=i.a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):r(r({},t),e)),n},u=function(e){var t=p(e.components);return i.a.createElement(c.Provider,{value:t},e.children)},d={inlineCode:"code",wrapper:function(e){var t=e.children;return i.a.createElement(i.a.Fragment,{},t)}},h=i.a.forwardRef((function(e,t){var n=e.components,o=e.mdxType,a=e.originalType,s=e.parentName,c=l(e,["components","mdxType","originalType","parentName"]),u=p(n),h=o,b=u["".concat(s,".").concat(h)]||u[h]||d[h]||a;return n?i.a.createElement(b,r(r({ref:t},c),{},{components:n})):i.a.createElement(b,r({ref:t},c))}));function b(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var a=n.length,s=new Array(a);s[0]=h;var r={};for(var l in t)hasOwnProperty.call(t,l)&&(r[l]=t[l]);r.originalType=e,r.mdxType="string"==typeof e?e:o,s[1]=r;for(var c=2;c<a;c++)s[c]=n[c];return i.a.createElement.apply(null,s)}return i.a.createElement.apply(null,n)}h.displayName="MDXCreateElement"}}]);