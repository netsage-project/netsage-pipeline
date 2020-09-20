module.exports = {
  Pipeline: {
    Pipeline: ["pipeline", "pipeline_importer", "pipeline_logstash"],
    Deployment: ["deploy/choose_install", "deploy/bare_metal_install"],
    Documentation: ["docusaurus"],
  },
  Docker: {
    "Deployment Guides": ["devel/docker"],
    Deployment: [
      "deploy/docker_install",
      "deploy/docker_simple",
      "deploy/docker_advanced",
      "deploy/docker_troubleshoot",
    ],
  },
};
