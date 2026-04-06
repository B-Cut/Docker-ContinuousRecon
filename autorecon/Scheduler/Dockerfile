FROM alpine

RUN apk add curl

COPY ./Crontab /etc/crontab

WORKDIR /src
COPY ./scripts /src/scripts
RUN chmod -R +x  /src/scripts

RUN crontab /etc/crontab
RUN touch /var/log/cron.log

CMD ["cron", "&&", "tail", "-f", "/var/log/cron.log"]
