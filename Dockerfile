FROM rocker/shiny:4.3.2

WORKDIR /workspace

# Copy entire repo into image (handles either root app.R or app/app.R)
COPY . /workspace

# Place app.R where Shiny Server expects it
RUN mkdir -p /srv/shiny-server/app && \
    if [ -f /workspace/app.R ]; then \
      cp /workspace/app.R /srv/shiny-server/app/app.R; \
    elif [ -f /workspace/app/app.R ]; then \
      cp /workspace/app/app.R /srv/shiny-server/app/app.R; \
    else \
      echo "No app.R found in repository root or app/" && ls -la /workspace && exit 1; \
    fi

# Copy video asset if present
RUN if [ -f /workspace/openingvideo.mp4 ]; then \
      cp /workspace/openingvideo.mp4 /srv/shiny-server/app/openingvideo.mp4; \
    fi

# Use custom Shiny Server config to serve app at root '/'
COPY shiny-server.conf /etc/shiny-server/shiny-server.conf

# Expose Shiny Server default port
EXPOSE 3838

# Start Shiny Server
CMD ["/usr/bin/shiny-server"]
