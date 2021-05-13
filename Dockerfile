FROM ubuntu:focal as bldr

RUN apt-get update
RUN apt-get install -y \
    build-essential \
    libssl-dev

WORKDIR /app/
COPY . .

RUN make

FROM frolvlad/alpine-glibc

RUN apk update
RUN apk add \
    openssl

WORKDIR /app/
COPY --from=bldr /app/game .
COPY --from=bldr /app/data ./data
RUN openssl genrsa -out data/game.pem 1024
ENTRYPOINT ["./game"]