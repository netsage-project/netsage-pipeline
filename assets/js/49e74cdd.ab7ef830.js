(window.webpackJsonp=window.webpackJsonp||[]).push([[38],{108:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return r})),n.d(t,"metadata",(function(){return l})),n.d(t,"toc",(function(){return s})),n.d(t,"default",(function(){return c}));var a=n(3),i=n(7),o=(n(0),n(212)),r={id:"intro",title:"Intro",sidebar_label:"Intro"},l={unversionedId:"pipeline/intro",id:"version-1.2.10/pipeline/intro",isDocsHomePage:!1,title:"Intro",description:"The NetSage Pipeline",source:"@site/versioned_docs/version-1.2.10/pipeline/intro.md",slug:"/pipeline/intro",permalink:"/netsage-pipeline/docs/1.2.10/pipeline/intro",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/versioned_docs/version-1.2.10/pipeline/intro.md",version:"1.2.10",sidebar_label:"Intro",sidebar:"version-1.2.10/Pipeline",next:{title:"Tstat Data Collection",permalink:"/netsage-pipeline/docs/1.2.10/pipeline/tstat"}},s=[{value:"Description",id:"description",children:[]},{value:"Data Collection",id:"data-collection",children:[]},{value:"Pipeline Components",id:"pipeline-components",children:[]},{value:"Visualization",id:"visualization",children:[]},{value:"Pipeline Installation",id:"pipeline-installation",children:[]}],p={toc:s};function c(e){var t=e.components,n=Object(i.a)(e,["components"]);return Object(o.b)("wrapper",Object(a.a)({},p,n,{components:t,mdxType:"MDXLayout"}),Object(o.b)("h1",{id:"the-netsage-pipeline"},"The NetSage Pipeline"),Object(o.b)("h2",{id:"description"},"Description"),Object(o.b)("p",null,'The Netsage Flow Processing Pipeline is composed of several components for processing network flow data, including importing, deidentification, metadata tagging, flow stitching, etc.\nThere are many ways the components can be combined, configured, and run. These documents will describe the standard "simple" set up and provide information for more complex configurations.'),Object(o.b)("h2",{id:"data-collection"},"Data Collection"),Object(o.b)("p",null,"In Netsage, sensor(s) are network devices configured to collect flow data (",Object(o.b)("a",{parentName:"p",href:"http://tstat.polito.it/"},"tstat"),", ",Object(o.b)("a",{parentName:"p",href:"https://www.rfc-editor.org/info/rfc3176"},"sflow"),", or ",Object(o.b)("a",{parentName:"p",href:"https://www.cisco.com/c/en/us/products/collateral/ios-nx-os-software/ios-netflow/prod_white_paper0900aecd80406232.html"},"netflow"),') and send it to a "pipeline host" for processing. '),Object(o.b)("p",null,"Tstat flow data can be sent directly to the pipeline ingest RabbitMQ queue on the pipeline host using the Netsage ",Object(o.b)("a",{parentName:"p",href:"https://github.com/netsage-project/tstat-transport"},"tstat-transport")," tool. This can be installed as usual or via Docker. "),Object(o.b)("p",null,"Sflow and netflow data from configured routers should be sent to the pipeline host where it is collected and stored into nfcapd files using ",Object(o.b)("a",{parentName:"p",href:"https://github.com/phaag/nfdump"},"nfdump tools"),". The Netsage project has packaged the nfdump tools into a ",Object(o.b)("a",{parentName:"p",href:"https://github.com/netsage-project/docker-nfdump-collector"},"Docker container")," for ease of use."),Object(o.b)("h2",{id:"pipeline-components"},"Pipeline Components"),Object(o.b)("p",null,"The Netsage Flow Processing Pipeline is made of the following components"),Object(o.b)("ul",null,Object(o.b)("li",{parentName:"ul"},"Importer:  Perl scripts on the pipeline host that read nfcapd flow files and send the flow data to a RabbitMQ queue.   (",Object(o.b)("a",{parentName:"li",href:"/netsage-pipeline/docs/1.2.10/pipeline/importer"},"Doc"),", ",Object(o.b)("a",{parentName:"li",href:"https://github.com/netsage-project/netsage-pipeline/blob/master/lib/GRNOC/NetSage/Deidentifier/NetflowImporter.pm"},"in github"),")"),Object(o.b)("li",{parentName:"ul"},Object(o.b)("a",{parentName:"li",href:"https://www.rabbitmq.com/"},"RabbitMQ"),": Used for message passing and queuing of tasks."),Object(o.b)("li",{parentName:"ul"},Object(o.b)("a",{parentName:"li",href:"https://www.elastic.co/logstash"},"Logstash")," pipeline: Performs a variety of operations on the flow data to transform it and add additional information.  (",Object(o.b)("a",{parentName:"li",href:"/netsage-pipeline/docs/1.2.10/pipeline/logstash"},"Doc"),")"),Object(o.b)("li",{parentName:"ul"},Object(o.b)("a",{parentName:"li",href:"https://www.elastic.co/what-is/elasticsearch"},"Elasticsearch"),": Used for storing the final flow data. ")),Object(o.b)("h2",{id:"visualization"},"Visualization"),Object(o.b)("p",null,Object(o.b)("a",{parentName:"p",href:"https://grafana.com/oss/grafana/"},"Grafana")," or ",Object(o.b)("a",{parentName:"p",href:"https://www.elastic.co/kibana"},"Kibana")," can be used to visualize the data stored in elasticsearch.  Netsage Grafana Dashboards are available ",Object(o.b)("a",{parentName:"p",href:"https://github.com/netsage-project/netsage-grafana-configs"},"in github"),"."),Object(o.b)("h2",{id:"pipeline-installation"},"Pipeline Installation"),Object(o.b)("p",null,'Originally, the pipeline was deployed by installing all of the components individually on one or more servers (the "BareMetal" or "Manual" Install). More recently, we\'ve also added a Docker deployment option. With simple pipelines having just one sflow and/or one netflow sensor (and any number of tstat sensors), the basic "Docker Installation" should suffice. The "Docker Advanced Options" guide will help when there are more sensors and/or other customizations required.'))}c.isMDXComponent=!0},212:function(e,t,n){"use strict";n.d(t,"a",(function(){return d})),n.d(t,"b",(function(){return f}));var a=n(0),i=n.n(a);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function r(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);t&&(a=a.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,a)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?r(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):r(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function s(e,t){if(null==e)return{};var n,a,i=function(e,t){if(null==e)return{};var n,a,i={},o=Object.keys(e);for(a=0;a<o.length;a++)n=o[a],t.indexOf(n)>=0||(i[n]=e[n]);return i}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(a=0;a<o.length;a++)n=o[a],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(i[n]=e[n])}return i}var p=i.a.createContext({}),c=function(e){var t=i.a.useContext(p),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},d=function(e){var t=c(e.components);return i.a.createElement(p.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return i.a.createElement(i.a.Fragment,{},t)}},u=i.a.forwardRef((function(e,t){var n=e.components,a=e.mdxType,o=e.originalType,r=e.parentName,p=s(e,["components","mdxType","originalType","parentName"]),d=c(n),u=a,f=d["".concat(r,".").concat(u)]||d[u]||b[u]||o;return n?i.a.createElement(f,l(l({ref:t},p),{},{components:n})):i.a.createElement(f,l({ref:t},p))}));function f(e,t){var n=arguments,a=t&&t.mdxType;if("string"==typeof e||a){var o=n.length,r=new Array(o);r[0]=u;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l.mdxType="string"==typeof e?e:a,r[1]=l;for(var p=2;p<o;p++)r[p]=n[p];return i.a.createElement.apply(null,r)}return i.a.createElement.apply(null,n)}u.displayName="MDXCreateElement"}}]);