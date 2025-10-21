FROM rocker/r-ver:4.3.2

# Set default locale and port
ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    PORT=3838

# Install required R packages
RUN R -e "install.packages(c('shiny'), repos='https://cloud.r-project.org')"

# Create app dir and copy source
WORKDIR /app
COPY . /app

# Expose Shiny port (Railway sets $PORT at runtime)
EXPOSE 3838

# Run Shiny app binding to 0.0.0.0 and $PORT
CMD ["R", "-e", "shiny::runApp('app', host='0.0.0.0', port=as.numeric(Sys.getenv('PORT', '3838')))" ]


