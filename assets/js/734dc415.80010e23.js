(window.webpackJsonp=window.webpackJsonp||[]).push([[67],{137:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return i})),n.d(t,"metadata",(function(){return l})),n.d(t,"toc",(function(){return s})),n.d(t,"default",(function(){return p}));var o=n(3),a=n(7),r=(n(0),n(232)),i={id:"docker_install_simple",title:"Docker Installation Guide",sidebar_label:"Docker Installation"},l={unversionedId:"deploy/docker_install_simple",id:"deploy/docker_install_simple",isDocsHomePage:!1,title:"Docker Installation Guide",description:"In this deployment guide, you will learn how to deploy a basic Netsage setup that includes one sflow and/or one netflow collector.  If you have more than one collector of either type, or other special situations, see the Docker Advanced guide.",source:"@site/docs/deploy/docker_install_simple.md",slug:"/deploy/docker_install_simple",permalink:"/netsage-pipeline/docs/next/deploy/docker_install_simple",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/docs/deploy/docker_install_simple.md",version:"current",sidebar_label:"Docker Installation",sidebar:"Pipeline",previous:{title:"Manual Installation Guide",permalink:"/netsage-pipeline/docs/next/deploy/bare_metal_install"},next:{title:"Docker Advanced Options Guide",permalink:"/netsage-pipeline/docs/next/deploy/docker_install_advanced"}},s=[{value:"1. Set up Data Sources",id:"1-set-up-data-sources",children:[]},{value:"2. Set up a Pipeline Host",id:"2-set-up-a-pipeline-host",children:[]},{value:"3. Clone the Netsage Pipeline Project",id:"3-clone-the-netsage-pipeline-project",children:[]},{value:"4. Create Docker-compose.override.yml",id:"4-create-docker-composeoverrideyml",children:[]},{value:"5. Choose Pipeline Version",id:"5-choose-pipeline-version",children:[]},{value:"6. Create Environment File",id:"6-create-environment-file",children:[]},{value:"Testing the Collectors",id:"testing-the-collectors",children:[]},{value:"Running the Collectors and Pipeline",id:"running-the-collectors-and-pipeline",children:[]}],c={toc:s};function p(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(r.b)("wrapper",Object(o.a)({},c,n,{components:t,mdxType:"MDXLayout"}),Object(r.b)("p",null,"In this deployment guide, you will learn how to deploy a basic Netsage setup that includes one sflow and/or one netflow collector.  If you have more than one collector of either type, or other special situations, see the Docker Advanced guide."),Object(r.b)("p",null,"The Docker containers included in the installation are"),Object(r.b)("ul",null,Object(r.b)("li",{parentName:"ul"},"rabbit    (the local RabbitMQ server)"),Object(r.b)("li",{parentName:"ul"},"sflow-collector   (receives sflow data and writes nfcapd files)"),Object(r.b)("li",{parentName:"ul"},"netflow-collector   (receives netflow data and writes nfcapd files)"),Object(r.b)("li",{parentName:"ul"},"importer   (reads nfcapd files and puts flows into a local rabbit queue)"),Object(r.b)("li",{parentName:"ul"},"logstash   (logstash pipeline that processes flows and sends them to their final destination, by default a local rabbit queue)"),Object(r.b)("li",{parentName:"ul"},"ofelia   (cron-like downloading of files used by the logstash pipeline)")),Object(r.b)("p",null,"The code and configs for the importer and logstash pipeline can be viewed in the netsage-project/netsage-pipeline github repo. See netsage-project/docker-nfdump-collector for code related to the collectors."),Object(r.b)("h3",{id:"1-set-up-data-sources"},"1. Set up Data Sources"),Object(r.b)("p",null,"The data processing pipeline needs data to ingest in order to do anything, of course. There are three types of data that can be consumed."),Object(r.b)("ul",null,Object(r.b)("li",{parentName:"ul"},"sflow "),Object(r.b)("li",{parentName:"ul"},"netflow"),Object(r.b)("li",{parentName:"ul"},"tstat")),Object(r.b)("p",null,"At least one of these must be set up on a ",Object(r.b)("em",{parentName:"p"},"sensor")," (i.e., flow ",Object(r.b)("em",{parentName:"p"},"exporter")," / router), to provide the incoming flow data.\nYou can do this step later, but it will helpful to have it working first. "),Object(r.b)("p",null,"Sflow and netflow data should be exported to the pipeline host where there will be ",Object(r.b)("em",{parentName:"p"},"collectors")," (nfcapd and/or sfcapd processes) ready to receive it (see below). To use the default settings, send sflow to port 9998 and netflow/IPFIX to port 9999. On the pipeline host, allow incoming traffic from the flow exporters, of course."),Object(r.b)("p",null,'Tstat data should be sent directly to the logstash input rabbit queue "netsage_deidentifier_raw" on the pipeline host. No collector is needed for tstat data. See the netsage-project/tstat-transport repo.  (From there, logstash will grab the data and process it the same way as it processes sflow/netflow data. (See the Docker Advanced guide.)'),Object(r.b)("h3",{id:"2-set-up-a-pipeline-host"},"2. Set up a Pipeline Host"),Object(r.b)("p",null,"Decide where to run the Docker Pipeline and get it set up. Adjust iptables to allow the flow exporters (routers) to send flow data to the host. "),Object(r.b)("p",null,"Install Docker Engine (docker-ce, docker-ce-cli, containerd.io) - see instructions at ",Object(r.b)("a",{parentName:"p",href:"https://docs.docker.com/engine/install/"},"https://docs.docker.com/engine/install/"),"."),Object(r.b)("p",null,"Install Docker Compose from Docker's GitHub repository - see ",Object(r.b)("a",{parentName:"p",href:"https://docs.docker.com/compose/install/"},"https://docs.docker.com/compose/install/"),".  You need to ",Object(r.b)("strong",{parentName:"p"},"specify version 1.29.2")," (or newer) in the curl command. "),Object(r.b)("p",null,"Check default file permissions. If the ",Object(r.b)("em",{parentName:"p"},"logstash")," user is not able to access the logstash config files in the git checkout, you'll get an error from logstash saying there are no .conf files found even though they are there. Various components also need to be able to read and write to the data/ directory in the checkout. Defaults of 775 (u=rwx, g=rwx, o=rx) should work."),Object(r.b)("h3",{id:"3-clone-the-netsage-pipeline-project"},"3. Clone the Netsage Pipeline Project"),Object(r.b)("p",null,"Clone the netsage-pipeline project from github."),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"git clone https://github.com/netsage-project/netsage-pipeline.git\n")),Object(r.b)("p",null,"When the pipeline runs, it uses the logstash conf files that are in the git checkout (in conf-logstash/), as well as a couple other files like docker-compose.yml, so it is important to checkout the correct version."),Object(r.b)("p",null,"Move into the netsage-pipeline/ directory (",Object(r.b)("strong",{parentName:"p"},"all git and docker commands must be run from inside this directory!"),"), then checkout the most recent version of the code. It will say you are in 'detached HEAD' state if you don't include -b."),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"git checkout {tag}\n")),Object(r.b)("p",null,'Replace "{tag}" with the release version you intend to use, e.g., "v1.2.11".  ("Master" is the development version and is not intended for general use!)\n',Object(r.b)("inlineCode",{parentName:"p"},"git status")," will confirm which branch you are on, e.g., master or v1.2.11."),Object(r.b)("h3",{id:"4-create-docker-composeoverrideyml"},"4. Create Docker-compose.override.yml"),Object(r.b)("p",null,"Information in the ",Object(r.b)("inlineCode",{parentName:"p"},"docker-compose.yml")," file tells docker which containers (processes) to run and sets various parameters for them.\nSettings in the ",Object(r.b)("inlineCode",{parentName:"p"},"docker-compose.override.yml")," file will overrule and add to those. Note that docker-compose.yml should not be edited since upgrades will replace it. Put all customizations in the override file, since override files will not be overwritten."),Object(r.b)("p",null,"Collector settings may need to be edited by the user, so the information that docker uses to run the collectors is specified (only) in the override file. Therefore, docker-compose_override.example.yml must always be copied to docker-compose_override.yml. "),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"cp docker-compose.override_example.yml docker-compose.override.yml\n")),Object(r.b)("p",null,"By default docker will bring up a single sflow collector and a single netflow collector that listen to udp traffic on ports localhost:9998 and 9999. If this matches your case, you don't need to make any changes to the docker-compose.override_example.yml. "),Object(r.b)("ul",null,Object(r.b)("li",{parentName:"ul"},"If you have only one collector, remove or comment out the section for the one not needed so the collector doesn't run and simply create empty nfcapd files."),Object(r.b)("li",{parentName:"ul"},'If the collectors need to listen to different ports, make the appropriate changes here in both the "command:" and "ports:" lines. '),Object(r.b)("li",{parentName:"ul"},"By default, the collectors will save flows to nfcapd files in sflow/ and netflow/ subdirectories in ",Object(r.b)("inlineCode",{parentName:"li"},"./data/input_data/")," (i.e., the data/ directory in the git checkout).  If you need to save the data files to a different location, see the Docker Advanced section.")),Object(r.b)("p",null,"Other lines in this file you can ignore for now. "),Object(r.b)("div",{className:"admonition admonition-note alert alert--secondary"},Object(r.b)("div",{parentName:"div",className:"admonition-heading"},Object(r.b)("h5",{parentName:"div"},Object(r.b)("span",{parentName:"h5",className:"admonition-icon"},Object(r.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},Object(r.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M6.3 5.69a.942.942 0 0 1-.28-.7c0-.28.09-.52.28-.7.19-.18.42-.28.7-.28.28 0 .52.09.7.28.18.19.28.42.28.7 0 .28-.09.52-.28.7a1 1 0 0 1-.7.3c-.28 0-.52-.11-.7-.3zM8 7.99c-.02-.25-.11-.48-.31-.69-.2-.19-.42-.3-.69-.31H6c-.27.02-.48.13-.69.31-.2.2-.3.44-.31.69h1v3c.02.27.11.5.31.69.2.2.42.31.69.31h1c.27 0 .48-.11.69-.31.2-.19.3-.42.31-.69H8V7.98v.01zM7 2.3c-3.14 0-5.7 2.54-5.7 5.68 0 3.14 2.56 5.7 5.7 5.7s5.7-2.55 5.7-5.7c0-3.15-2.56-5.69-5.7-5.69v.01zM7 .98c3.86 0 7 3.14 7 7s-3.14 7-7 7-7-3.12-7-7 3.14-7 7-7z"}))),"note")),Object(r.b)("div",{parentName:"div",className:"admonition-content"},Object(r.b)("p",{parentName:"div"},"If you run into issues, try removing all the comments in the override file as they may conflict with the parsing done by docker-compose, though we have not found this to be a problem."))),Object(r.b)("h3",{id:"5-choose-pipeline-version"},"5. Choose Pipeline Version"),Object(r.b)("p",null,"Once you've created the docker-compose.override.xml file and finished adjusting it for any customizations, you're ready to select which image versions Docker should run."),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"./scripts/docker_select_version.sh\n")),Object(r.b)("p",null,"When prompted, select the ",Object(r.b)("strong",{parentName:"p"},"same version")," you checked out earlier. "),Object(r.b)("p",null,"This script will replace the version numbers of docker images in docker-compose.override.yml and docker-compose.yml with the correct values."),Object(r.b)("h3",{id:"6-create-environment-file"},"6. Create Environment File"),Object(r.b)("p",null,Object(r.b)("p",{parentName:"p"},"Next, copy ",Object(r.b)("inlineCode",{parentName:"p"},"env.example")," to ",Object(r.b)("inlineCode",{parentName:"p"},".env"),"  "),Object(r.b)("pre",{parentName:"p"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"cp env.example .env \n")),Object(r.b)("p",{parentName:"p"},"then edit the .env file to set the sensor names to unique identifiers (with spaces or not, no quotes)"),Object(r.b)("pre",{parentName:"p"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"# Importer settings\nsflowSensorName=My sflow sensor name\nnetflowSensorName=My netflow sensor name\n")),Object(r.b)("ul",{parentName:"p"},Object(r.b)("li",{parentName:"ul"},"If you have only one collector, remove or comment out the line for the one you are not using."),Object(r.b)("li",{parentName:"ul"},'If you have more than one of the same type of collector, see the "Docker Advanced" documentation.')),Object(r.b)("div",{parentName:"p",className:"admonition admonition-note alert alert--secondary"},Object(r.b)("div",{parentName:"div",className:"admonition-heading"},Object(r.b)("h5",{parentName:"div"},Object(r.b)("span",{parentName:"h5",className:"admonition-icon"},Object(r.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},Object(r.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M6.3 5.69a.942.942 0 0 1-.28-.7c0-.28.09-.52.28-.7.19-.18.42-.28.7-.28.28 0 .52.09.7.28.18.19.28.42.28.7 0 .28-.09.52-.28.7a1 1 0 0 1-.7.3c-.28 0-.52-.11-.7-.3zM8 7.99c-.02-.25-.11-.48-.31-.69-.2-.19-.42-.3-.69-.31H6c-.27.02-.48.13-.69.31-.2.2-.3.44-.31.69h1v3c.02.27.11.5.31.69.2.2.42.31.69.31h1c.27 0 .48-.11.69-.31.2-.19.3-.42.31-.69H8V7.98v.01zM7 2.3c-3.14 0-5.7 2.54-5.7 5.68 0 3.14 2.56 5.7 5.7 5.7s5.7-2.55 5.7-5.7c0-3.15-2.56-5.69-5.7-5.69v.01zM7 .98c3.86 0 7 3.14 7 7s-3.14 7-7 7-7-3.12-7-7 3.14-7 7-7z"}))),"note")),Object(r.b)("div",{parentName:"div",className:"admonition-content"},Object(r.b)("p",{parentName:"div"},"These names uniquely identify the source of the data and will be shown in the Grafana dashboards. In elasticsearch, they are saved in the ",Object(r.b)("inlineCode",{parentName:"p"},"meta.sensor_id"),' field. Choose names that are meaningful and unique.\nFor example, your sensor names might be "MyNet New York Sflow" and "MyNet Boston Netflow" or "MyNet New York - London" and "MyNet New York - Paris". Whatever makes sense in your situation.'))),Object(r.b)("p",{parentName:"p"},"You will also want to edit the ",Object(r.b)("strong",{parentName:"p"},"Logstash output rabbit queue")," section. This section defines where the final data will land after going through the pipeline.  By default, it will be written to a rabbitmq queue on ",Object(r.b)("inlineCode",{parentName:"p"},"rabbit"),", ie, the local rabbitMQ server running in the docker container. Enter a hostname to send to a remote rabbitMQ server (also the correct username, password, and queue key/name). "),Object(r.b)("pre",{parentName:"p"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"rabbitmq_output_host=rabbit@mynet.edu\nrabbitmq_output_username=guest\nrabbitmq_output_pw=guest\nrabbitmq_output_key=netsage_archive_input\n")),Object(r.b)("div",{parentName:"p",className:"admonition admonition-note alert alert--secondary"},Object(r.b)("div",{parentName:"div",className:"admonition-heading"},Object(r.b)("h5",{parentName:"div"},Object(r.b)("span",{parentName:"h5",className:"admonition-icon"},Object(r.b)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},Object(r.b)("path",{parentName:"svg",fillRule:"evenodd",d:"M6.3 5.69a.942.942 0 0 1-.28-.7c0-.28.09-.52.28-.7.19-.18.42-.28.7-.28.28 0 .52.09.7.28.18.19.28.42.28.7 0 .28-.09.52-.28.7a1 1 0 0 1-.7.3c-.28 0-.52-.11-.7-.3zM8 7.99c-.02-.25-.11-.48-.31-.69-.2-.19-.42-.3-.69-.31H6c-.27.02-.48.13-.69.31-.2.2-.3.44-.31.69h1v3c.02.27.11.5.31.69.2.2.42.31.69.31h1c.27 0 .48-.11.69-.31.2-.19.3-.42.31-.69H8V7.98v.01zM7 2.3c-3.14 0-5.7 2.54-5.7 5.68 0 3.14 2.56 5.7 5.7 5.7s5.7-2.55 5.7-5.7c0-3.15-2.56-5.69-5.7-5.69v.01zM7 .98c3.86 0 7 3.14 7 7s-3.14 7-7 7-7-3.12-7-7 3.14-7 7-7z"}))),"note")),Object(r.b)("div",{parentName:"div",className:"admonition-content"},Object(r.b)("p",{parentName:"div"},"To send processed flow data to GlobalNOC at Indiana University, you will need to obtain settings for this section from your contact. A new queue may need to be set up at IU, as well as allowing traffic from your pipeline host. (At IU, data from the this final rabbit queue will be moved into an Elasticsearch instance for storage and viewing.)"))),Object(r.b)("p",{parentName:"p"},"The following options are described in the Docker Advanced section:"),Object(r.b)("p",{parentName:"p"},Object(r.b)("strong",{parentName:"p"},"To drop all flows except those using the specfied interfaces"),": Use if only some flows from a router are of interest and those can be identified by interface."),Object(r.b)("p",{parentName:"p"},Object(r.b)("strong",{parentName:"p"},"To change the sensor name for flows using a certain interface"),": Use if you want to break out some flows coming into a port and give them a different sensor name."),Object(r.b)("p",{parentName:"p"},Object(r.b)("strong",{parentName:"p"},'To "manually" correct flow sizes and rates for sampling for specified sensors'),": Use if sampling corrections are not being done automatically. Normally you do not need to use this, but check flows to be sure results are reasonable.")),Object(r.b)("h2",{id:"testing-the-collectors"},"Testing the Collectors"),Object(r.b)("p",null,"At this point, you can start the two flow collectors by themselves by running the following line. If you only need one of the collectors, remove the other from this command.  "),Object(r.b)("p",null,"(See the next section for how to start all the containers, including the collectors.)"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose up -d sflow-collector netflow-collector\n")),Object(r.b)("p",null,"Subdirectories for sflow/netflow, year, month, and day are created automatically under ",Object(r.b)("inlineCode",{parentName:"p"},"data/input_data/"),". File names contain dates and times.\nThese are not text files; to view the contents, use an ",Object(r.b)("a",{parentName:"p",href:"http://www.linuxcertif.com/man/1/nfdump/"},"nfdump command")," (you will need to install nfdump).\nFiles will be deleted automatically by the importer as they age out (the default is to keep 3 days).  "),Object(r.b)("p",null,"If the collector(s) are running properly, you should see nfcapd files being written every 5 minutes and they should have sizes of more than a few hundred bytes. (Empty files still have header and footer lines.)",Object(r.b)("br",{parentName:"p"}),"\n","See Troubleshooting if you have problems."),Object(r.b)("p",null,"To stop the collectors"),Object(r.b)("pre",null,Object(r.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose down \n")),Object(r.b)("h2",{id:"running-the-collectors-and-pipeline"},"Running the Collectors and Pipeline"),Object(r.b)("p",null,Object(r.b)("p",{parentName:"p"},"Start up the pipeline (all containers) using:"),Object(r.b)("pre",{parentName:"p"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"# docker-compose up -d\n")),Object(r.b)("p",{parentName:"p"},'This will also restart any containers/processes that have died. "-d" runs containers in the background.'),Object(r.b)("p",{parentName:"p"},"You can see the status of the containers and whether any have died (exited) using"),Object(r.b)("pre",{parentName:"p"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"# docker-compose ps\n")),Object(r.b)("p",{parentName:"p"},"To check the logs for each of the containers, run"),Object(r.b)("pre",{parentName:"p"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"# docker-compose logs\n# docker-compose logs logstash\n# docker-compose logs importer\netc.\n")),Object(r.b)("p",{parentName:"p"},"Add ",Object(r.b)("inlineCode",{parentName:"p"},"-f")," or, e.g., ",Object(r.b)("inlineCode",{parentName:"p"},"-f logstash")," to see new log messages as they arrive.  ",Object(r.b)("inlineCode",{parentName:"p"},"--timestamps"),", ",Object(r.b)("inlineCode",{parentName:"p"},"--tail"),",  and ",Object(r.b)("inlineCode",{parentName:"p"},"--since")," are also useful -- look up details in Docker documentation."),Object(r.b)("p",{parentName:"p"},"To shut down the pipeline (all containers) use"),Object(r.b)("pre",{parentName:"p"},Object(r.b)("code",{parentName:"pre",className:"language-sh"},"# docker-compose down\n")),Object(r.b)("p",{parentName:"p"},"Run all commands from the netsage-pipeline/ directory.")))}p.isMDXComponent=!0},232:function(e,t,n){"use strict";n.d(t,"a",(function(){return d})),n.d(t,"b",(function(){return m}));var o=n(0),a=n.n(o);function r(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){r(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function s(e,t){if(null==e)return{};var n,o,a=function(e,t){if(null==e)return{};var n,o,a={},r=Object.keys(e);for(o=0;o<r.length;o++)n=r[o],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);for(o=0;o<r.length;o++)n=r[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var c=a.a.createContext({}),p=function(e){var t=a.a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},d=function(e){var t=p(e.components);return a.a.createElement(c.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},u=a.a.forwardRef((function(e,t){var n=e.components,o=e.mdxType,r=e.originalType,i=e.parentName,c=s(e,["components","mdxType","originalType","parentName"]),d=p(n),u=o,m=d["".concat(i,".").concat(u)]||d[u]||b[u]||r;return n?a.a.createElement(m,l(l({ref:t},c),{},{components:n})):a.a.createElement(m,l({ref:t},c))}));function m(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var r=n.length,i=new Array(r);i[0]=u;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l.mdxType="string"==typeof e?e:o,i[1]=l;for(var c=2;c<r;c++)i[c]=n[c];return a.a.createElement.apply(null,i)}return a.a.createElement.apply(null,n)}u.displayName="MDXCreateElement"}}]);