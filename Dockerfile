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
    fi && \
    printf '<!doctype html><html><head><meta http-equiv="refresh" content="0; url=/app/"></head><body>Redirecting to <a href="/app/">/app/</a>...</body></html>' > /srv/shiny-server/index.html

# Use default Shiny Server config (no custom conf)

# Expose Shiny Server default port
EXPOSE 3838

# Start Shiny Server
CMD ["/usr/bin/shiny-server"]
