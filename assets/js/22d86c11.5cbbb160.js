(window.webpackJsonp=window.webpackJsonp||[]).push([[21],{212:function(e,t,n){"use strict";n.d(t,"a",(function(){return p})),n.d(t,"b",(function(){return h}));var o=n(0),a=n.n(o);function r(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){r(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function s(e,t){if(null==e)return{};var n,o,a=function(e,t){if(null==e)return{};var n,o,a={},r=Object.keys(e);for(o=0;o<r.length;o++)n=r[o],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);for(o=0;o<r.length;o++)n=r[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var c=a.a.createContext({}),d=function(e){var t=a.a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},p=function(e){var t=d(e.components);return a.a.createElement(c.Provider,{value:t},e.children)},m={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},u=a.a.forwardRef((function(e,t){var n=e.components,o=e.mdxType,r=e.originalType,i=e.parentName,c=s(e,["components","mdxType","originalType","parentName"]),p=d(n),u=o,h=p["".concat(i,".").concat(u)]||p[u]||m[u]||r;return n?a.a.createElement(h,l(l({ref:t},c),{},{components:n})):a.a.createElement(h,l({ref:t},c))}));function h(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var r=n.length,i=new Array(r);i[0]=u;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l.mdxType="string"==typeof e?e:o,i[1]=l;for(var c=2;c<r;c++)i[c]=n[c];return a.a.createElement.apply(null,i)}return a.a.createElement.apply(null,n)}u.displayName="MDXCreateElement"},91:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return i})),n.d(t,"metadata",(function(){return l})),n.d(t,"toc",(function(){return s})),n.d(t,"default",(function(){return d}));var o=n(3),a=n(7),r=(n(0),n(212)),i={id:"docker_install_advanced",title:"Docker Advanced Options Guide",sidebar_label:"Docker Advanced Options"},l={unversionedId:"deploy/docker_install_advanced",id:"version-1.2.11/deploy/docker_install_advanced",isDocsHomePage:!1,title:"Docker Advanced Options Guide",description:"If the basic Docker Installation does not meet your needs, the following customizations will allow for more complex situations. Find the section(s) which apply to you.",source:"@site/versioned_docs/version-1.2.11/deploy/docker_install_advanced.md",slug:"/deploy/docker_install_advanced",permalink:"/netsage-pipeline/docs/deploy/docker_install_advanced",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/versioned_docs/version-1.2.11/deploy/docker_install_advanced.md",version:"1.2.11",sidebar_label:"Docker Advanced Options",sidebar:"version-1.2.11/Pipeline",previous:{title:"Docker Installation Guide",permalink:"/netsage-pipeline/docs/deploy/docker_install_simple"},next:{title:"Upgrading",permalink:"/netsage-pipeline/docs/deploy/docker_upgrade"}},s=[{value:"To Add an Additional Sflow or Netflow Collector",id:"to-add-an-additional-sflow-or-netflow-collector",children:[]},{value:"To Keep Only Flows From Certain Interfaces",id:"to-keep-only-flows-from-certain-interfaces",children:[]},{value:"To Change a Sensor Name Depending on the Interface Used",id:"to-change-a-sensor-name-depending-on-the-interface-used",children:[]},{value:"To Do Sampling Rate Corrections in Logstash",id:"to-do-sampling-rate-corrections-in-logstash",children:[]},{value:"To Change How Long Nfcapd Files Are Kept",id:"to-change-how-long-nfcapd-files-are-kept",children:[]},{value:"To Save Flow Data to a Different Location",id:"to-save-flow-data-to-a-different-location",children:[]},{value:"To Customize Java Settings / Increase Memory Available for Lostash",id:"to-customize-java-settings--increase-memory-available-for-lostash",children:[]},{value:"To Bring up Kibana and Elasticsearch Containers",id:"to-bring-up-kibana-and-elasticsearch-containers",children:[]}],c={toc:s};function d(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(r.b)("wrapper",Object(o.a)({},c,n,{components:t,mdxType:"MDXLayout"}),Object(r.b)("p",null,"If the basic Docker Installation does not meet your needs, the following customizations will allow for more complex situations. Find the section(s) which apply to you."),Object(r.b)("p",null,Object(r.b)("em",{parentName:"p"},"Please first read the Docker Installation guide in detail. This guide will build on top of that.")),Object(r.b)("h2",{id:"to-add-an-additional-sflow-or-netflow-collector"},"To Add an Additional Sflow or Netflow Collector"),Object(r.b)("p",null,"If you have more than 1 sflow and/or 1 netflow sensor, you will need to create more collectors and modify the importer config file. The following instructions describe the steps needed to add one additional sensor."),Object(r.b)("p",null,"Any number of sensors can be accomodated, although if there are more than a few being processed by the same Importer, you may run into issues where long-lasting flows from sensosr A time out in the aggregation step while waiting for flows from sensors B to D to be processed. (Another option might be be to run more than one Docker deployment.) "),Object(r.b)("h4",{id:"a-edit-docker-composeoverrideyml"},"a. Edit docker-compose.override.yml"),Object(r.b)("p",null,"The pattern to add a flow collector is always the same. To add an sflow collector called example-collector, edit the docker-compose.override.yml file and add something like"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-yaml"},'  example-collector:\n    image: netsage/nfdump-collector:alpine-1.6.23\n    restart: always\n    command: sfcapd -T all -l /data -S 1 -w -z -p 9997\n    volumes:\n      - ./data/input_data/example:/data\n    ports:\n      - "9997:9997/udp"\n')),Object(r.b)("ul",null,Object(r.b)("li",{parentName:"ul"},'collector name: should be updated to something that has some meaning, in our example "example-collector".'),Object(r.b)("li",{parentName:"ul"},"image: copy from the default collector sections already in the file. "),Object(r.b)("li",{parentName:"ul"},'command: choose between "sfcapd" for sflow and "nfcapd" for netflow, and at the end of the command, specify the port to watch for incoming flow data.  '),Object(r.b)("li",{parentName:"ul"},'volumes: specify where to write the nfcapd files. Make sure the path is unique and in ./data/. In this case, we\'re writing to ./data/input_data/example. Change "example" to something meaningful.'),Object(r.b)("li",{parentName:"ul"},"ports: make sure the port here matches the port you've set in the command. Naturally all ports have to be unique for this host and the router should be configured to export data to the same port. (?? If the port on your docker container is different than the port on your host/local machine, use container_port:host_port.) ")),Object(r.b)("p",null,"Make sure the indentation is right or you'll get an error about yaml parsing."),Object(r.b)("p",null,"You will also need to uncomment these lines: "),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-yaml"},"  volumes:\n     - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml\n")),Object(r.b)("h4",{id:"b--edit-netsage_overridexml"},"b.  Edit netsage_override.xml"),Object(r.b)("p",null,"To make the Pipeline Importer aware of the new data to process, you will need to create a custom Importer configuration: netsage_override.xml.  This will replace the usual config file netsage_shared.xml. "),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"cp compose/importer/netsage_shared.xml userConfig/netsage_override.xml\n")),Object(r.b)("p",null,'Edit netsage_override.xml and add a new "collection" section for the new sensor as in the following example. The flow-path should match the path set above in docker-compose.override.yml. $exampleSensorName is a new "variable"; don\'t replace it here, it will be replaced with a value that you set in the .env file. For the flow-type, enter "sflow" or "netflow" as appropriate. (Enter "netflow" if you\'re running IPFIX.)'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-xml"},"    <collection>\n        <flow-path>/data/input_data/example/</flow-path>\n        <sensor>$exampleSensorName</sensor>\n        <flow-type>sflow</flow-type>\n    </collection>\n")),Object(r.b)("h4",{id:"c-edit-environment-file"},"c. Edit environment file"),Object(r.b)("p",null,'Then, in the .env file, add a line that sets a value for the "variable" you referenced above, $exampleSensorName. The value is the name of the sensor which will be saved to elasticsearch and which appears in Netsage Dashboards. Set it to something meaningful and unique. E.g.,'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-ini"},"exampleSensorName=MyNet Los Angeles sFlow\n")),Object(r.b)("h4",{id:"d-running-the-new-collector"},"d. Running the new collector"),Object(r.b)("p",null,"After doing the setup above and selecting the docker version to run, you can start the new collector by running the following line, using the collector name (or by running ",Object(r.b)("inlineCode",{parentName:"p"},"docker-compose up -d")," to start up all containers):"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose up -d example-collector\n")),Object(r.b)("h2",{id:"to-keep-only-flows-from-certain-interfaces"},"To Keep Only Flows From Certain Interfaces"),Object(r.b)("p",null,"If your sensors are exporting all flows, but only those using a particular interface are relevant, use this option in the .env file. The collectors and importer will save/read all incoming flows, but the logstash pipeline will drop those that do not have src_ifindex OR dst_inindex equal to one of those listed. "),Object(r.b)("p",null,"In the .env file, uncomment lines in the appropriate section and enter the information required. Be sure ",Object(r.b)("inlineCode",{parentName:"p"},"ifindex_filter_flag=True"),' with "True" capitalized as shown, any sensor names are spelled exactly right, and list all the ifindex values of flows that should be kept and processed. Some examples (use just one!):'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"ifindex_filter_keep=123\nifindex_filter_keep=123,456\nifindex_filter_keep=Sensor 1: 789\nifindex_filter_keep=123; Sensor 1: 789; Sensor 2: 800, 900\n")),Object(r.b)("p",null,"In the first case, all flows that have src_ifindex = 123 or dst_ifindex = 123 will be kept, regardless of sensor name. (Note that this may be a problem if you have more than 1 sensor with the same ifindex values!)\nIn the 2nd case, if src or dst ifindex is 123 or 456, the flow will be processed.\nIn the 3rd case, only flows from Sensor 1 will be filtered, with flows using ifindex 789 kept.\nIn the last example, any flow with ifindex 123 will be kept. Sensor 1 flows with ifindex 789 (or 123) will be kept, and those from Sensor 2 having ifindex 800 or 900 (or 123) will be kept.  "),Object(r.b)("p",null,"Spaces don't matter except within the sensor names. Punctuation is required as shown."),Object(r.b)("h2",{id:"to-change-a-sensor-name-depending-on-the-interface-used"},"To Change a Sensor Name Depending on the Interface Used"),Object(r.b)("p",null,"In some cases, users want to keep all flows from a certain sensor but differentiate between those that enter or exit through specific sensor interfaces. This can be done by using this option in the .env file."),Object(r.b)("p",null,'In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 4 fields are set properly! For example,'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"ifindex_sensor_rename_flag=True\nifindex_sensor_rename_old_name=IU Sflow \nifindex_sensor_rename_new_name=IU Bloomington Sflow\nifindex_sensor_rename_ifindex=10032\n")),Object(r.b)("p",null,'In this case, any flows from the "IU Sflow" sensor that use interface 10032 (src_ifindex = 10032 OR dst_ifindex = 10032) will have the sensor name changed from "IU Sflow" to "IU Bloomington Sflow". Currently, only one such rename can be configured in Docker and only 1 ifindex is allowed.'),Object(r.b)("div",{className:"admonition admonition-note alert alert--secondary"},Object(r.b)("div",{parentName:"div",className:"admonition-heading"},Object(r.b)("h5",{parentName:"div"},Object(r.b)("span",{parentName:"h5",className:"admonition-icon"},Object(r.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},Object(r.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M6.3 5.69a.942.942 0 0 1-.28-.7c0-.28.09-.52.28-.7.19-.18.42-.28.7-.28.28 0 .52.09.7.28.18.19.28.42.28.7 0 .28-.09.52-.28.7a1 1 0 0 1-.7.3c-.28 0-.52-.11-.7-.3zM8 7.99c-.02-.25-.11-.48-.31-.69-.2-.19-.42-.3-.69-.31H6c-.27.02-.48.13-.69.31-.2.2-.3.44-.31.69h1v3c.02.27.11.5.31.69.2.2.42.31.69.31h1c.27 0 .48-.11.69-.31.2-.19.3-.42.31-.69H8V7.98v.01zM7 2.3c-3.14 0-5.7 2.54-5.7 5.68 0 3.14 2.56 5.7 5.7 5.7s5.7-2.55 5.7-5.7c0-3.15-2.56-5.69-5.7-5.69v.01zM7 .98c3.86 0 7 3.14 7 7s-3.14 7-7 7-7-3.12-7-7 3.14-7 7-7z"}))),"note")),Object(r.b)("div",{parentName:"div",className:"admonition-content"},Object(r.b)("p",{parentName:"div"},"Please notify the devs at IU in advance, if you need to modify a sensor name, because the regexes used for determining sensor_group and sensor_type may have to be updated."))),Object(r.b)("h2",{id:"to-do-sampling-rate-corrections-in-logstash"},"To Do Sampling Rate Corrections in Logstash"),Object(r.b)("p",null,"When flow sampling is done, corrections have to be applied. For example, if you are sampling 1 out of 100 flows, for each flow measured, it is assumed that in reality there would be 100 flows of that size with that src and dst, so the number of bits (and the number of packets, bits/s and packets/s) is multiplied by 100. Usually the collector (nfcapd or sfcapd process) gets the sampling rate from the incoming data and applies the correction, but in some cases, the sensor may not send the sampling rate, or there may be a complex set-up that requires a manual correction. With netflow, a manual correction can be applied using the '-s' option in the nfsen config, if nfsen is being used, or the nfcapd command, but this is not convenient when using Docker. For sflow, there is no such option. In either case, the correction can be made in logstash as follows."),Object(r.b)("p",null,'In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 3 fields are set properly! The same correction can be applied to multiple sensors by using a comma-separed list. The same correction applies to all listed sensors. For example,'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"sampling_correction_flag=True\nsampling_correction_sensors=IU Bloomington Sflow, IU Sflow\nsampling_correction_factor=512\n")),Object(r.b)("h2",{id:"to-change-how-long-nfcapd-files-are-kept"},"To Change How Long Nfcapd Files Are Kept"),Object(r.b)("p",null,"The importer will automatically delete older nfcapd files for you, so that your disk doesn't fill up. By default, 3 days worth of files will be kept. This can be adjusted by making a netsage_override.xml file:"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"cp compose/importer/netsage_shared.xml userConfig/netsage_override.xml\n")),Object(r.b)("p",null,"At the bottom of the file, edit this section to set the number of days worth of files to keep. Set cull-enable to 0 for no culling. Eg, to save 1 days worth of data:"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-xml"},"  <worker>\n    <cull-enable>1</cull-enable>\n    <cull-ttl>1</cull-ttl>\n  </worker>\n")),Object(r.b)("p",null,"You will also need to uncomment these lines in docker-compose.override.yml: "),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-yaml"},"  volumes:\n     - ./userConfig/netsage_override.xml:/etc/grnoc/netsage/deidentifier/netsage_shared.xml\n")),Object(r.b)("h2",{id:"to-save-flow-data-to-a-different-location"},"To Save Flow Data to a Different Location"),Object(r.b)("p",null,"By default, data is saved to subdirectories in the ./data/ directory (ie, the data/ directory in the git checkout).  If you would like to use a different location, there are two options."),Object(r.b)("ol",null,Object(r.b)("li",{parentName:"ol"},"The best solution is to create a symlink between ./data/ and the preferred location, or, for an NFS volume, export it as ${PROJECT_DIR}/data.")),Object(r.b)("p",null,"During installation, delete the data/ directory (it should only contain .placeholder), then create your symlink. Eg, to use /var/netsage/ instead of data/, "),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"cd {netsage-pipeline dir}\nmkdir /var/netsage\nrm data/.placeholder\nrmdir data\nln -s /var/netsage {netsage-pipeline dir}/data\n")),Object(r.b)("p",null,"(Check the permissions of the directory.)"),Object(r.b)("ol",{start:2},Object(r.b)("li",{parentName:"ol"},"Alternatively, update volumes in docker-compose.yml and docker-compose.override.yml Eg, to save nfcapd files to subdirs in /mydir, set the collector volumes to ",Object(r.b)("inlineCode",{parentName:"li"},"- /mydir/input_data/netflow:/data")," (similarly for sflow) and set the importer and logstash volumes to ",Object(r.b)("inlineCode",{parentName:"li"},"- /mydir:/data"),". ")),Object(r.b)("div",{className:"admonition admonition-warning alert alert--danger"},Object(r.b)("div",{parentName:"div",className:"admonition-heading"},Object(r.b)("h5",{parentName:"div"},Object(r.b)("span",{parentName:"h5",className:"admonition-icon"},Object(r.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"12",height:"16",viewBox:"0 0 12 16"},Object(r.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M5.05.31c.81 2.17.41 3.38-.52 4.31C3.55 5.67 1.98 6.45.9 7.98c-1.45 2.05-1.7 6.53 3.53 7.7-2.2-1.16-2.67-4.52-.3-6.61-.61 2.03.53 3.33 1.94 2.86 1.39-.47 2.3.53 2.27 1.67-.02.78-.31 1.44-1.13 1.81 3.42-.59 4.78-3.42 4.78-5.56 0-2.84-2.53-3.22-1.25-5.61-1.52.13-2.03 1.13-1.89 2.75.09 1.08-1.02 1.8-1.86 1.33-.67-.41-.66-1.19-.06-1.78C8.18 5.31 8.68 2.45 5.05.32L5.03.3l.02.01z"}))),"warning")),Object(r.b)("div",{parentName:"div",className:"admonition-content"},Object(r.b)("p",{parentName:"div"},"If you choose to update the docker-compose file, keep in mind that those changes will cause a merge conflict or be wiped out on upgrade.\nYou'll have to manage the volumes exported and ensure all the paths are updated correctly for the next release manually."))),Object(r.b)("h2",{id:"to-customize-java-settings--increase-memory-available-for-lostash"},"To Customize Java Settings / Increase Memory Available for Lostash"),Object(r.b)("p",null,"If cpu or memory seems to be a problem, try increasing the JVM heap size for logstash from 2GB to 3 or 4, no more than 8."),Object(r.b)("p",null,"To do this, edit LS_JAVA_OPTS in the .env file. ","[is this working??]"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-yaml"},"LS_JAVA_OPTS=-Xmx4g -Xms4g\n")),Object(r.b)("p",null,"Here are some tips for adjusting the JVM heap size (",Object(r.b)("a",{parentName:"p",href:"https://www.elastic.co/guide/en/logstash/current/jvm-settings.html"},"https://www.elastic.co/guide/en/logstash/current/jvm-settings.html"),"):"),Object(r.b)("ul",null,Object(r.b)("li",{parentName:"ul"},"Set the minimum (Xms) and maximum (Xmx) heap allocation size to the same value to prevent the heap from resizing at runtime, which is a very costly process."),Object(r.b)("li",{parentName:"ul"},"CPU utilization can increase unnecessarily if the heap size is too low, resulting in the JVM constantly garbage collecting. You can check for this issue by doubling the heap size to see if performance improves."),Object(r.b)("li",{parentName:"ul"},"Do not increase the heap size past the amount of physical memory. Some memory must be left to run the OS and other processes. As a general guideline for most installations, don\u2019t exceed 50-75% of physical memory. The more memory you have, the higher percentage you can use.")),Object(r.b)("p",null,"To modify other logstash settings, rename the provided example file for JVM Options and tweak the settings as desired:"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"cp userConfig/jvm.options_example userConfig/jvm.options\n")),Object(r.b)("p",null,"Also update the docker-compose.override.xml file to uncomment lines in the logstash section. It should look something like this: "),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-yaml"},"logstash:\n  image: netsage/pipeline_logstash:latest\n  volumes:\n    - ./userConfig/jvm.options:/usr/share/logstash/config/jvm.options\n")),Object(r.b)("h2",{id:"to-bring-up-kibana-and-elasticsearch-containers"},"To Bring up Kibana and Elasticsearch Containers"),Object(r.b)("p",null,"The file docker-compose.develop.yaml can be used in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components."),Object(r.b)("p",null,"This isn't a production pattern but the tools can be useful at times. Please refer to the ",Object(r.b)("a",{parentName:"p",href:"../devel/docker_dev_guide#optional-elasticsearch-and-kibana"},"Docker Dev Guide")))}d.isMDXComponent=!0}}]);