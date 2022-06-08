(window.webpackJsonp=window.webpackJsonp||[]).push([[125],{196:function(e,t,r){"use strict";r.r(t),r.d(t,"frontMatter",(function(){return o})),r.d(t,"metadata",(function(){return s})),r.d(t,"toc",(function(){return p})),r.d(t,"default",(function(){return l}));var n=r(3),a=r(7),i=(r(0),r(212)),o={id:"tstat",title:"Tstat Data Export",sidebar_label:"Tstat Data"},s={unversionedId:"pipeline/tstat",id:"pipeline/tstat",isDocsHomePage:!1,title:"Tstat Data Export",description:"Netsage GitHub Project",source:"@site/docs/pipeline/tstat.md",slug:"/pipeline/tstat",permalink:"/netsage-pipeline/docs/next/pipeline/tstat",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/docs/pipeline/tstat.md",version:"current",sidebar_label:"Tstat Data",sidebar:"Pipeline",previous:{title:"Intro",permalink:"/netsage-pipeline/docs/next/pipeline/intro"},next:{title:"Sflow/Netflow Data Export",permalink:"/netsage-pipeline/docs/next/pipeline/sensors"}},p=[{value:"Netsage GitHub Project",id:"netsage-github-project",children:[]},{value:"Docker",id:"docker",children:[]}],c={toc:p};function l(e){var t=e.components,r=Object(a.a)(e,["components"]);return Object(i.b)("wrapper",Object(n.a)({},c,r,{components:t,mdxType:"MDXLayout"}),Object(i.b)("h2",{id:"netsage-github-project"},"Netsage GitHub Project"),Object(i.b)("p",null,Object(i.b)("a",{parentName:"p",href:"http://tstat.polito.it/"},"Tstat")," is a passive sniffer that provides insights into traffic patterns.  The Netsage ",Object(i.b)("a",{parentName:"p",href:"https://github.com/netsage-project/tstat-transport"},"tstat-transport")," project provides client programs to parse the captured data and send it to a rabbitmq host where it can then be processed by the ",Object(i.b)("a",{parentName:"p",href:"logstash"},"logstash pipeline"),", stored in elasticsearch, and finally displayed in our Grafana ",Object(i.b)("a",{parentName:"p",href:"https://github.com/netsage-project/netsage-grafana-configs"},"dashboards"),"."),Object(i.b)("h2",{id:"docker"},"Docker"),Object(i.b)("p",null,"Netsage Docker images exist on Docker Hub for tstat and tstat_transport. This is still in a beta state and is in development.  The initial documentation is available ",Object(i.b)("a",{parentName:"p",href:"https://github.com/netsage-project/tstat-transport/blob/master/docs/docker.md"},"here"),".  "))}l.isMDXComponent=!0},212:function(e,t,r){"use strict";r.d(t,"a",(function(){return u})),r.d(t,"b",(function(){return f}));var n=r(0),a=r.n(n);function i(e,t,r){return t in e?Object.defineProperty(e,t,{value:r,enumerable:!0,configurable:!0,writable:!0}):e[t]=r,e}function o(e,t){var r=Object.keys(e);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(e);t&&(n=n.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),r.push.apply(r,n)}return r}function s(e){for(var t=1;t<arguments.length;t++){var r=null!=arguments[t]?arguments[t]:{};t%2?o(Object(r),!0).forEach((function(t){i(e,t,r[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(r)):o(Object(r)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(r,t))}))}return e}function p(e,t){if(null==e)return{};var r,n,a=function(e,t){if(null==e)return{};var r,n,a={},i=Object.keys(e);for(n=0;n<i.length;n++)r=i[n],t.indexOf(r)>=0||(a[r]=e[r]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(n=0;n<i.length;n++)r=i[n],t.indexOf(r)>=0||Object.prototype.propertyIsEnumerable.call(e,r)&&(a[r]=e[r])}return a}var c=a.a.createContext({}),l=function(e){var t=a.a.useContext(c),r=t;return e&&(r="function"==typeof e?e(t):s(s({},t),e)),r},u=function(e){var t=l(e.components);return a.a.createElement(c.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},d=a.a.forwardRef((function(e,t){var r=e.components,n=e.mdxType,i=e.originalType,o=e.parentName,c=p(e,["components","mdxType","originalType","parentName"]),u=l(r),d=n,f=u["".concat(o,".").concat(d)]||u[d]||b[d]||i;return r?a.a.createElement(f,s(s({ref:t},c),{},{components:r})):a.a.createElement(f,s({ref:t},c))}));function f(e,t){var r=arguments,n=t&&t.mdxType;if("string"==typeof e||n){var i=r.length,o=new Array(i);o[0]=d;var s={};for(var p in t)hasOwnProperty.call(t,p)&&(s[p]=t[p]);s.originalType=e,s.mdxType="string"==typeof e?e:n,o[1]=s;for(var c=2;c<i;c++)o[c]=r[c];return a.a.createElement.apply(null,o)}return a.a.createElement.apply(null,r)}d.displayName="MDXCreateElement"}}]);