FROM rocker/tidyverse:3.6.3

RUN mkdir -p /app
COPY ./ /app
WORKDIR /app
RUN Rscript -e "install.packages('renv')"
RUN Rscript -e "renv::restore()"

CMD ["RScript","/app/app.R"]
