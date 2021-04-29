(window.webpackJsonp=window.webpackJsonp||[]).push([[12],{172:function(e,t,n){"use strict";n.d(t,"a",(function(){return p})),n.d(t,"b",(function(){return m}));var o=n(0),r=n.n(o);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function c(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function l(e,t){if(null==e)return{};var n,o,r=function(e,t){if(null==e)return{};var n,o,r={},a=Object.keys(e);for(o=0;o<a.length;o++)n=a[o],t.indexOf(n)>=0||(r[n]=e[n]);return r}(e,t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(o=0;o<a.length;o++)n=a[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(r[n]=e[n])}return r}var s=r.a.createContext({}),d=function(e){var t=r.a.useContext(s),n=t;return e&&(n="function"==typeof e?e(t):c(c({},t),e)),n},p=function(e){var t=d(e.components);return r.a.createElement(s.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return r.a.createElement(r.a.Fragment,{},t)}},u=r.a.forwardRef((function(e,t){var n=e.components,o=e.mdxType,a=e.originalType,i=e.parentName,s=l(e,["components","mdxType","originalType","parentName"]),p=d(n),u=o,m=p["".concat(i,".").concat(u)]||p[u]||b[u]||a;return n?r.a.createElement(m,c(c({ref:t},s),{},{components:n})):r.a.createElement(m,c({ref:t},s))}));function m(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var a=n.length,i=new Array(a);i[0]=u;var c={};for(var l in t)hasOwnProperty.call(t,l)&&(c[l]=t[l]);c.originalType=e,c.mdxType="string"==typeof e?e:o,i[1]=c;for(var s=2;s<a;s++)i[s]=n[s];return r.a.createElement.apply(null,i)}return r.a.createElement.apply(null,n)}u.displayName="MDXCreateElement"},82:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return i})),n.d(t,"metadata",(function(){return c})),n.d(t,"toc",(function(){return l})),n.d(t,"default",(function(){return d}));var o=n(3),r=n(7),a=(n(0),n(172)),i={id:"docker_dev_guide",title:"Docker Dev Guide",sidebar_label:"Docker Dev Guide"},c={unversionedId:"devel/docker_dev_guide",id:"devel/docker_dev_guide",isDocsHomePage:!1,title:"Docker Dev Guide",description:"Selecting a Version",source:"@site/docs/devel/docker.md",slug:"/devel/docker_dev_guide",permalink:"/netsage-pipeline/docs/next/devel/docker_dev_guide",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/docs/devel/docker.md",version:"current",sidebar_label:"Docker Dev Guide",sidebar:"Pipeline",previous:{title:"Pipeline Replay Dataset",permalink:"/netsage-pipeline/docs/next/devel/dev_dataset"},next:{title:"Revising Documentation",permalink:"/netsage-pipeline/docs/next/devel/docusaurus"}},l=[{value:"Selecting a Version",id:"selecting-a-version",children:[]},{value:"Installing",id:"installing",children:[]},{value:"Importer",id:"importer",children:[]},{value:"Build Images",id:"build-images",children:[{value:"Build Using Source Code",id:"build-using-source-code",children:[]}]},{value:"Optional: ElasticSearch and Kibana",id:"optional-elasticsearch-and-kibana",children:[]},{value:"Handy Docker Commands",id:"handy-docker-commands",children:[{value:"Start the Containers",id:"start-the-containers",children:[]},{value:"Stop the Containers",id:"stop-the-containers",children:[]},{value:"Enter a Container Shell",id:"enter-a-container-shell",children:[]},{value:"View Container Logs",id:"view-container-logs",children:[]}]}],s={toc:l};function d(e){var t=e.components,n=Object(r.a)(e,["components"]);return Object(a.b)("wrapper",Object(o.a)({},s,n,{components:t,mdxType:"MDXLayout"}),Object(a.b)("h2",{id:"selecting-a-version"},"Selecting a Version"),Object(a.b)("p",null,'You can use the "master" version or a tagged version.',Object(a.b)("br",{parentName:"p"}),"\n","To select a released version use the docker_select_version.sh script (see the Deployment Guide).\nIf you wish to use the development version (master branch) simply scip the docker_select_version.sh step."),Object(a.b)("h2",{id:"installing"},"Installing"),Object(a.b)("p",null,"See the Deployment Guide to learn how to set up collectors, your environment and override files, etc."),Object(a.b)("h2",{id:"importer"},"Importer"),Object(a.b)("p",null,'The importer "shared" config that Docker uses is defined in compose/netsage_shared.xml.  ',Object(a.b)("strong",{parentName:"p"}," NOTE: If you want to make changes to this file, you will need to rebuild the container")),Object(a.b)("h2",{id:"build-images"},"Build Images"),Object(a.b)("p",null,"The images are published on Docker Hub, but if you'd like to incorporate local changes please follow the process below."),Object(a.b)("h3",{id:"build-using-source-code"},"Build Using Source Code"),Object(a.b)("p",null,"If you would like to build the ",Object(a.b)("em",{parentName:"p"},"importer")," container using the version of the pipeline scripts found in the GitHub repo then run the following:"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose -f docker-compose.build.yml build\n\n")),Object(a.b)("p",null,"NOTE: The importer container includes the config files for the logstash pipeline. "),Object(a.b)("h2",{id:"optional-elasticsearch-and-kibana"},"Optional: ElasticSearch and Kibana"),Object(a.b)("p",null,"You can optionally store flow data locally in an ElasticSearch container and view the data with Kibana. Local storage can be enabled with the following steps:"),Object(a.b)("ol",null,Object(a.b)("li",{parentName:"ol"},"Uncomment the following lines in conf-logstash/99-outputs.conf:")),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},'elasticsearch {\n    hosts => ["elasticsearch"]\n    index => "netsage_flow-%{+YYYY.MM.dd}"\n}\n')),Object(a.b)("ol",{start:2},Object(a.b)("li",{parentName:"ol"},Object(a.b)("p",{parentName:"li"},"Comment out the ",Object(a.b)("inlineCode",{parentName:"p"},"rabbitmq {...}")," block in conf-logstash/99-outputs.conf if you do not want to also send logstash output to RabbitMQ.")),Object(a.b)("li",{parentName:"ol"},Object(a.b)("p",{parentName:"li"},"Run the containers using the following line: ",Object(a.b)("inlineCode",{parentName:"p"}," "),"  ",Object(a.b)("inlineCode",{parentName:"p"},"docker-compose -f docker-compose.yml  -f docker-compose.develop.yml up  -d"),"  ",Object(a.b)("inlineCode",{parentName:"p"}," ")))),Object(a.b)("h2",{id:"handy-docker-commands"},"Handy Docker Commands"),Object(a.b)("h3",{id:"start-the-containers"},"Start the Containers"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose up -d \n")),Object(a.b)("h3",{id:"stop-the-containers"},"Stop the Containers"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose stop && docker-compose rm \n")),Object(a.b)("h3",{id:"enter-a-container-shell"},"Enter a Container Shell"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose exec logstash bash     #bash shell in logstash container\ndocker-compose exec importer bash     #bash shell in importer container\ndocker-compose exec rabbit bash       #bash shell in rabbit container\n")),Object(a.b)("h3",{id:"view-container-logs"},"View Container Logs"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre",className:"language-sh"},"docker-compose logs -f              #view logs for all containers \ndocker-compose logs -f logstash     #view logs for logstash container\ndocker-compose logs -f importer     #view logs for importer container\ndocker-compose logs -f rabbit       #view logs for rabbit container\n")))}d.isMDXComponent=!0}}]);