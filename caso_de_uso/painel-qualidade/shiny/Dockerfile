FROM rocker/r-shiny:3.6.3

RUN mkdir -p /srv/shiny-server/app

COPY ./ /srv/shiny-server/app

WORKDIR /srv/shiny-server/app
RUN Rscript "renv::restore()"

EXPOSE 3838

CMD ["/usr/bin/shiny-server.sh"]