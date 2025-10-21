FROM rocker/r-ver:4.3.2

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
 && rm -rf /var/lib/apt/lists/*

RUN install2.r --error --skipinstalled \
    shiny shinythemes bslib httr2 jsonlite readr stringr dplyr commonmark

WORKDIR /app

COPY app /app
COPY data /app/data
COPY openingvideo.mp4 /app/openingvideo.mp4

ENV PORT=8080
EXPOSE 8080

CMD ["R", "-e", "port <- as.numeric(Sys.getenv('PORT','8080')); shiny::runApp('/app', host='0.0.0.0', port=port)"]