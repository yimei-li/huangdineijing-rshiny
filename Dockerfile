FROM rocker/shiny:4.3.2

# Copy app into Shiny Server app dir
COPY app.R /srv/shiny-server/app/app.R

# Expose Shiny Server default port
EXPOSE 3838

# Start Shiny Server
CMD ["/usr/bin/shiny-server"]
