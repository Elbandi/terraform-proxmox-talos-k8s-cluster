FROM alpine

RUN apk add --no-cache lvm2

ADD --chmod=755 init.sh /

ADD --chmod=755 report.sh /

CMD ["/report.sh"]
