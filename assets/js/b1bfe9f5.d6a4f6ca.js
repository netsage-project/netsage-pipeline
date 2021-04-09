(window.webpackJsonp=window.webpackJsonp||[]).push([[68],{138:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return i})),n.d(t,"metadata",(function(){return s})),n.d(t,"toc",(function(){return p})),n.d(t,"default",(function(){return l}));var r=n(3),o=n(7),a=(n(0),n(171)),i={id:"nfdump",title:"Nfdump",sidebar_label:"Nfdump"},s={unversionedId:"pipeline/nfdump",id:"version-1.2.8/pipeline/nfdump",isDocsHomePage:!1,title:"Nfdump",description:"Nfdump is a toolset used to collect and process netflow and sflow data that is sent from netflow/sflow compatible devices. The toolset supports netflow v1, v5/v7, v9, IPFIX and SFLOW. Nfdump supports IPv4 as well as IPv6.",source:"@site/versioned_docs/version-1.2.8/pipeline/nfdump.md",slug:"/pipeline/nfdump",permalink:"/netsage-pipeline/docs/1.2.8/pipeline/nfdump",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/versioned_docs/version-1.2.8/pipeline/nfdump.md",version:"1.2.8",sidebar_label:"Nfdump",sidebar:"version-1.2.8/Pipeline",previous:{title:"Tstat",permalink:"/netsage-pipeline/docs/1.2.8/pipeline/tstat"},next:{title:"Importer",permalink:"/netsage-pipeline/docs/1.2.8/pipeline/importer"}},p=[{value:"Netsage Usage",id:"netsage-usage",children:[]},{value:"Docker Deployment",id:"docker-deployment",children:[]}],c={toc:p};function l(e){var t=e.components,n=Object(o.a)(e,["components"]);return Object(a.b)("wrapper",Object(r.a)({},c,n,{components:t,mdxType:"MDXLayout"}),Object(a.b)("p",null,"Nfdump is a toolset used to collect and process netflow and sflow data that is sent from netflow/sflow compatible devices. The toolset supports netflow v1, v5/v7, v9, IPFIX and SFLOW. Nfdump supports IPv4 as well as IPv6."),Object(a.b)("h2",{id:"netsage-usage"},"Netsage Usage"),Object(a.b)("p",null,"The nfdump utility (nfcapd and/or sfcapd processes) is used to collect incoming netflow and sflow data and save it to disk (as nfcapd files).  The files are then processed by the ",Object(a.b)("a",{parentName:"p",href:"importer"},"importer"),", which uses an nfdump command, and sent to RabbitMQ. From there, the ",Object(a.b)("a",{parentName:"p",href:"logstash"},"logstash")," pipeline ingests the flows and processes them in exactly the same way as it processes tstat flows.  The data is eventually saved in elasticsearch and visualized by ",Object(a.b)("a",{parentName:"p",href:"https://github.com/netsage-project/netsage-grafana-configs"},"grafana dashboards"),"."),Object(a.b)("p",null,"One may also use the nfdump command interactively to view the flows in a nfcapd file in a terminal window."),Object(a.b)("h2",{id:"docker-deployment"},"Docker Deployment"),Object(a.b)("p",null,"The nfdump processes can be invoked locally or using a Docker container.  The Docker Deployment Guide walks you through utilizing the Docker container.  The Docker image definitions can be found ",Object(a.b)("a",{parentName:"p",href:"https://github.com/netsage-project/docker-nfdump-collector"},"HERE")))}l.isMDXComponent=!0},171:function(e,t,n){"use strict";n.d(t,"a",(function(){return d})),n.d(t,"b",(function(){return m}));var r=n(0),o=n.n(r);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function s(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function p(e,t){if(null==e)return{};var n,r,o=function(e,t){if(null==e)return{};var n,r,o={},a=Object.keys(e);for(r=0;r<a.length;r++)n=a[r],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(r=0;r<a.length;r++)n=a[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}var c=o.a.createContext({}),l=function(e){var t=o.a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):s(s({},t),e)),n},d=function(e){var t=l(e.components);return o.a.createElement(c.Provider,{value:t},e.children)},u={inlineCode:"code",wrapper:function(e){var t=e.children;return o.a.createElement(o.a.Fragment,{},t)}},f=o.a.forwardRef((function(e,t){var n=e.components,r=e.mdxType,a=e.originalType,i=e.parentName,c=p(e,["components","mdxType","originalType","parentName"]),d=l(n),f=r,m=d["".concat(i,".").concat(f)]||d[f]||u[f]||a;return n?o.a.createElement(m,s(s({ref:t},c),{},{components:n})):o.a.createElement(m,s({ref:t},c))}));function m(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var a=n.length,i=new Array(a);i[0]=f;var s={};for(var p in t)hasOwnProperty.call(t,p)&&(s[p]=t[p]);s.originalType=e,s.mdxType="string"==typeof e?e:r,i[1]=s;for(var c=2;c<a;c++)i[c]=n[c];return o.a.createElement.apply(null,i)}return o.a.createElement.apply(null,n)}f.displayName="MDXCreateElement"}}]);