FROM kong:3.2.2-ubuntu
USER root
# ADD kong-plugin-log-gelf /custom-plugins/log-gelf

# WORKDIR /custom-plugins/log-gelf
# RUN ls -R .
# RUN luarocks install kong-plugin-log-gelf-0.0.1-1.all.rock
# RUN luarocks show

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8000 8443 8001 8444

STOPSIGNAL SIGTERM
USER kong
CMD ["kong", "docker-start"]