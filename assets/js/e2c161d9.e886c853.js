(window.webpackJsonp=window.webpackJsonp||[]).push([[108],{179:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return o})),n.d(t,"metadata",(function(){return c})),n.d(t,"toc",(function(){return s})),n.d(t,"default",(function(){return l}));var r=n(3),a=n(7),i=(n(0),n(192)),o={id:"tstat",title:"Tstat Data Collection",sidebar_label:"Tstat Data"},c={unversionedId:"pipeline/tstat",id:"pipeline/tstat",isDocsHomePage:!1,title:"Tstat Data Collection",description:"Netsage GitHub Project",source:"@site/docs/pipeline/tstat.md",slug:"/pipeline/tstat",permalink:"/netsage-pipeline/docs/next/pipeline/tstat",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/docs/pipeline/tstat.md",version:"current",sidebar_label:"Tstat Data",sidebar:"Pipeline",previous:{title:"Intro",permalink:"/netsage-pipeline/docs/next/pipeline/intro"},next:{title:"Sflow/Netflow Data Collection",permalink:"/netsage-pipeline/docs/next/pipeline/nfdump"}},s=[{value:"Netsage GitHub Project",id:"netsage-github-project",children:[]},{value:"Docker",id:"docker",children:[]}],p={toc:s};function l(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(i.b)("wrapper",Object(r.a)({},p,n,{components:t,mdxType:"MDXLayout"}),Object(i.b)("h2",{id:"netsage-github-project"},"Netsage GitHub Project"),Object(i.b)("p",null,Object(i.b)("a",{parentName:"p",href:"http://tstat.polito.it/"},"Tstat")," is a passive sniffer that provides insights into traffic patterns.  The Netsage ",Object(i.b)("a",{parentName:"p",href:"https://github.com/netsage-project/tstat-transport"},"tstat-transport")," project provides client programs to parse the captured data and send it to a rabbitmq host where it can then be processed by the ",Object(i.b)("a",{parentName:"p",href:"logstash"},"logstash pipeline"),", stored in elasticsearch, and finally displayed in our Grafana ",Object(i.b)("a",{parentName:"p",href:"https://github.com/netsage-project/netsage-grafana-configs"},"dashboards"),"."),Object(i.b)("h2",{id:"docker"},"Docker"),Object(i.b)("p",null,"Netsage Docker images exist on Docker Hub for tstat and tstat_transport. This is still in a beta state and is in development.  The initial documentation is available ",Object(i.b)("a",{parentName:"p",href:"https://github.com/netsage-project/tstat-transport/blob/master/docs/docker.md"},"here"),".  "))}l.isMDXComponent=!0},192:function(e,t,n){"use strict";n.d(t,"a",(function(){return u})),n.d(t,"b",(function(){return f}));var r=n(0),a=n.n(r);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function o(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);t&&(r=r.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,r)}return n}function c(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?o(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):o(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function s(e,t){if(null==e)return{};var n,r,a=function(e,t){if(null==e)return{};var n,r,a={},i=Object.keys(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)n=i[r],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var p=a.a.createContext({}),l=function(e){var t=a.a.useContext(p),n=t;return e&&(n="function"==typeof e?e(t):c(c({},t),e)),n},u=function(e){var t=l(e.components);return a.a.createElement(p.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},d=a.a.forwardRef((function(e,t){var n=e.components,r=e.mdxType,i=e.originalType,o=e.parentName,p=s(e,["components","mdxType","originalType","parentName"]),u=l(n),d=r,f=u["".concat(o,".").concat(d)]||u[d]||b[d]||i;return n?a.a.createElement(f,c(c({ref:t},p),{},{components:n})):a.a.createElement(f,c({ref:t},p))}));function f(e,t){var n=arguments,r=t&&t.mdxType;if("string"==typeof e||r){var i=n.length,o=new Array(i);o[0]=d;var c={};for(var s in t)hasOwnProperty.call(t,s)&&(c[s]=t[s]);c.originalType=e,c.mdxType="string"==typeof e?e:r,o[1]=c;for(var p=2;p<i;p++)o[p]=n[p];return a.a.createElement.apply(null,o)}return a.a.createElement.apply(null,n)}d.displayName="MDXCreateElement"}}]);