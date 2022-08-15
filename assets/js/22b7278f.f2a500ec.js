(window.webpackJsonp=window.webpackJsonp||[]).push([[19],{209:function(e,t,n){"use strict";n.d(t,"a",(function(){return b})),n.d(t,"b",(function(){return u}));var a=n(0),o=n.n(a);function r(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,a)}return n}function s(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){r(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,a,o=function(e,t){if(null==e)return{};var n,a,o={},r=Object.keys(e);for(a=0;a<r.length;a++)n=r[a],t.indexOf(n)>=0||(o[n]=e[n]);return o}(e,t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);for(a=0;a<r.length;a++)n=r[a],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(o[n]=e[n])}return o}var c=o.a.createContext({}),p=function(e){var t=o.a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):s(s({},t),e)),n},b=function(e){var t=p(e.components);return o.a.createElement(c.Provider,{value:t},e.children)},h={inlineCode:"code",wrapper:function(e){var t=e.children;return o.a.createElement(o.a.Fragment,{},t)}},d=o.a.forwardRef((function(e,t){var n=e.components,a=e.mdxType,r=e.originalType,i=e.parentName,c=l(e,["components","mdxType","originalType","parentName"]),b=p(n),d=a,u=b["".concat(i,".").concat(d)]||b[d]||h[d]||r;return n?o.a.createElement(u,s(s({ref:t},c),{},{components:n})):o.a.createElement(u,s({ref:t},c))}));function u(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var r=n.length,i=new Array(r);i[0]=d;var s={};for(var l in t)hasOwnProperty.call(t,l)&&(s[l]=t[l]);s.originalType=e,s.mdxType="string"==typeof e?e:a,i[1]=s;for(var c=2;c<r;c++)i[c]=n[c];return o.a.createElement.apply(null,i)}return o.a.createElement.apply(null,n)}d.displayName="MDXCreateElement"},89:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return i})),n.d(t,"metadata",(function(){return s})),n.d(t,"toc",(function(){return l})),n.d(t,"default",(function(){return p}));var a=n(3),o=n(7),r=(n(0),n(209)),i={id:"intro",title:"Intro",sidebar_label:"Intro"},s={unversionedId:"pipeline/intro",id:"pipeline/intro",isDocsHomePage:!1,title:"Intro",description:"Network Flows",source:"@site/docs/pipeline/intro.md",slug:"/pipeline/intro",permalink:"/netsage-pipeline/docs/next/pipeline/intro",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/docs/pipeline/intro.md",version:"current",sidebar_label:"Intro",sidebar:"Pipeline",next:{title:"Tstat Data Export",permalink:"/netsage-pipeline/docs/next/pipeline/tstat"}},l=[{value:"Network Flows",id:"network-flows",children:[]},{value:"Flow Export",id:"flow-export",children:[]},{value:"The NetSage Pipeline",id:"the-netsage-pipeline",children:[{value:"Pipeline Components",id:"pipeline-components",children:[]},{value:"Pipeline Installation",id:"pipeline-installation",children:[]}]},{value:"Visualization",id:"visualization",children:[]}],c={toc:l};function p(e){var t=e.components,n=Object(o.a)(e,["components"]);return Object(r.b)("wrapper",Object(a.a)({},c,n,{components:t,mdxType:"MDXLayout"}),Object(r.b)("h2",{id:"network-flows"},"Network Flows"),Object(r.b)("p",null,"As is well known, communication between two computers is accomplished by breaking up the information to be sent into packets which are forwarded through routers and switches from the source to the destination. A ",Object(r.b)("strong",{parentName:"p"},"flow")," is defined as a series of packets with common characteristics. Normally these are the source IP and port, the destination IP and port, and the protocal (the ",Object(r.b)("strong",{parentName:"p"},"5-tuple"),"). These flows can be detected and analyzed to learn about the traffic going over a certain circuit, for example. "),Object(r.b)("blockquote",null,Object(r.b)("p",{parentName:"blockquote"},'Note that when there is a "conversation" between two hosts, there will be two flows, one in each direction. Note also that determining when the flow ends is somewhat problematic. A flow ends when no more matching packets have been detected for some time, but exactly how much time? A router may declare a flow over after waiting just 15 seconds, but if one is interested in whole "conversations," a much longer time might make more sense. The source port of flows is normally ephemeral and a particular value is unlikely to be reused in a short time unless the packets are part of the same flow, but what if packets with the same 5-tuple show up after 5 or 10 or 30 minutes? Are they part of the same flow? ')),Object(r.b)("h2",{id:"flow-export"},"Flow Export"),Object(r.b)("p",null,"Network devices such as routers can function as ",Object(r.b)("strong",{parentName:"p"},"flow exporters")," by simply configuring and enabling flow collection. All or nearly all come with this capability. "),Object(r.b)("p",null,"There are three main types of flow exporters: ",Object(r.b)("strong",{parentName:"p"},Object(r.b)("a",{parentName:"strong",href:"https://www.rfc-editor.org/info/rfc3176"},"sflow")),", ",Object(r.b)("strong",{parentName:"p"},Object(r.b)("a",{parentName:"strong",href:"https://www.cisco.com/c/en/us/products/collateral/ios-nx-os-software/ios-netflow/prod_white_paper0900aecd80406232.html"},"netflow/IPFIX"),")")," and ",Object(r.b)("strong",{parentName:"p"},Object(r.b)("a",{parentName:"strong",href:"http://tstat.polito.it/"},"tstat")),". Sflow data is composed of sampled packets, while netflow (the newest version of which is IPFIX) and tstat data consists of information about series of packets (ie whole flows, or what they consider whole flows). These are described further in the following sections. "),Object(r.b)("p",null,"For Netsage, flow exporters, also referred to as ",Object(r.b)("strong",{parentName:"p"},"sensors"),", are configured to send the flow data to a ",Object(r.b)("strong",{parentName:"p"},"Netsage Pipeline host")," for processing. "),Object(r.b)("h2",{id:"the-netsage-pipeline"},"The NetSage Pipeline"),Object(r.b)("p",null,"The ",Object(r.b)("strong",{parentName:"p"},"Netsage Flow Processing Pipeline")," processes network flow data. It is comprised of several components that collect the flows, add metadata, stitch them into longer flows, etc."),Object(r.b)("h3",{id:"pipeline-components"},"Pipeline Components"),Object(r.b)("p",null,"The Netsage Flow Processing Pipeline is made of the following components"),Object(r.b)("ul",null,Object(r.b)("li",{parentName:"ul"},Object(r.b)("strong",{parentName:"li"},Object(r.b)("a",{parentName:"strong",href:"https://github.com/pmacct/pmacct"},"Pmacct")),": The pmacct package includes sfacctd and nfacctd daemons which receive sflow and netflow/IPFIX flows, respectively, and send them to a rabbitmq queue."),Object(r.b)("li",{parentName:"ul"},Object(r.b)("strong",{parentName:"li"},Object(r.b)("a",{parentName:"strong",href:"https://www.rabbitmq.com/"},"RabbitMQ")),": Rabbitmq is used for message queueing and passing at a couple of points in the full pipeline."),Object(r.b)("li",{parentName:"ul"},Object(r.b)("strong",{parentName:"li"},Object(r.b)("a",{parentName:"strong",href:"https://www.elastic.co/logstash"},"Logstash")),": A logstash pipeline pulls flow data from a rabbit queue and performs a variety of operations to transform it and add additional information.  "),Object(r.b)("li",{parentName:"ul"},Object(r.b)("strong",{parentName:"li"},Object(r.b)("a",{parentName:"strong",href:"https://www.elastic.co/what-is/elasticsearch"},"Elasticsearch")),": Elasticsearch is used for storing the final flow data. ")),Object(r.b)("h3",{id:"pipeline-installation"},"Pipeline Installation"),Object(r.b)("p",null,'Originally, the pipeline was deployed by installing all of the components individually on one or more servers (the "Bare Metal" or "Manual" Install). We still use this deployment method at IU. More recently, we\'ve also added a Docker deployment option. For simple scenerios having just one sflow and/or one netflow sensor (and any number of tstat sensors), the basic "Docker Installation" should suffice. The "Docker Advanced Options" guide will help when there are more sensors and/or other customizations required.'),Object(r.b)("h2",{id:"visualization"},"Visualization"),Object(r.b)("p",null,Object(r.b)("a",{parentName:"p",href:"https://grafana.com/oss/grafana/"},"Grafana")," or ",Object(r.b)("a",{parentName:"p",href:"https://www.elastic.co/kibana"},"Kibana")," (with appropriate credentials) can be used to visualize the data stored in elasticsearch.  Netsage grafana dashboards or ",Object(r.b)("strong",{parentName:"p"},"portals")," are set up by the IU team.  The dashboards are saved in github ",Object(r.b)("a",{parentName:"p",href:"https://github.com/netsage-project/netsage-grafana-configs"},"HERE"),"."))}p.isMDXComponent=!0}}]);