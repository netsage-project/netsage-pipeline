const remarkImages = require("remark-images");

module.exports = {
  title: "Netsage Pipeline Documentation",
  tagline: "Netsage Pipeline Documentation",
  url: "https://netsage-project.github.io",
  baseUrl: "/netsage-pipeline/",
  favicon: "img/favicon.ico",
  organizationName: "netsage-project", // Usually your GitHub org/user name.
  projectName: "netsage-pipeline", // Usually your repo name.
  themeConfig: {
    navbar: {
      title: "NetSage Pipeline Documentation",
      logo: {
        alt: "NetSage Logo",
        src: "img/logo.png",
      },
      items: [
        {
          label: "Pipeline Documentation",
          position: "left",
          items: [
            {
              label: "Pipeline Documentation",
              position: "left",
              activeBasePath: "docs",
              to: "docs/pipeline",
            },
            {
              label: "Docker Guide",
              position: "left",
              activeBasePath: "docs",
              to: "docs/devel/docker",
            },
          ],
        },
        {
          href: "https://netsage-project.github.io/netsage-grafana-configs/",
          label: "Dashboard Documentation",
          position: "left",
          target: "_self",
        },
        {
          href: "https://github.com/netsage-project/netsage-pipeline/",
          label: "GitHub",
          position: "right",
        },
      ],
    },
    footer: {
      style: "dark",
      links: [],
      copyright: `Copyright © ${new Date().getFullYear()} NetSage Built with Docusaurus.`,
    },
  },
  presets: [
    [
      "@docusaurus/preset-classic",
      {
        docs: {
          remarkPlugins: [require("remark-import-partial")],
          sidebarPath: require.resolve("./sidebars.js"),
          // Please change this to your repo.
          editUrl:
            "https://github.com/netsage-project/netsage-pipeline/edit/master/",
        },
        blog: {
          showReadingTime: true,
          // Please change this to your repo.
          editUrl:
            "https://github.com/netsage-project/netsage-pipeline/edit/master/blog/",
        },
        theme: {
          customCss: require.resolve("./src/css/custom.css"),
        },
      },
    ],
  ],
};
