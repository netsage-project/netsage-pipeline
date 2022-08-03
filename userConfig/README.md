## User Config

This directory is git ignore so it ensures any changes here are preserved.  Any user overrides should go in here and saved for the next release.

Example of user overrides would be special logstash settings that are not configured via env and so on.

Eg, you could add a custom jvm.options file here and add the following to the docker-compose.override.yml file under logstash:
     volumes:
         - ./userConfig/jvm.options:/usr/share/logstash/config/jvm.options

NOTE - don't use both environment variables in the .env file and a custom config file/volume with those settings here.




