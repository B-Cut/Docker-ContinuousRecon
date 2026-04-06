FROM alpine

RUN apk add curl cron

# Enable cron service
RUN rc-update add cron

COPY ./Crontab /etc/cron.d/

WORKDIR /src
COPY ./scripts /src/scripts
RUN chmod -R +x  /src/scripts

CMD ["cron", "&&", "tail", "-f", "/var/log/cron.log"]
