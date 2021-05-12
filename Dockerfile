FROM ubuntu:focal as bldr

RUN apt-get update
RUN apt-get install -y \
    build-essential \
    libssl-dev

WORKDIR /app/
COPY . .

RUN make

FROM alpine:latest
WORKDIR /app/
COPY --from=bldr /app/game .
ENTRYPOINT ["./game"]