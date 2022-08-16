(window.webpackJsonp=window.webpackJsonp||[]).push([[104],{175:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return i})),n.d(t,"metadata",(function(){return s})),n.d(t,"toc",(function(){return l})),n.d(t,"default",(function(){return d}));var o=n(3),a=n(7),r=(n(0),n(209)),i={id:"docker_install_advanced",title:"Docker Advanced Options Guide",sidebar_label:"Docker Advanced Options"},s={unversionedId:"deploy/docker_install_advanced",id:"deploy/docker_install_advanced",isDocsHomePage:!1,title:"Docker Advanced Options Guide",description:"The following customizations will allow for more complex situations than described in the Docker Installation guide. Find the section(s) which apply to you.",source:"@site/docs/deploy/docker_install_advanced.md",slug:"/deploy/docker_install_advanced",permalink:"/netsage-pipeline/docs/next/deploy/docker_install_advanced",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/docs/deploy/docker_install_advanced.md",version:"current",sidebar_label:"Docker Advanced Options",sidebar:"Pipeline",previous:{title:"Docker Installation Guide",permalink:"/netsage-pipeline/docs/next/deploy/docker_install_simple"},next:{title:"Upgrading",permalink:"/netsage-pipeline/docs/next/deploy/docker_upgrade"}},l=[{value:"To Add Additional Sflow or Netflow Collectors",id:"to-add-additional-sflow-or-netflow-collectors",children:[]},{value:"To Filter Flows by Interface",id:"to-filter-flows-by-interface",children:[]},{value:"To Filter Flows by Subnet",id:"to-filter-flows-by-subnet",children:[]},{value:"To Change a Sensor Name Depending on the Interface Used",id:"to-change-a-sensor-name-depending-on-the-interface-used",children:[]},{value:"To Do Sampling Rate Corrections in Logstash",id:"to-do-sampling-rate-corrections-in-logstash",children:[]},{value:"To NOT Deidentify Flows",id:"to-not-deidentify-flows",children:[]},{value:"To Increase Memory Available for Lostash",id:"to-increase-memory-available-for-lostash",children:[]},{value:"To Overwrite Organization Names When an ASN is Shared",id:"to-overwrite-organization-names-when-an-asn-is-shared",children:[]},{value:"To Tag Flows with Science Discipline Information",id:"to-tag-flows-with-science-discipline-information",children:[]},{value:"To Bring up Kibana and Elasticsearch Containers",id:"to-bring-up-kibana-and-elasticsearch-containers",children:[]}],c={toc:l};function d(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(r.b)("wrapper",Object(o.a)({},c,n,{components:t,mdxType:"MDXLayout"}),Object(r.b)("p",null,"The following customizations will allow for more complex situations than described in the Docker Installation guide. Find the section(s) which apply to you."),Object(r.b)("p",null,Object(r.b)("em",{parentName:"p"},"Please first read the Docker Installation guide in detail. This guide will build on top of that.")),Object(r.b)("h2",{id:"to-add-additional-sflow-or-netflow-collectors"},"To Add Additional Sflow or Netflow Collectors"),Object(r.b)("p",null,"Any number of sensors can be accomodated, although if there are more than a few being processed by the same pipeline, you may run into scaling issues. "),Object(r.b)("h4",{id:"a-edit-environment-file"},"a. Edit environment file"),Object(r.b)("p",null,"As an example, say we have three netflow sensors. In the .env file, first set ",Object(r.b)("inlineCode",{parentName:"p"},"netflowSensors=3"),". Then, in the next section, add the actual sensor names and ports for the additional sensors using variable names ending with _2 and _3. An example:"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre"},"netflowSensorName_1=The 1st Netflow Sensor Name\nnetflowPort_1=9000\n\nnetflowSensorName_2=The 2nd Netflow Sensor Name\nnetflowPort_2=9001\n\nnetflowSensorName_3=The 3rd Netflow Sensor Name\nnetflowPort_3=9002\n")),Object(r.b)("h4",{id:"b-edit-docker-composeoverride_exampleyml"},"b. Edit docker-composeoverride_example.yml"),Object(r.b)("p",null,"Add more nfacctd services to the ",Object(r.b)("strong",{parentName:"p"},"example")," override file. When copying and pasting, replace _1 with _2 or _3 in three places! Your file should look look something like this (remember you'll need to do this again after an upgrade! We need to fix the script to do this automatically):"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre"},'nfacctd_1:\n    ports:\n      # port on host receiving flow data : port in the container\n      - "${netflowPort_1}:${netflowContainerPort_1}/udp"\n\nnfacctd_2:\n    ports:\n      # port on host receiving flow data : port in the container\n      - "${netflowPort_2}:${netflowContainerPort_2}/udp"\n\nnfacctd_3:\n    ports:\n      # port on host receiving flow data : port in the container\n      - "${netflowPort_3}:${netflowContainerPort_3}/udp"\n')),Object(r.b)("h4",{id:"c-rerun-setup-pmacctsh"},"c. Rerun setup-pmacct.sh"),Object(r.b)("p",null,"Delete (after backing up) docker-compose.override.yml so the pmacct setup script can recreate it along with creating additional nfacctd config files. "),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre"},"rm docker-compose.override.yml\n./pmacct-setup.sh\n")),Object(r.b)("p",null,"Check docker-compose.override.yml and files in conf-pmacct/ for consistency."),Object(r.b)("h4",{id:"d-start-new-containers"},"d. Start new containers"),Object(r.b)("p",null,"If you are simply adding new collectors nfacctd_2 and nfacctd_3, and there are no changes to nfacctd_1, you should be able to start up the additional containers with"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose up -d \n")),Object(r.b)("p",null,"Otherwise, or to be safe, bring everything down first, then back up."),Object(r.b)("h2",{id:"to-filter-flows-by-interface"},"To Filter Flows by Interface"),Object(r.b)("p",null,"If your sensors are exporting all flows, but only those using particular interfaces are relevant, use this option in the .env file. All incoming flows will be read in, but the logstash pipeline will drop those that do not have src_ifindex OR dst_inindex equal to one of those listed.  (Processing a large number of unecessary flows may overwhelm logstash, so if at all possible, try to limit the flows at the router level or using iptables.) "),Object(r.b)("p",null,'In the .env file, uncomment lines in the appropriate section and enter the information required. "ALL" can refer to all sensors or all interfaces of a sensor. If a sensor is not referenced at all, all of its flows will be kept. Be sure ',Object(r.b)("inlineCode",{parentName:"p"},"ifindex_filter_flag=True"),' with "True" capitalized as shown, any sensor names are spelled exactly right, and list all the ifindex values of flows that should be kept and processed. Use semicolons to separate sensors. Some examples (use just one!):'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"ifindex_filter_flag=True\n## examples (include only 1 such line):\nifindex_filter_keep=ALL:123\nifindex_filter_keep=Sensor 1: 123\nifindex_filter_keep=Sensor 1: 456, 789\nifindex_filter_keep=Sensor 1: ALL; Sensor 2: 800, 900\n")),Object(r.b)("ul",null,Object(r.b)("li",{parentName:"ul"},"In the first example, all flows that have src_ifindex = 123 or dst_ifindex = 123 will be kept, regardless of sensor name. All other flows will be discarded."),Object(r.b)("li",{parentName:"ul"},'In the 2nd case, if src or dst ifindex is 123 and the sensor name is "Sensor 1", the flow will be kept. If there are flows from "Sensor 2", all of them will be kept.'),Object(r.b)("li",{parentName:"ul"},"In the 3rd case, flows from Sensor 1 having ifindex 456 or 789 will be kept."),Object(r.b)("li",{parentName:"ul"},"In the last example, all Sensor 1 flows will be kept, and those from Sensor 2 having ifindex 800 or 900 will be kept.  ")),Object(r.b)("p",null,"Spaces don't matter except within the sensor names. Punctuation is required as shown."),Object(r.b)("h2",{id:"to-filter-flows-by-subnet"},"To Filter Flows by Subnet"),Object(r.b)("p",null,'With this option, flows from specified sensors will be dropped unless src or dst is in the list of subnets to keep. It works similarly to the option to filter by interface.  "ALL" can refer to all sensors.\nIf a sensor is not referenced at all, all of its flows will be kept. '),Object(r.b)("p",null,"For example,"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre"},"subnet_filter_flag=True\nsubnet_filter_keep=Sensor A Name: 123.45.6.0/16; Sensor B Name: 123.33.33.0/24, 456.66.66.0/24\n")),Object(r.b)("h2",{id:"to-change-a-sensor-name-depending-on-the-interface-used"},"To Change a Sensor Name Depending on the Interface Used"),Object(r.b)("p",null,"In some cases, users want to keep all flows from a certain sensor but differentiate between those that enter or exit through a specific interface by using a different sensor name."),Object(r.b)("p",null,'In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all four fields are set properly! For example,'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"ifindex_sensor_rename_flag=True\nifindex_sensor_rename_ifindex=10032\nifindex_sensor_rename_old_name=IU Sflow \nifindex_sensor_rename_new_name=IU Bloomington Sflow\n")),Object(r.b)("p",null,'In this case, any flows from the "IU Sflow" sensor that use interface 10032 (src_ifindex = 10032 OR dst_ifindex = 10032) will have the sensor name changed from "IU Sflow" to "IU Bloomington Sflow". Currently, only one such rename can be configured in Docker and only 1 ifindex is allowed.'),Object(r.b)("div",{className:"admonition admonition-note alert alert--secondary"},Object(r.b)("div",{parentName:"div",className:"admonition-heading"},Object(r.b)("h5",{parentName:"div"},Object(r.b)("span",{parentName:"h5",className:"admonition-icon"},Object(r.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},Object(r.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M6.3 5.69a.942.942 0 0 1-.28-.7c0-.28.09-.52.28-.7.19-.18.42-.28.7-.28.28 0 .52.09.7.28.18.19.28.42.28.7 0 .28-.09.52-.28.7a1 1 0 0 1-.7.3c-.28 0-.52-.11-.7-.3zM8 7.99c-.02-.25-.11-.48-.31-.69-.2-.19-.42-.3-.69-.31H6c-.27.02-.48.13-.69.31-.2.2-.3.44-.31.69h1v3c.02.27.11.5.31.69.2.2.42.31.69.31h1c.27 0 .48-.11.69-.31.2-.19.3-.42.31-.69H8V7.98v.01zM7 2.3c-3.14 0-5.7 2.54-5.7 5.68 0 3.14 2.56 5.7 5.7 5.7s5.7-2.55 5.7-5.7c0-3.15-2.56-5.69-5.7-5.69v.01zM7 .98c3.86 0 7 3.14 7 7s-3.14 7-7 7-7-3.12-7-7 3.14-7 7-7z"}))),"note")),Object(r.b)("div",{parentName:"div",className:"admonition-content"},Object(r.b)("p",{parentName:"div"},"Please notify the devs at IU in advance, if you need to modify a sensor name, because the regexes used for determining sensor_group and sensor_type may have to be updated."))),Object(r.b)("h2",{id:"to-do-sampling-rate-corrections-in-logstash"},"To Do Sampling Rate Corrections in Logstash"),Object(r.b)("p",null,"When flow sampling is done, corrections have to be applied to the number of packets and bytes. For example, if you are sampling 1 out of 100 flows, for each flow measured, it is assumed that in reality there would be 100 flows of that size with that src and dst, so the number of bits (and the number of packets, bits/s and packets/s) is multiplied by 100. Usually the collector (nfacctd or sfacctd process) gets the sampling rate from the incoming data and applies the correction, but in some cases, the sensor may not send the sampling rate, or there may be a complex set-up that requires a manual correction. "),Object(r.b)("p",null,'In the .env file, uncomment the appropriate section and enter the information required. Be sure "True" is capitalized as shown and all 3 fields are set properly! The same correction can be applied to multiple sensors by using a semicolon-separated list. The same correction applies to all listed sensors. For example,'),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"sampling_correction_flag=True\nsampling_correction_sensors=IU Bloomington Sflow; IU Indy Sflow\nsampling_correction_factor=512\n")),Object(r.b)("p",null,'In this example, all flows from sensors "IU Bloomington Sflow" and "IU Indy Sflow" will have a correction factor of 512 applied by logstash. Any other sensors will not have a correction applied by logstash (presumably pmacct would apply the correction automatically).'),Object(r.b)("blockquote",null,Object(r.b)("p",{parentName:"blockquote"},"Note that if pmacct has made a sampling correction already, no additional manual correction will be applied, even if these options are set,\nso this can be used ",Object(r.b)("em",{parentName:"p"},"to be sure")," a sampling correction is applied.")),Object(r.b)("h2",{id:"to-not-deidentify-flows"},"To NOT Deidentify Flows"),Object(r.b)("p",null,"Normally all flows are deidentified before being saved to elasticsearch by truncating the src and dst IP addresses. If you do NOT want to do this, set full_IPs_flag to True. (You will most likely want to request access control on the grafana portal, as well.)"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre"},"# To keep full IP addresses, set this parameter to True.\nfull_IPs_flag=True\n")),Object(r.b)("h2",{id:"to-increase-memory-available-for-lostash"},"To Increase Memory Available for Lostash"),Object(r.b)("p",null,"If cpu or memory usage seems to be a problem, try increasing the java JVM heap size for logstash from 4GB to 8GB."),Object(r.b)("p",null,"To do this, edit LS_JAVA_OPTS in the .env file. E.g.,"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-yaml"},"LS_JAVA_OPTS=-Xmx8g -Xms8g\n")),Object(r.b)("p",null,"Here are some tips for adjusting the JVM heap size (see ",Object(r.b)("a",{parentName:"p",href:"https://www.elastic.co/guide/en/logstash/current/jvm-settings.html"},"https://www.elastic.co/guide/en/logstash/current/jvm-settings.html"),"):"),Object(r.b)("ul",null,Object(r.b)("li",{parentName:"ul"},"Set the minimum (Xms) and maximum (Xmx) heap allocation size to the same value to prevent the heap from resizing at runtime, which is a very costly process."),Object(r.b)("li",{parentName:"ul"},"CPU utilization can increase unnecessarily if the heap size is too low, resulting in the JVM constantly garbage collecting. You can check for this issue by doubling the heap size to see if performance improves."),Object(r.b)("li",{parentName:"ul"},"Do not increase the heap size past the amount of physical memory. Some memory must be left to run the OS and other processes. As a general guideline for most installations, don\u2019t exceed 50-75% of physical memory. The more memory you have, the higher percentage you can use.")),Object(r.b)("h2",{id:"to-overwrite-organization-names-when-an-asn-is-shared"},"To Overwrite Organization Names When an ASN is Shared"),Object(r.b)("p",null,"Source and destination organization names come from lookups by ASN or IP in databases provided by CAIDA or MaxMind. (The former is preferred, the latter acts as a backup.)\nSometimes an organization that owns an AS and a large block of IPs will allow members or subentities to use certain IP ranges within the same AS.\nIn this case, all flows to and from the members will have src or dst organization set to the parent organization's name. If desired, the member organizations' names can be substituted. To do so requires the use of a \"member list\" which specifies the ASN(s) being shared and the IP ranges for each member. "),Object(r.b)("p",null,"See ",Object(r.b)("strong",{parentName:"p"},"conf-logstash/support/networkA-members-list.rb.example")," for an example. "),Object(r.b)("h2",{id:"to-tag-flows-with-science-discipline-information"},"To Tag Flows with Science Discipline Information"),Object(r.b)("p",null,"At ",Object(r.b)("a",{parentName:"p",href:"https://scienceregistry.netsage.global"},"https://scienceregistry.netsage.global"),", you can see a hand-curated list of resources (IP blocks) which are linked to the organizations, sciences, and projects that use them. This information is used by the Netsage pipeline to tag science-related flows. If you would like to see your resources or projects included, please contact us to have them added to the Registry. "),Object(r.b)("h2",{id:"to-bring-up-kibana-and-elasticsearch-containers"},"To Bring up Kibana and Elasticsearch Containers"),Object(r.b)("p",null,"The file docker-compose.develop.yaml can be used in conjunction with docker-compose.yaml to bring up the optional Kibana and Elastic Search components."),Object(r.b)("p",null,"This isn't a production pattern but the tools can be useful at times. Please refer to the ",Object(r.b)("a",{parentName:"p",href:"../devel/docker_dev_guide#optional-elasticsearch-and-kibana"},"Docker Dev Guide")))}d.isMDXComponent=!0},209:function(e,t,n){"use strict";n.d(t,"a",(function(){return p})),n.d(t,"b",(function(){return m}));var o=n(0),a=n.n(o);function r(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function s(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){r(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,o,a=function(e,t){if(null==e)return{};var n,o,a={},r=Object.keys(e);for(o=0;o<r.length;o++)n=r[o],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);for(o=0;o<r.length;o++)n=r[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var c=a.a.createContext({}),d=function(e){var t=a.a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):s(s({},t),e)),n},p=function(e){var t=d(e.components);return a.a.createElement(c.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},u=a.a.forwardRef((function(e,t){var n=e.components,o=e.mdxType,r=e.originalType,i=e.parentName,c=l(e,["components","mdxType","originalType","parentName"]),p=d(n),u=o,m=p["".concat(i,".").concat(u)]||p[u]||b[u]||r;return n?a.a.createElement(m,s(s({ref:t},c),{},{components:n})):a.a.createElement(m,s({ref:t},c))}));function m(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var r=n.length,i=new Array(r);i[0]=u;var s={};for(var l in t)hasOwnProperty.call(t,l)&&(s[l]=t[l]);s.originalType=e,s.mdxType="string"==typeof e?e:o,i[1]=s;for(var c=2;c<r;c++)i[c]=n[c];return a.a.createElement.apply(null,i)}return a.a.createElement.apply(null,n)}u.displayName="MDXCreateElement"}}]);