(window.webpackJsonp=window.webpackJsonp||[]).push([[70],{140:function(e,t,o){"use strict";o.r(t),o.d(t,"frontMatter",(function(){return a})),o.d(t,"metadata",(function(){return l})),o.d(t,"toc",(function(){return s})),o.d(t,"default",(function(){return u}));var n=o(3),r=o(7),i=(o(0),o(232)),a={id:"docker_troubleshoot",title:"Docker Troubleshooting",sidebar_label:"Troubleshooting"},l={unversionedId:"deploy/docker_troubleshoot",id:"version-1.2.11/deploy/docker_troubleshoot",isDocsHomePage:!1,title:"Docker Troubleshooting",description:"Troubleshooting",source:"@site/versioned_docs/version-1.2.11/deploy/docker_troubleshooting.md",slug:"/deploy/docker_troubleshoot",permalink:"/netsage-pipeline/docs/1.2.11/deploy/docker_troubleshoot",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/versioned_docs/version-1.2.11/deploy/docker_troubleshooting.md",version:"1.2.11",sidebar_label:"Troubleshooting",sidebar:"version-1.2.11/Pipeline",previous:{title:"Upgrading",permalink:"/netsage-pipeline/docs/1.2.11/deploy/docker_upgrade"},next:{title:"Pipeline Replay Dataset",permalink:"/netsage-pipeline/docs/1.2.11/devel/dev_dataset"}},s=[{value:"Troubleshooting",id:"troubleshooting",children:[{value:"If you are not seeing flows after installation",id:"if-you-are-not-seeing-flows-after-installation",children:[]},{value:"If flow collection stops",id:"if-flow-collection-stops",children:[]}]}],c={toc:s};function u(e){var t=e.components,o=Object(r.a)(e,["components"]);return Object(i.b)("wrapper",Object(n.a)({},c,o,{components:t,mdxType:"MDXLayout"}),Object(i.b)("h2",{id:"troubleshooting"},"Troubleshooting"),Object(i.b)("h3",{id:"if-you-are-not-seeing-flows-after-installation"},"If you are not seeing flows after installation"),Object(i.b)("p",null,Object(i.b)("strong",{parentName:"p"},"Troubleshooting checklist:")),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"Use ",Object(i.b)("inlineCode",{parentName:"li"},"docker-compose ps")," to be sure the collectors (and other containers) are running."),Object(i.b)("li",{parentName:"ul"},"Make sure you configured your routers to point to the correct address/port where the collector is running.\xa0 "),Object(i.b)("li",{parentName:"ul"},"Check iptables on your pipeline host to be sure incoming traffic from the routers is allowed."),Object(i.b)("li",{parentName:"ul"},'Check to see if nfcapd files are being written. There should be a directory for the year, month, and day in netsage-pipeline/data/input_data/netflow/ or sflow/, and files should be larger than a few hundred bytes. If the files exist but are too small, the collector is running but there are no incoming flows.  "nfdump -r filename" will show the flows in a file (you may need to install nfdump).'),Object(i.b)("li",{parentName:"ul"},"Make sure you created .env and docker-compose.override.yml files and updated the settings accordingly,  sensorName especially since that identifies the source of the data."),Object(i.b)("li",{parentName:"ul"},"Check the logs of the various containers to see if anything jumps out as being invalid.\xa0 ",Object(i.b)("inlineCode",{parentName:"li"},"docker-compose logs $service"),", where $service is logstash, importer, rabbit, etc."),Object(i.b)("li",{parentName:"ul"},"If the final rabbit queue is on an external host, check the credentials you are using and whether iptables on that host allows incoming traffic from your pipeline host.")),Object(i.b)("h3",{id:"if-flow-collection-stops"},"If flow collection stops"),Object(i.b)("p",null,Object(i.b)("strong",{parentName:"p"},"Errors:")),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"See if any of the containers has died using  ",Object(i.b)("inlineCode",{parentName:"li"},"docker ps")),Object(i.b)("li",{parentName:"ul"},"Check the logs of the various containers to see if anything jumps out as being invalid.\xa0Eg, ",Object(i.b)("inlineCode",{parentName:"li"},"docker-compose logs logstash"),"."),Object(i.b)("li",{parentName:"ul"},"If logstash dies with an error about not finding ","*",".conf files, make sure conf-logstash/ and directories and files within are readable by everyone (and directories are executable by everyone). The data/ directory and subdirectories need to be readable and writable by everyone, as well.")),Object(i.b)("p",null,Object(i.b)("strong",{parentName:"p"},"Disk space:")),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"If the pipeline suddenly fails, check to see if the disk is full. If it is, first try getting rid of old docker images and containers to free up space: ",Object(i.b)("inlineCode",{parentName:"li"},"docker image prune -a")," and ",Object(i.b)("inlineCode",{parentName:"li"},"docker container prune"),"."),Object(i.b)("li",{parentName:"ul"},"Also check to see how much space the nfcapd files are consuming. You may need to add more disk space. You could also try automatically deleting nfcapd files after a fewer number of days (see Docker Advanced). ")),Object(i.b)("p",null,Object(i.b)("strong",{parentName:"p"},"Memory:")),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"If you are running a lot of data, sometimes docker may need to be allocated more memory. The most\nlikely culprit is logstash (java) which is only allocated 2GB of RAM by default. Please see the Docker Advanced guide for how to change.")))}u.isMDXComponent=!0},232:function(e,t,o){"use strict";o.d(t,"a",(function(){return d})),o.d(t,"b",(function(){return f}));var n=o(0),r=o.n(n);function i(e,t,o){return t in e?Object.defineProperty(e,t,{value:o,enumerable:!0,configurable:!0,writable:!0}):e[t]=o,e}function a(e,t){var o=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),o.push.apply(o,n)}return o}function l(e){for(var t=1;t<arguments.length;t++){var o=null!=arguments[t]?arguments[t]:{};t%2?a(Object(o),!0).forEach((function(t){i(e,t,o[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(o)):a(Object(o)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(o,t))}))}return e}function s(e,t){if(null==e)return{};var o,n,r=function(e,t){if(null==e)return{};var o,n,r={},i=Object.keys(e);for(n=0;n<i.length;n++)o=i[n],t.indexOf(o)>=0||(r[o]=e[o]);return r}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(n=0;n<i.length;n++)o=i[n],t.indexOf(o)>=0||Object.prototype.propertyIsEnumerable.call(e,o)&&(r[o]=e[o])}return r}var c=r.a.createContext({}),u=function(e){var t=r.a.useContext(c),o=t;return e&&(o="function"==typeof e?e(t):l(l({},t),e)),o},d=function(e){var t=u(e.components);return r.a.createElement(c.Provider,{value:t},e.children)},p={inlineCode:"code",wrapper:function(e){var t=e.children;return r.a.createElement(r.a.Fragment,{},t)}},b=r.a.forwardRef((function(e,t){var o=e.components,n=e.mdxType,i=e.originalType,a=e.parentName,c=s(e,["components","mdxType","originalType","parentName"]),d=u(o),b=n,f=d["".concat(a,".").concat(b)]||d[b]||p[b]||i;return o?r.a.createElement(f,l(l({ref:t},c),{},{components:o})):r.a.createElement(f,l({ref:t},c))}));function f(e,t){var o=arguments,n=t&&t.mdxType;if("string"==typeof e||n){var i=o.length,a=new Array(i);a[0]=b;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l.mdxType="string"==typeof e?e:n,a[1]=l;for(var c=2;c<i;c++)a[c]=o[c];return r.a.createElement.apply(null,a)}return r.a.createElement.apply(null,o)}b.displayName="MDXCreateElement"}}]);