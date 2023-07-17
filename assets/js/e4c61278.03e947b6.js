(window.webpackJsonp=window.webpackJsonp||[]).push([[147],{218:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return i})),n.d(t,"metadata",(function(){return l})),n.d(t,"toc",(function(){return s})),n.d(t,"default",(function(){return d}));var o=n(3),r=n(7),a=(n(0),n(232)),i={id:"docker_dev_tag",title:"How to Release a New Version of the Pipeline",sidebar_label:"Making Releases"},l={unversionedId:"devel/docker_dev_tag",id:"version-2.0.0/devel/docker_dev_tag",isDocsHomePage:!1,title:"How to Release a New Version of the Pipeline",description:"If a new version of nfdump needs to be used, make the new nfdump-collector image(s) first (see below) and update the docker-compose files with the new version number, then make new pipelineimporter and pipelinelogstash images..",source:"@site/versioned_docs/version-2.0.0/devel/tag.md",slug:"/devel/docker_dev_tag",permalink:"/netsage-pipeline/docs/devel/docker_dev_tag",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/versioned_docs/version-2.0.0/devel/tag.md",version:"2.0.0",sidebar_label:"Making Releases",sidebar:"version-2.0.0/Pipeline",previous:{title:"Revising Documentation",permalink:"/netsage-pipeline/docs/devel/docusaurus"}},s=[{value:"Make an RPM Release",id:"make-an-rpm-release",children:[]},{value:"In Github, Create a Release Tag",id:"in-github-create-a-release-tag",children:[]},{value:"To Build and Push Images Manually",id:"to-build-and-push-images-manually",children:[]},{value:"Building With Automation",id:"building-with-automation",children:[]},{value:"Test Docker Images",id:"test-docker-images",children:[]},{value:"Make Versioned Docs",id:"make-versioned-docs",children:[]},{value:"To Make New Nfdump-Collector Images",id:"to-make-new-nfdump-collector-images",children:[{value:"New Version of Logstash",id:"new-version-of-logstash",children:[]}]}],c={toc:s};function d(e){var t=e.components,n=Object(r.a)(e,["components"]);return Object(a.b)("wrapper",Object(o.a)({},c,n,{components:t,mdxType:"MDXLayout"}),Object(a.b)("p",null,"If a new version of nfdump needs to be used, make the new nfdump-collector image(s) first (see below) and update the docker-compose files with the new version number, then make new pipeline_importer and pipeline_logstash images.."),Object(a.b)("h2",{id:"make-an-rpm-release"},"Make an RPM Release"),Object(a.b)("p",null,"Use standard procedures to create an rpm of the new version of the pipeline. Update the version number and the CHANGES file, build the rpm, repoify, etc., then upgrade grnoc-netsage-deidentifier on bare-metal hosts using yum. If all works well, do the following steps to create new Docker images with which to upgrade Docker deployments."),Object(a.b)("h2",{id:"in-github-create-a-release-tag"},"In Github, Create a Release Tag"),Object(a.b)("p",null,"Create a new Tag or Release in Github, eg, v1.2.11.\nBe sure to copy info from the CHANGES file into the Release description."),Object(a.b)("h2",{id:"to-build-and-push-images-manually"},"To Build and Push Images Manually"),Object(a.b)("p",null,"Below is the procedure to build pipeline_importer and pipeline_logstash images manually."),Object(a.b)("p",null,"Install docker-compose if not done already. See the Docker Installation instructions."),Object(a.b)("p",null,"Git clone (or git pull) the pipeline project and check out the tag you want to build, then set the version number in docker-compose.build.yml using the script. Eg, for v1.2.11,"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"git clone https://github.com/netsage-project/netsage-pipeline.git\ncd netsage-pipeline\ngit checkout -b v1.2.11\n./scripts/docker_select_version.sh 1.2.11\n")),Object(a.b)("p",null,"Then build the pipeline_importer and pipeline_logstash images and push them to Docker Hub:"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"$ sudo systemctl start docker\n$ sudo docker-compose -f docker-compose.build.yml build\n$ sudo docker login\n     provide your DockerHub login credentials\n$ sudo docker-compose -f docker-compose.build.yml push    (will push images mentioned in docker-compose.yml ??)\n     or  $ docker push $image:$tag                        (will push a specific image version)\n$ sudo systemctl stop docker\n")),Object(a.b)("p",null,"If you run into an error about retrieving a mirrorlist and could not find a valid baseurl for repo, restart docker and try again.\nIf that doesn't work, try adding this to /etc/hosts: ",Object(a.b)("inlineCode",{parentName:"p"},"67.219.148.138  mirrorlist.centos.org"),", and/or try ",Object(a.b)("inlineCode",{parentName:"p"},"yum install net-tools bridge-utils"),", and/or restart network.service then docker. "),Object(a.b)("p",null,"The person pushing to Docker Hub must have a Docker Hub account and belong to the Netsage team (3 users are allowed, for the free level)."),Object(a.b)("p",null,'It might be a good idea to test the images before pushing them. See "Test Docker Images" below.'),Object(a.b)("h2",{id:"building-with-automation"},"Building With Automation"),Object(a.b)("p",null,"???"),Object(a.b)("h2",{id:"test-docker-images"},"Test Docker Images"),Object(a.b)("p",null,"See the Docker installation instructions for details... "),Object(a.b)("p",null,"In the git checkout of the correct version, make an .env file and a docker-compose.override.yml file. You probably want to send the processed data to a dev Elasticsearch instance. Use samplicate or some other method to have data sent to the dev host. "),Object(a.b)("p",null,"Run docker_select_version.sh if you haven't already, then start it up ",Object(a.b)("inlineCode",{parentName:"p"},"$ sudo docker-compose up -d"),". If there are local images, they'll be used, otherwise they'll be pulled from Docker Hub."),Object(a.b)("p",null,"After about 30 minutes, you should see flows in elasticsearch."),Object(a.b)("h2",{id:"make-versioned-docs"},"Make Versioned Docs"),Object(a.b)("p",null,"A new set of versioned docs also has to be tagged once you are done making changes for the latest pipeline version. See the ",Object(a.b)("strong",{parentName:"p"},"Docusaurus guide"),". "),Object(a.b)("h2",{id:"to-make-new-nfdump-collector-images"},"To Make New Nfdump-Collector Images"),Object(a.b)("p",null,"If a new version of nfdump has been released that we need, new nfdump-collector images need to be made."),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"$ git clone https://github.com/netsage-project/docker-nfdump-collector.git\n$ cd docker-nfdump-collector\n$ sudo systemctl start docker\n")),Object(a.b)("p",null,"To use squash: create a file at\xa0/etc/docker/daemon.json and put into it"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},' "experimental": true  \n "debug: false"\n')),Object(a.b)("p",null,"To build version $VER, eg, 1.6.23 (both regular and alpine linux versions ?):"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"$ sudo docker build --build-arg NFDUMP_VERSION=$VER  --tag netsage/nfdump-collector:$VER --squash  collector\n$ sudo docker build --build-arg NFDUMP_VERSION=$VER  --tag netsage/nfdump-collector:alpine-$VER -f collector/Dockerfile-alpine --squash .    \n")),Object(a.b)("p",null,"To push to Docker Hub and quit docker"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"$ sudo docker login\n     provide your DockerHub login credentials\n$ sudo docker push netsage/nfdump-collector:$VER\n$ sudo systemctl stop docker\n")),Object(a.b)("p",null,"To use the new collector image in the pipeline, change the version number in docker-compose.override_example.yml. For example, to use the alpine-1.6.23 image:"),Object(a.b)("pre",null,Object(a.b)("code",{parentName:"pre"},"sflow-collector:\n    image: netsage/nfdump-collector:alpine-1.6.23\n...\nnetflow-collector:\n    image: netsage/nfdump-collector:alpine-1.6.23\n")),Object(a.b)("p",null,"Remind users to make the same change in their docker-compose.override.yml file when they do the next pipeline upgrade."),Object(a.b)("h3",{id:"new-version-of-logstash"},"New Version of Logstash"),Object(a.b)("p",null,"If a new version of logstash has been released that we want everyone to use,\n???"))}d.isMDXComponent=!0},232:function(e,t,n){"use strict";n.d(t,"a",(function(){return u})),n.d(t,"b",(function(){return m}));var o=n(0),r=n.n(o);function a(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function i(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function l(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?i(Object(n),!0).forEach((function(t){a(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function s(e,t){if(null==e)return{};var n,o,r=function(e,t){if(null==e)return{};var n,o,r={},a=Object.keys(e);for(o=0;o<a.length;o++)n=a[o],t.indexOf(n)>=0||(r[n]=e[n]);return r}(e,t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);for(o=0;o<a.length;o++)n=a[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(r[n]=e[n])}return r}var c=r.a.createContext({}),d=function(e){var t=r.a.useContext(c),n=t;return e&&(n="function"==typeof e?e(t):l(l({},t),e)),n},u=function(e){var t=d(e.components);return r.a.createElement(c.Provider,{value:t},e.children)},p={inlineCode:"code",wrapper:function(e){var t=e.children;return r.a.createElement(r.a.Fragment,{},t)}},b=r.a.forwardRef((function(e,t){var n=e.components,o=e.mdxType,a=e.originalType,i=e.parentName,c=s(e,["components","mdxType","originalType","parentName"]),u=d(n),b=o,m=u["".concat(i,".").concat(b)]||u[b]||p[b]||a;return n?r.a.createElement(m,l(l({ref:t},c),{},{components:n})):r.a.createElement(m,l({ref:t},c))}));function m(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var a=n.length,i=new Array(a);i[0]=b;var l={};for(var s in t)hasOwnProperty.call(t,s)&&(l[s]=t[s]);l.originalType=e,l.mdxType="string"==typeof e?e:o,i[1]=l;for(var c=2;c<a;c++)i[c]=n[c];return r.a.createElement.apply(null,i)}return r.a.createElement.apply(null,n)}b.displayName="MDXCreateElement"}}]);