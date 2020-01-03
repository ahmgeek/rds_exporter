FROM golang:1.13-alpine3.10 as builder

RUN apk update && apk add git make

COPY . /go/src/github.com/pdffillerdocker/rds_exporter/

WORKDIR /go/src/github.com/pdffillerdocker/rds_exporter

RUN mkdir vendor/github.com/percona/rds_exporter && \
    cp -r basic client config enhanced sessions vendor/github.com/percona/rds_exporter/

RUN make build

##############################################################

FROM alpine:3.10

COPY --from=builder /go/src/github.com/pdffillerdocker/rds_exporter/rds_exporter /bin/

RUN apk add --no-cache supervisor python3 && \
    python3 -m pip install pyyaml boto3==1.7.71

COPY generate_rds_list.py /etc/rds_exporter/

COPY supervisord.conf /etc/supervisord.conf

RUN echo "*/20    *       *       *       *       /etc/rds_exporter/generate_rds_list.py && supervisorctl restart rds-exporter" >> /var/spool/cron/crontabs/root

COPY entrypoint.sh /etc/rds_exporter

RUN chmod +x /etc/rds_exporter/entrypoint.sh

EXPOSE      9042
ENTRYPOINT  [ "/etc/rds_exporter/entrypoint.sh" ]
CMD [ "/usr/bin/supervisord" ]
