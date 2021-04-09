(window.webpackJsonp=window.webpackJsonp||[]).push([[75],{145:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return a})),n.d(t,"metadata",(function(){return l})),n.d(t,"toc",(function(){return c})),n.d(t,"default",(function(){return s}));var r=n(3),i=n(7),o=(n(0),n(171)),a={id:"pipeline",title:"Pipeline",sidebar_label:"Intro"},l={unversionedId:"pipeline",id:"version-1.2.5/pipeline",isDocsHomePage:!1,title:"Pipeline",description:"The NetSage Pipeline",source:"@site/versioned_docs/version-1.2.5/pipeline.md",slug:"/pipeline",permalink:"/netsage-pipeline/docs/1.2.5/pipeline",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/versioned_docs/version-1.2.5/pipeline.md",version:"1.2.5",sidebar_label:"Intro",sidebar:"version-1.2.5/Pipeline",next:{title:"Importer",permalink:"/netsage-pipeline/docs/1.2.5/pipeline_importer"}},c=[{value:"Components",id:"components",children:[]},{value:"Sensors and Data Collection",id:"sensors-and-data-collection",children:[{value:"Importer",id:"importer",children:[]}]}],p={toc:c};function s(e){var t=e.components,n=Object(i.a)(e,["components"]);return Object(o.b)("wrapper",Object(r.a)({},p,n,{components:t,mdxType:"MDXLayout"}),Object(o.b)("h1",{id:"the-netsage-pipeline"},"The NetSage Pipeline"),Object(o.b)("h1",{id:"description"},"Description"),Object(o.b)("p",null,"The Netsage Flow Processing Pipeline includes several components for processing network flow data, including importing, deidentification, metadata tagging, flow stitching, etc."),Object(o.b)("h2",{id:"components"},"Components"),Object(o.b)("p",null,"The Pipeline is made of the following components (Currently)"),Object(o.b)("ul",null,Object(o.b)("li",{parentName:"ul"},Object(o.b)("a",{parentName:"li",href:"https://github.com/netsage-project/netsage-pipeline/blob/master/lib/GRNOC/NetSage/Deidentifier/NetflowImporter.pm"},"Importer"),"  (Collection of perl scripts)",Object(o.b)("ul",{parentName:"li"},Object(o.b)("li",{parentName:"ul"},Object(o.b)("a",{parentName:"li",href:"pipeline_importer"},"doc")))),Object(o.b)("li",{parentName:"ul"},Object(o.b)("a",{parentName:"li",href:"https://www.elastic.co/logstash"},"Elastic Logstash")," Performs a variety of transformation on the data",Object(o.b)("ul",{parentName:"li"},Object(o.b)("li",{parentName:"ul"},Object(o.b)("a",{parentName:"li",href:"pipeline_logstash"},"doc")," "))),Object(o.b)("li",{parentName:"ul"},Object(o.b)("a",{parentName:"li",href:"https://www.rabbitmq.com/"},"RabbitMQ")," used for message passing and queing of tasks.")),Object(o.b)("h2",{id:"sensors-and-data-collection"},"Sensors and Data Collection"),Object(o.b)("p",null,'"Testpoints" or "sensors" collect flow data (',Object(o.b)("a",{parentName:"p",href:"http://tstat.polito.it/"},"tstat"),", ",Object(o.b)("a",{parentName:"p",href:"https://www.rfc-editor.org/info/rfc3176"},"sflow"),", or ",Object(o.b)("a",{parentName:"p",href:"https://www.cisco.com/c/en/us/products/collateral/ios-nx-os-software/ios-netflow/prod_white_paper0900aecd80406232.html"},"netflow"),') and send it to a "pipeline host" for processing (for globanoc, flow-proc.bldc.grnoc.iu.edu or netsage-probe1.grnoc.iu.edu). '),Object(o.b)("p",null,"Tstat data goes directly into the netsage_deidentifier_raw queue rabbit queue. The other data is written to nfcapd files."),Object(o.b)("h3",{id:"importer"},"Importer"),Object(o.b)("p",null,"A netsage-netflow-importer-daemon reads any new nfcapd files that have come in after a configurable delay. The importer aggregates flows within each file, and writes the results to the netsage_deidentifier_raw queue rabbit queue."))}s.isMDXComponent=!0},171:function(e,t,n){"use strict";n.d(t,"a",(function(){return b})),n.d(t,"b",(function(){return f}));var r=n(0),i=n.n(r);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function a(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?a(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):a(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function c(e,t){if(null==e)return{};var n,r,i=function(e,t){if(null==e)return{};var n,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||(i[n]=e[n]);return i}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(i[n]=e[n])}return i}var p=i.a.createContext({}),s=function(e){var t=i.a.useContext(p),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},b=function(e){var t=s(e.components);return i.a.createElement(p.Provider,{value:t},e.children)},u={inlineCode:"code",wrapper:function(e){var t=e.children;return i.a.createElement(i.a.Fragment,{},t)}},d=i.a.forwardRef((function(e,t){var n=e.components,r=e.mdxType,o=e.originalType,a=e.parentName,p=c(e,["components","mdxType","originalType","parentName"]),b=s(n),d=r,f=b["".concat(a,".").concat(d)]||b[d]||u[d]||o;return n?i.a.createElement(f,l(l({ref:t},p),{},{components:n})):i.a.createElement(f,l({ref:t},p))}));function f(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var o=n.length,a=new Array(o);a[0]=d;var l={};for(var c in t)hasOwnProperty.call(t,c)&&(l[c]=t[c]);l.originalType=e,l.mdxType="string"==typeof e?e:r,a[1]=l;for(var p=2;p<o;p++)a[p]=n[p];return i.a.createElement.apply(null,a)}return i.a.createElement.apply(null,n)}d.displayName="MDXCreateElement"}}]);