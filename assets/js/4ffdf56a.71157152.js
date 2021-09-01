(window.webpackJsonp=window.webpackJsonp||[]).push([[35],{105:function(e,t,n){"use strict";n.r(t),n.d(t,"frontMatter",(function(){return r})),n.d(t,"metadata",(function(){return s})),n.d(t,"toc",(function(){return c})),n.d(t,"default",(function(){return u}));var o=n(3),a=n(7),i=(n(0),n(192)),r={id:"docusaurus",title:"Revising Documentation",sidebar_label:"Docusaurus"},s={unversionedId:"devel/docusaurus",id:"devel/docusaurus",isDocsHomePage:!1,title:"Revising Documentation",description:"This project's documentation uses Docusaurus.",source:"@site/docs/devel/documentation_guide.md",slug:"/devel/docusaurus",permalink:"/netsage-pipeline/docs/next/devel/docusaurus",editUrl:"https://github.com/netsage-project/netsage-pipeline/edit/master/website/docs/devel/documentation_guide.md",version:"current",sidebar_label:"Docusaurus",sidebar:"Pipeline",previous:{title:"Docker Dev Guide",permalink:"/netsage-pipeline/docs/next/devel/docker_dev_guide"},next:{title:"How to Tag a New Release",permalink:"/netsage-pipeline/docs/next/devel/docker_dev_tag"}},c=[{value:"If Not Using Docker",id:"if-not-using-docker",children:[{value:"Installation",id:"installation",children:[]},{value:"If Local Development",id:"if-local-development",children:[]},{value:"To Make Changes",id:"to-make-changes",children:[]},{value:"Tagging a New release",id:"tagging-a-new-release",children:[]},{value:"Deploying Docs to github.io",id:"deploying-docs-to-githubio",children:[]},{value:"Removing a version",id:"removing-a-version",children:[]}]},{value:"If Using Docker",id:"if-using-docker",children:[{value:"Build and Start the Container",id:"build-and-start-the-container",children:[]},{value:"To Make Changes",id:"to-make-changes-1",children:[]},{value:"Tagging a New release",id:"tagging-a-new-release-1",children:[]},{value:"Deploying Docs to github.io",id:"deploying-docs-to-githubio-1",children:[]}]}],l={toc:c};function u(e){var t=e.components,n=Object(a.a)(e,["components"]);return Object(i.b)("wrapper",Object(o.a)({},l,n,{components:t,mdxType:"MDXLayout"}),Object(i.b)("p",null,"This project's documentation uses Docusaurus."),Object(i.b)("p",null,"Docusaurus converts markdown into html and builds a static website using React UI components, which can be exported to a webserver."),Object(i.b)("p",null,"Yarn is a package manager for JavaScript and replaces the\xa0npm\xa0client. It is not strictly necessary but highly encouraged."),Object(i.b)("p",null,"To extend the docs simply create a markdown file and reference the ID in the side bar config. Please see the related documentation\nat the ",Object(i.b)("a",{parentName:"p",href:"https://v2.docusaurus.io/"},"docusaurus 2")," project website."),Object(i.b)("p",null,Object(i.b)("em",{parentName:"p"},"THE FOLLOWING INSTRUCTIONS ARE NOT CONFIRMED TO WORK. PLEASE UPDATE WITH CORRECTIONS.")),Object(i.b)("h2",{id:"if-not-using-docker"},"If Not Using Docker"),Object(i.b)("p",null,"These are instructions for editing and releasing docs without using Docker."),Object(i.b)("h3",{id:"installation"},"Installation"),Object(i.b)("p",null,"To get started the first time, install npm, then use that to install yarn "),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre"},"$ sudo yum install npm\n$ sudo npm install -g yarn \n")),Object(i.b)("p",null,"Git clone the netsage pipeline project, then run yarn install to get all the dependencies listed within package.json"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre"},"$ cd netsage-pipeline/website\n$ yarn install\n")),Object(i.b)("h3",{id:"if-local-development"},"If Local Development"),Object(i.b)("p",null,"If you are working on your local machine, rather than sshing into a host, you can view changes to the docs in a browser as you work. Use the following commands to generate the static website content (gets written into the\xa0build\xa0directory), then start a local development server and open up a browser window in which to view the docs. Most changes you make will be reflected live without having to restart the server."),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre"},"$ yarn build  \n$ yarn start\ngo to http://localhost:3000\n")),Object(i.b)("h3",{id:"to-make-changes"},"To Make Changes"),Object(i.b)("p",null,"Whether on a local machine or a linux host, to make changes, edit the files in website/docs/.\nWhen finished, git add, git commit, git push, as usual.\nRepeat as needed."),Object(i.b)("p",null,'To view the changes you\'ve made with some formatting, just go to the file on github in a browser. To see all of the formatting, read the "Deploying Docs to github.io" section below.'),Object(i.b)("h3",{id:"tagging-a-new-release"},"Tagging a New release"),Object(i.b)("p",null,"When it's time to release a new version of the Pipeline, you need to create a new version of the docs as well. "),Object(i.b)("p",null,"Once the documentation is stable and you don't forsee any new change, please do the following:"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre"},"$ yarn run docusaurus docs:version a.b.c\n")),Object(i.b)("p",null,"replacing a.b.c with the next release version number.",Object(i.b)("br",{parentName:"p"}),"\n","This will create new versioned docs in website/versioned_docs/."),Object(i.b)("p",null,"Then edit docusaurus.config.js and change ",Object(i.b)("inlineCode",{parentName:"p"},"lastVersion:")," to refer to the new version number. "),Object(i.b)("p",null,"Finally, commit and push the following to github:"),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"website/versioned_docs/version-a.b.c/"),Object(i.b)("li",{parentName:"ul"},"website/versioned_sidebars/version-a.b.c.sidebars.json"),Object(i.b)("li",{parentName:"ul"},"versions.json "),Object(i.b)("li",{parentName:"ul"},"docusaurus.config.js")),Object(i.b)("h3",{id:"deploying-docs-to-githubio"},"Deploying Docs to github.io"),Object(i.b)("p",null,'Whether you have created a new set of versioned tags or just want to update the docs in "master", to make changes appear at ',Object(i.b)("a",{parentName:"p",href:"https://netsage-project.github.io/netsage-pipeline"},"https://netsage-project.github.io/netsage-pipeline"),", do the following."),Object(i.b)("p",null,"If Travis or some other CI is working, it will run yarn install and yarn deploy to do this automatically."),Object(i.b)("p",null,"If it is not, do it manually:"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre"},'$ USE_SSH="true" GIT_USER="your-username" yarn deploy   \n')),Object(i.b)("p",null,"replacing your-username.  This sets a couple env vars then runs 'yarn deploy' which runs 'docusaurus deploy' (see package.json) which pushes the static website created to url: \"",Object(i.b)("a",{parentName:"p",href:"https://netsage-project.github.io%22"},'https://netsage-project.github.io"')," (see docusaurus.config.js) "),Object(i.b)("p",null,"NOTE: You need to have created ssh keys on the host you are running this on and added them to your github account. "),Object(i.b)("h3",{id:"removing-a-version"},"Removing a version"),Object(i.b)("p",null,"To remove version 1.2.6 of the docs, for example,"),Object(i.b)("p",null,"we need to: "),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"update versions.json to remove the reference"),Object(i.b)("li",{parentName:"ul"},"remove the versioned_docs/version-1.2.6"),Object(i.b)("li",{parentName:"ul"},"remove versioned_sidebars/version-1.2.6-sidebars.json")),Object(i.b)("h2",{id:"if-using-docker"},"If Using Docker"),Object(i.b)("p",null,"You may also use a docs Docker container to simplify installation, making changes, and deployment.  This method starts a local web server that allows you to see changes to the docs in a browser on your local machine, as they are made."),Object(i.b)("h3",{id:"build-and-start-the-container"},"Build and Start the Container"),Object(i.b)("p",null,"Git clone the netsage pipeline project then build and start the container.\nThe Dockerfile in website/ tells how to build an image that runs yarn.  Docker-compose.yml brings up a docs container."),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre"},"$ cd netsage-pipeline/website\n$ docker-compose build build_docs\n$ docker-compose up -d docs\ngo to http://localhost:8000/netsage-pipeline/\n")),Object(i.b)("h3",{id:"to-make-changes-1"},"To Make Changes"),Object(i.b)("p",null,"Whether on a local machine or a linux host, to make changes, edit the files in website/docs/.\nWhen finished, git add, git commit, git push, as usual.\nRepeat as needed."),Object(i.b)("h3",{id:"tagging-a-new-release-1"},"Tagging a New release"),Object(i.b)("p",null,"When it's time to release a new version of the Pipeline, you need to create a new version of the docs as well. "),Object(i.b)("p",null,"Once the documentation is stable and you don't forsee any new change, please do the following:"),Object(i.b)("pre",null,Object(i.b)("code",{parentName:"pre"},"$ docker-compose build build_docs\n$ docker-compose run  docs yarn run docusaurus docs:version  a.b.c\n")),Object(i.b)("p",null,"replacing a.b.c with the next release version number.",Object(i.b)("br",{parentName:"p"}),"\n","This will create new versioned docs in website/versioned_docs/."),Object(i.b)("p",null,"Then edit docusaurus.config.js and change ",Object(i.b)("inlineCode",{parentName:"p"},"lastVersion:")," to refer to the new version number. "),Object(i.b)("p",null,"Finally, commit and push the following to github:"),Object(i.b)("ul",null,Object(i.b)("li",{parentName:"ul"},"website/versioned_docs/version-a.b.c/"),Object(i.b)("li",{parentName:"ul"},"website/versioned_sidebars/version-a.b.c.sidebars.json"),Object(i.b)("li",{parentName:"ul"},"versions.json "),Object(i.b)("li",{parentName:"ul"},"docusaurus.config.js")),Object(i.b)("h3",{id:"deploying-docs-to-githubio-1"},"Deploying Docs to github.io"),Object(i.b)("p",null,"How to do this when using Docker ??? Get into the container ???"),Object(i.b)("p",null,"For now, go a linux server that has yarn installed and\nfollow the instructions under If Not Using Docker."))}u.isMDXComponent=!0},192:function(e,t,n){"use strict";n.d(t,"a",(function(){return d})),n.d(t,"b",(function(){return h}));var o=n(0),a=n.n(o);function i(e,t,n){return t in e?Object.defineProperty(e,t,{value:n,enumerable:!0,configurable:!0,writable:!0}):e[t]=n,e}function r(e,t){var n=Object.keys(e);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);t&&(o=o.filter((function(t){return Object.getOwnPropertyDescriptor(e,t).enumerable}))),n.push.apply(n,o)}return n}function s(e){for(var t=1;t<arguments.length;t++){var n=null!=arguments[t]?arguments[t]:{};t%2?r(Object(n),!0).forEach((function(t){i(e,t,n[t])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(n)):r(Object(n)).forEach((function(t){Object.defineProperty(e,t,Object.getOwnPropertyDescriptor(n,t))}))}return e}function c(e,t){if(null==e)return{};var n,o,a=function(e,t){if(null==e)return{};var n,o,a={},i=Object.keys(e);for(o=0;o<i.length;o++)n=i[o],t.indexOf(n)>=0||(a[n]=e[n]);return a}(e,t);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(o=0;o<i.length;o++)n=i[o],t.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(e,n)&&(a[n]=e[n])}return a}var l=a.a.createContext({}),u=function(e){var t=a.a.useContext(l),n=t;return e&&(n="function"==typeof e?e(t):s(s({},t),e)),n},d=function(e){var t=u(e.components);return a.a.createElement(l.Provider,{value:t},e.children)},b={inlineCode:"code",wrapper:function(e){var t=e.children;return a.a.createElement(a.a.Fragment,{},t)}},p=a.a.forwardRef((function(e,t){var n=e.components,o=e.mdxType,i=e.originalType,r=e.parentName,l=c(e,["components","mdxType","originalType","parentName"]),d=u(n),p=o,h=d["".concat(r,".").concat(p)]||d[p]||b[p]||i;return n?a.a.createElement(h,s(s({ref:t},l),{},{components:n})):a.a.createElement(h,s({ref:t},l))}));function h(e,t){var n=arguments,o=t&&t.mdxType;if("string"==typeof e||o){var i=n.length,r=new Array(i);r[0]=p;var s={};for(var c in t)hasOwnProperty.call(t,c)&&(s[c]=t[c]);s.originalType=e,s.mdxType="string"==typeof e?e:o,r[1]=s;for(var l=2;l<i;l++)r[l]=n[l];return a.a.createElement.apply(null,r)}return a.a.createElement.apply(null,n)}p.displayName="MDXCreateElement"}}]);