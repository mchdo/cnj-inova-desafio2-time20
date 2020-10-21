FROM postgres:12.4

RUN apt-get update && apt-get install -y curl

COPY pt_BR /usr/share/i18n/locales/pt_BR

RUN localedef -i de_DE -c -f ISO-8859-1 -A /usr/share/i18n/locales/pt_BR pt_BR.ISO-8859-1
ENV LANG pt_BR.ISO-8859-1
RUN export LC_ALL=pt_BR
RUN echo LC_ALL=pt_BR >> /etc/environment

COPY postgresql.conf /setup/postgresql.conf