(window.webpackJsonp=window.webpackJsonp||[]).push([[83],{153:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return a})),n.d(t,"metadata",(function(){return p})),n.d(t,"toc",(function(){return l})),n.d(t,"default",(function(){return c}));var r=n(3),i=n(7),o=(n(0),n(232)),a={id:"importer",title:"Importer",sidebar_label:"Importer"},p={unversionedId:"pipeline/importer",id:"version-1.2.11/pipeline/importer",isDocsHomePage:!1,title:"Importer",description:'A netsage-netflow-importer script reads any new nfcapd files that have come in after a configurable delay and writes the results to the "netsagedeidentifierraw" RabbitMQ queue.',source:"@site/versioned_docs/version-1.2.11/pipeline/importer.md",slug:"/pipeline/importer",permalink:"/netsage-pipeline/docs/1.2.11/pipeline/importer",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/versioned_docs/version-1.2.11/pipeline/importer.md",version:"1.2.11",sidebar_label:"Importer",sidebar:"version-1.2.11/Pipeline",previous:{title:"Sflow/Netflow Data Collection",permalink:"/netsage-pipeline/docs/1.2.11/pipeline/nfdump"},next:{title:"Logstash Pipeline",permalink:"/netsage-pipeline/docs/1.2.11/pipeline/logstash"}},l=[{value:"Configuration",id:"configuration",children:[]}],s={toc:l};function c(e){var t=e.components,n=Object(i.a)(e,["components"]);return Object(o.b)("wrapper",Object(r.a)({},s,n,{components:t,mdxType:"MDXLayout"}),Object(o.b)("p",null,'A netsage-netflow-importer script reads any new nfcapd files that have come in after a configurable delay and writes the results to the "netsage_deidentifier_raw" RabbitMQ queue.\nAll flow data waits in the queue until it is read in and processed by the logstash pipeline.'),Object(o.b)("p",null,'To read nfcapd files, the importer uses an nfdump command with the "-a" option to aggregate raw flows within the file by the "5-tuple," i.e., the source and destination IPs, ports, and protocol. The  "-L" option is used to throw out any aggregated flows below a threshold number of bytes. This threshold is specified in the importer config file. '),Object(o.b)("h3",{id:"configuration"},"Configuration"),Object(o.b)("p",null,"Configuration files for the importer are netsage_netflow_importer.xml and netsage_shared.xml in /etc/grnoc/netsage/deidentfier/. Comments in the files briefly describe the options. See also the Deployment pages in these docs."),Object(o.b)("p",null,"To avoid re-reading nfcapd files, the importer stores the names of files that have already been read in /var/cache/netsage/netflow_importer.cache. "))}c.isMDXComponent=!0},232:function(e,t,n){"use strict";n.d(t,"a",(function(){return u})),n.d(t,"b",(function(){return m}));var r=n(0),i=n.n(r);function o(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function a(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function p(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?a(Object(n),!0).forEach((function(t){o(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):a(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,r,i=function(e,t){if(null==e)return{};var n,r,i={},o=Object.keys(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||(i[n]=e[n]);return i}(e,t);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)n=o[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(i[n]=e[n])}return i}var s=i.a.createContext({}),c=function(e){var t=i.a.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):p(p({},t),e)),n},u=function(e){var t=c(e.components);return i.a.createElement(s.Provider,{value:t},e.children)},f={inlineCode:"code",wrapper:function(e){var t=e.children;return i.a.createElement(i.a.Fragment,{},t)}},d=i.a.forwardRef((function(e,t){var n=e.components,r=e.mdxType,o=e.originalType,a=e.parentName,s=l(e,["components","mdxType","originalType","parentName"]),u=c(n),d=r,m=u["".concat(a,".").concat(d)]||u[d]||f[d]||o;return n?i.a.createElement(m,p(p({ref:t},s),{},{components:n})):i.a.createElement(m,p({ref:t},s))}));function m(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var o=n.length,a=new Array(o);a[0]=d;var p={};for(var l in t)hasOwnProperty.call(t,l)&&(p[l]=t[l]);p.originalType=e,p.mdxType="string"==typeof e?e:r,a[1]=p;for(var s=2;s<o;s++)a[s]=n[s];return i.a.createElement.apply(null,a)}return i.a.createElement.apply(null,n)}d.displayName="MDXCreateElement"}}]);