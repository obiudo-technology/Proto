FROM alpine:3.20

WORKDIR /proto

COPY proto/ /proto/

CMD ["sh", "-c", "ls -R /proto && tail -f /dev/null"]
