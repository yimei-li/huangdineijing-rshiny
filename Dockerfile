FROM rocker/r-ver:4.3.2

ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    PORT=8080

# Install R packages needed
RUN R -e "install.packages('shiny', repos='https://cloud.r-project.org')"

WORKDIR /app
COPY app.R /app/app.R

# Expose default; Railway will route to $PORT
EXPOSE 8080

# Run Shiny binding to 0.0.0.0 and $PORT (Railway sets PORT)
CMD ["R", "-e", "shiny::runApp('app.R', host='0.0.0.0', port=as.numeric(Sys.getenv('PORT','8080')))" ]
