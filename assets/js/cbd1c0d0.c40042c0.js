(window.webpackJsonp=window.webpackJsonp||[]).push([[79],{150:function(e,t,a){"use strict";a.r(t),a.d(t,"frontMatter",(function(){return i})),a.d(t,"metadata",(function(){return s})),a.d(t,"toc",(function(){return l})),a.d(t,"default",(function(){return d}));var n=a(3),o=a(7),r=(a(0),a(171)),i={id:"docker_install_advanced",title:"Docker Advanced Installation Guide",sidebar_label:"Docker Advanced"},s={unversionedId:"deploy/docker_install_advanced",id:"deploy/docker_install_advanced",isDocsHomePage:!1,title:"Docker Advanced Installation Guide",description:"If the Docker Simple installation does not meet your needs, the following customizations will allow for more complex situations.",source:"@site/docs/deploy/docker_install_advanced.md",slug:"/deploy/docker_install_advanced",permalink:"/netsage-pipeline/docs/next/deploy/docker_install_advanced",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/docs/deploy/docker_install_advanced.md",version:"current",sidebar_label:"Docker Advanced",sidebar:"Pipeline",previous:{title:"Docker Default Installation Guide",permalink:"/netsage-pipeline/docs/next/deploy/docker_install_simple"},next:{title:"Docker Troubleshooting",permalink:"/netsage-pipeline/docs/next/deploy/docker_troubleshoot"}},l=[{value:"To Add an Additional Sflow or Netflow Collector",id:"to-add-an-additional-sflow-or-netflow-collector",children:[{value:"1. Edit docker-compose.override.yml",id:"1-edit-docker-composeoverrideyml",children:[]},{value:"2.  Edit netsage_override.xml",id:"2--edit-netsage_overridexml",children:[]},{value:"3. Edit environment file",id:"3-edit-environment-file",children:[]},{value:"Running the new collector",id:"running-the-new-collector",children:[]}]},{value:"To Change a Sensor Name Depending on the Interface Used",id:"to-change-a-sensor-name-depending-on-the-interface-used",children:[]}],c={toc:l};function d(e){var t=e.components,a=Object(o.a)(e,["components"]);return Object(r.b)("wrapper",Object(n.a)({},c,a,{components:t,mdxType:"MDXLayout"}),Object(r.b)("p",null,"If the Docker Simple installation does not meet your needs, the following customizations will allow for more complex situations."),Object(r.b)("p",null,Object(r.b)("em",{parentName:"p"},"Please first read the Docker Simple installation guide in detail. This guide will build on top of that.")),Object(r.b)("h2",{id:"to-add-an-additional-sflow-or-netflow-collector"},"To Add an Additional Sflow or Netflow Collector"),Object(r.b)("p",null,"If you have more than 1 sflow and/or 1 netflow sensor, you will need to create more collectors and modify the importer config file. The following instructions describe the steps needed to add one additional sensor."),Object(r.b)("p",null,"Any number of sensors can be accomodated, although if there are more than a few being processed by the same Importer, you may run into issues where long-lasting flows from sensosr A time out in the aggregation step while waiting for flows from sensors B to D to be processed. (Another option might be be to run more than one Docker deployment.) "),Object(r.b)("h3",{id:"1-edit-docker-composeoverrideyml"},"1. Edit docker-compose.override.yml"),Object(r.b)("p",null,"The pattern to add a flow collector is always the same. To add an sflow collector called example-collector, edit the docker-compose.override.yml file and add"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-yaml"},'  example-collector:\n    image: netsage/nfdump-collector:1.6.18\n    restart: always\n    command: sfcapd -T all -l /data -S 1 -w -z -p 9997\n    volumes:\n      - ./data/input_data/example:/data\n    ports:\n      - "9997:9997/udp"\n')),Object(r.b)("ul",null,Object(r.b)("li",{parentName:"ul"},'collector-name: should be updated to something that has some meaning, in our example "example-collector".'),Object(r.b)("li",{parentName:"ul"},"command: choose between sfcapd for sflow and nfcapd for netflow, and at the end of the command, specify the port to watch for incoming flow data.  (Unless your flow exporter is already set up to use a different port, you can use the default ports and configure the exporters on the routers to match.)"),Object(r.b)("li",{parentName:"ul"},"ports: make sure the port here matches the port you've set in the command. Naturally all ports have to be unique for this host and the\nrouter should be configured to export data to the same port. (If the port on your docker container is different than the port on your host/local machine, use container_port:host_port.) "),Object(r.b)("li",{parentName:"ul"},"volumes: specify where to write the nfcapd files. Make sure the path is unique and in ./data/. In this case, we're writing to ./data/input_data/example. Change the last part of the path to something meaningful.")),Object(r.b)("p",null,"You will also need to uncomment these lines: "),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-yaml"},"  volumes:\n     - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml\n")),Object(r.b)("h3",{id:"2--edit-netsage_overridexml"},"2.  Edit netsage_override.xml"),Object(r.b)("p",null,"To make the Pipeline Importer aware of the new data to process, you will need to create a custom Importer configuration: netsage_override.xml.  This will replace the usual config file netsage_shared.xml. "),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"cp compose/importer/netsage_shared.xml userConfig/netsage_override.xml\n")),Object(r.b)("p",null,'Edit netsage_override.xml and add a "collection" section for the new sensor as in the following example. The flow-path should match the path set above in docker-compose.override.yml. $exampleSensorName is a new "variable"; it will be replaced with a value set in the .env file. For the flow-type, enter "sflow" or "netflow" as appropriate.'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-xml"},"    <collection>\n        <flow-path>/data/input_data/example/</flow-path>\n        <sensor>$exampleSensorName</sensor>\n        <flow-type>sflow</flow-type>\n    </collection>\n")),Object(r.b)("h3",{id:"3-edit-environment-file"},"3. Edit environment file"),Object(r.b)("p",null,'Then, in the .env file, add a line that sets a value for the "variable" you referenced above, $exampleSensorName. The value is the name of the sensor which will be saved to elasticsearch and which appears in Netsage Dashboards. Set it to something meaningful and unique.'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-ini"},"exampleSensorName=Example New York sFlow\n")),Object(r.b)("h3",{id:"running-the-new-collector"},"Running the new collector"),Object(r.b)("p",null,"After doing the setup above and selecting the docker version to run, you can start the new collector by running the following line, using the collector name (or by running ",Object(r.b)("inlineCode",{parentName:"p"},"docker-compose up -d")," to start up all containers):"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose up -d example-collector\n")),Object(r.b)("div",{className:"admonition admonition-note alert alert--secondary"},Object(r.b)("div",{parentName:"div",className:"admonition-heading"},Object(r.b)("h5",{parentName:"div"},Object(r.b)("span",{parentName:"h5",className:"admonition-icon"},Object(r.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},Object(r.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M6.3 5.69a.942.942 0 0 1-.28-.7c0-.28.09-.52.28-.7.19-.18.42-.28.7-.28.28 0 .52.09.7.28.18.19.28.42.28.7 0 .28-.09.52-.28.7a1 1 0 0 1-.7.3c-.28 0-.52-.11-.7-.3zM8 7.99c-.02-.25-.11-.48-.31-.69-.2-.19-.42-.3-.69-.31H6c-.27.02-.48.13-.69.31-.2.2-.3.44-.31.69h1v3c.02.27.11.5.31.69.2.2.42.31.69.31h1c.27 0 .48-.11.69-.31.2-.19.3-.42.31-.69H8V7.98v.01zM7 2.3c-3.14 0-5.7 2.54-5.7 5.68 0 3.14 2.56 5.7 5.7 5.7s5.7-2.55 5.7-5.7c0-3.15-2.56-5.69-5.7-5.69v.01zM7 .98c3.86 0 7 3.14 7 7s-3.14 7-7 7-7-3.12-7-7 3.14-7 7-7z"}))),"note")),Object(r.b)("div",{parentName:"div",className:"admonition-content"},Object(r.b)("p",{parentName:"div"},"The default version of the collector is 1.6.18. There are other versions released and :latest should be point to the latest one, but there is no particular effort made to make sure we released the latest version. You can get a listing of all the current tags listed ",Object(r.b)("a",{parentName:"p",href:"https://hub.docker.com/r/netsage/nfdump-collector/tags"},"here")," and the source to generate the docker image can be found ",Object(r.b)("a",{parentName:"p",href:"https://github.com/netsage-project/docker-nfdump-collector"},"here")," the code for the You may use a different version though there is no particular effort to have an image for every nfdump release."))),Object(r.b)("h2",{id:"to-change-a-sensor-name-depending-on-the-interface-used"},"To Change a Sensor Name Depending on the Interface Used"),Object(r.b)("p",null,"In some cases, users want to differentiate between flows that enter or exit through specific sensor interfaces. This can be done by editing the env file."),Object(r.b)("p",null,'In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 4 fields are set properly! For example,'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"ifindex_sensor_rename_flag=True\nifindex_sensor_rename_old_name=IU Sflow \nifindex_sensor_rename_new_name=IU Bloomington Sflow\nifindex_sensor_rename_ifindex=10032\n")),Object(r.b)("p",null,'In this case, any flows through interface 10032 (src_ifindex = 10032 OR dst_ifindex = 10032) will have the sensor name (sensor_id) changed from "IU Sflow" to "IU Bloomington Sflow". Currently, only one such rename can be configured in Docker.'),Object(r.b)("div",{className:"admonition admonition-note alert alert--secondary"},Object(r.b)("div",{parentName:"div",className:"admonition-heading"},Object(r.b)("h5",{parentName:"div"},Object(r.b)("span",{parentName:"h5",className:"admonition-icon"},Object(r.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},Object(r.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M6.3 5.69a.942.942 0 0 1-.28-.7c0-.28.09-.52.28-.7.19-.18.42-.28.7-.28.28 0 .52.09.7.28.18.19.28.42.28.7 0 .28-.09.52-.28.7a1 1 0 0 1-.7.3c-.28 0-.52-.11-.7-.3zM8 7.99c-.02-.25-.11-.48-.31-.69-.2-.19-.42-.3-.69-.31H6c-.27.02-.48.13-.69.31-.2.2-.3.44-.31.69h1v3c.02.27.11.5.31.69.2.2.42.31.69.31h1c.27 0 .48-.11.69-.31.2-.19.3-.42.31-.69H8V7.98v.01zM7 2.3c-3.14 0-5.7 2.54-5.7 5.68 0 3.14 2.56 5.7 5.7 5.7s5.7-2.55 5.7-5.7c0-3.15-2.56-5.69-5.7-5.69v.01zM7 .98c3.86 0 7 3.14 7 7s-3.14 7-7 7-7-3.12-7-7 3.14-7 7-7z"}))),"note")),Object(r.b)("div",{parentName:"div",className:"admonition-content"},Object(r.b)("p",{parentName:"div"},"Please notify the devs at IU in advance, if you need to modify a sensor name, because the regexes used for determining sensor_group and sensor_type may have to be updated."),Object(r.b)("h2",{parentName:"div",id:"to-do-sampling-rate-corrections-in-logstash"},"To Do Sampling Rate Corrections in Logstash"),Object(r.b)("p",{parentName:"div"},"When flow sampling is done, the number of bits needs to be corrected for the sampling rate. For example, if you are sampling 1 out of 100 flows and a sample has 55 MB, it is assumed that in reality there would be 100 flows of that size (with that src and dst), so the number of bits is multiplied by 100. Usually the collector (nfcapd or sfcapd process) gets the sampling rate from the incoming data and applies the correction, but in some cases, the sensor may not send the sampling rate, or there may be a complex set-up that requires a manual correction. With netflow, a manual correction can be applied using the '-s' option in the nfsen config or the nfcapd command. For sflow, there is no such option. In either case, the correction can be made in logstash as follows."),Object(r.b)("p",{parentName:"div"},'In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 3 fields are set properly! The same correction can be applied to multiple sensors by using a comma-separed list. For example,'),Object(r.b)("pre",{parentName:"div"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"sampling_correction_flag=True\nsampling_correction_sensors=IU Bloomington Sflow, IU Sflow\nsampling_correction_factor=512\n")),Object(r.b)("h2",{parentName:"div",id:"to-change-how-long-nfcapd-files-are-kept"},"To Change How Long Nfcapd Files Are Kept"),Object(r.b)("p",{parentName:"div"},"The importer will automatically delete older nfcapd files for you, so that your disk don't fill up. By default, 3 days worth of files will be kept. This can be adjusted by making a netsage_override.xml file:"),Object(r.b)("pre",{parentName:"div"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"cp compose/importer/netsage_shared.xml userConfig/netsage_override.xml\n")),Object(r.b)("p",{parentName:"div"},"At the bottom of the file, edit this section to set the number of days worth of files to keep. Set cull-enable to 0 for no culling. Eg, to save 7 days worth of data:"),Object(r.b)("pre",{parentName:"div"},Object(r.b)("code",{parentName:"pre",className:"language-xml"},"  <worker>\n    <cull-enable>1</cull-enable>\n    <cull-ttl>7</cull-ttl>\n  </worker>\n")),Object(r.b)("p",{parentName:"div"},"You will also need to uncomment these lines in docker-compose.override.yml: "),Object(r.b)("pre",{parentName:"div"},Object(r.b)("code",{parentName:"pre",className:"language-yaml"},"  volumes:\n     - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml\n")),Object(r.b)("h2",{parentName:"div",id:"to-process-tstat-data"},"To Process Tstat Data"),Object(r.b)("p",{parentName:"div"},'Tstat data is not collected by nfdump/sfcapd/nfcapd or read by an Importer. Instead, the flow data is sent directly from the router or switch to the logstash pipeline\'s ingest rabbit queue (named "netsage_deidentifier_raw").  So, when following the Docker Simple guide, the sections related to configuring and starting up the collectors and Importer will not pertain to the tstat sensors. The .env file still needs to be set up though.'),Object(r.b)("p",{parentName:"div"},"Setting up Tstat is outside the scope of this document, but see the Netsage project Tstat-Transport which contains client programs that can send tstat data to a rabbit queue. See ",Object(r.b)("a",{parentName:"p",href:"https://github.com/netsage-project/tstat-transport.git"},"https://github.com/netsage-project/tstat-transport.git"),". Basically, you need to have Tstat send data directly to the same rabbit queue that the importers write sflow and netflow data to and that the logstash pipeline reads from."),Object(r.b)("h2",{parentName:"div",id:"to-customize-java-settings--increase-memory-available-for-lostash"},"To Customize Java Settings / Increase Memory Available for Lostash"),Object(r.b)("p",{parentName:"div"},"If you need to modify the amount of memory logstash can use or any other java settings,\nrename the provided example for JVM Options and tweak the settings as desired."),Object(r.b)("pre",{parentName:"div"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"cp userConfig/jvm.options_example userConfig/jvm.options\n")),Object(r.b)("p",{parentName:"div"},"Also update the docker-compose.override.xml file to uncomment lines in the logstash section. It should look something like this:"),Object(r.b)("pre",{parentName:"div"},Object(r.b)("code",{parentName:"pre",className:"language-yaml"},"logstash:\n  image: netsage/pipeline_logstash:latest\n  volumes:\n    - ./userConfig/jvm.options:/usr/share/logstash/config/jvm.options\n")),Object(r.b)("p",{parentName:"div"},"Here are some tips for adjusting the JVM heap size (",Object(r.b)("a",{parentName:"p",href:"https://www.elastic.co/guide/en/logstash/current/jvm-settings.html"},"https://www.elastic.co/guide/en/logstash/current/jvm-settings.html"),"):"),Object(r.b)("ul",{parentName:"div"},Object(r.b)("li",{parentName:"ul"},"The recommended heap size for typical ingestion scenarios should be no less than 4GB and no more than 8GB."),Object(r.b)("li",{parentName:"ul"},"CPU utilization can increase unnecessarily if the heap size is too low, resulting in the JVM constantly garbage collecting. You can check for this issue by doubling the heap size to see if performance improves."),Object(r.b)("li",{parentName:"ul"},"Do not increase the heap size past the amount of physical memory. Some memory must be left to run the OS and other processes. As a general guideline for most installations, don\u2019t exceed 50-75% of physical memory. The more memory you have, the higher percentage you can use."),Object(r.b)("li",{parentName:"ul"},"Set the minimum (Xms) and maximum (Xmx) heap allocation size to the same value to prevent the heap from resizing at runtime, which is a very costly process.")),Object(r.b)("h2",{parentName:"div",id:"to-bring-up-kibana-and-elasticsearch-containers"},"To Bring up Kibana and Elasticsearch Containers"),Object(r.b)("p",{parentName:"div"},"The file docker-compose.develop.yaml can be used in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components."),Object(r.b)("p",{parentName:"div"},"This isn't a production pattern but the tools can be useful at times. Please refer to the ",Object(r.b)("a",{parentName:"p",href:"../devel/docker_dev_guide#optional-elasticsearch-and-kibana"},"Docker Dev Guide")),Object(r.b)("h2",{parentName:"div",id:"for-data-saved-to-an-nfs-volume"},"For Data Saved to an NFS Volume"),Object(r.b)("p",{parentName:"div"},"By default, data is saved to subdirectories in the ./data directory.  If you would like to use an NFS mount instead you will need to either"),Object(r.b)("ol",{parentName:"div"},Object(r.b)("li",{parentName:"ol"},"export the NFS volume as ${PROJECT_DIR}/data (which is the idea scenario and least intrusive)"),Object(r.b)("li",{parentName:"ol"},"update the path to the NFS export path in all locations in docker-compose.yml and docker-compose.override.yml")),Object(r.b)("p",{parentName:"div"},"Note: modifying all the paths in the two files should work, but may not. In one case, it worked to modify only the paths for the collector volumes (eg, - /mnt/nfs/netsagedata/netflow:/data), leaving all others with their default values."))),Object(r.b)("p",null,"If you choose to update the docker-compose file, keep in mind that those changes will cause a merge conflict on upgrade.\nYou'll have to manage the volumes exported and ensure all the paths are updated correctly for the next release manually.\n:::"))}d.isMDXComponent=!0},171:function(e,t,a){"use strict";a.d(t,"a",(function(){return p})),a.d(t,"b",(function(){return u}));var n=a(0),o=a.n(n);function r(e,t,a){return t in e?Object.defineProperty(e,t,{value:a,enumerable:!0,configurable:!0,writable:!0}):e[t]=a,e}function i(e,t){var a=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),a.push.apply(a,n)}return a}function s(e){for(var t=1;t<arguments.length;t++){var a=null!=arguments[t]?arguments[t]:{};t%2?i(Object(a),!0).forEach((function(t){r(e,t,a[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(a)):i(Object(a)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(a,t))}))}return e}function l(e,t){if(null==e)return{};var a,n,o=function(e,t){if(null==e)return{};var a,n,o={},r=Object.keys(e);for(n=0;n<r.length;n++)a=r[n],t.indexOf(a)>=0||(o[a]=e[a]);return o}(e,t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);for(n=0;n<r.length;n++)a=r[n],t.indexOf(a)>=0||Object.prototype.propertyIsEnumerable.call(e,a)&&(o[a]=e[a])}return o}var c=o.a.createContext({}),d=function(e){var t=o.a.useContext(c),a=t;return e&&(a="function"==typeof e?e(t):s(s({},t),e)),a},p=function(e){var t=d(e.components);return o.a.createElement(c.Provider,{value:t},e.children)},m={inlineCode:"code",wrapper:function(e){var t=e.children;return o.a.createElement(o.a.Fragment,{},t)}},h=o.a.forwardRef((function(e,t){var a=e.components,n=e.mdxType,r=e.originalType,i=e.parentName,c=l(e,["components","mdxType","originalType","parentName"]),p=d(a),h=n,u=p["".concat(i,".").concat(h)]||p[h]||m[h]||r;return a?o.a.createElement(u,s(s({ref:t},c),{},{components:a})):o.a.createElement(u,s({ref:t},c))}));function u(e,t){var a=arguments,n=t&&t.mdxType;if("string"==typeof e||n){var r=a.length,i=new Array(r);i[0]=h;var s={};for(var l in t)hasOwnProperty.call(t,l)&&(s[l]=t[l]);s.originalType=e,s.mdxType="string"==typeof e?e:n,i[1]=s;for(var c=2;c<r;c++)i[c]=a[c];return o.a.createElement.apply(null,i)}return o.a.createElement.apply(null,a)}h.displayName="MDXCreateElement"}}]);