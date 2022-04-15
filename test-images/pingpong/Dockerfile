FROM public.ecr.aws/bitnami/golang:latest AS build
WORKDIR /go/src/ping/
COPY pingpong.go ./
COPY go.mod ./
RUN CGO_ENABLED=0 GOOS=linux GOPROXY=direct go build -a -installsuffix cgo -o pingpong .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=build /go/src/ping/pingpong ./
EXPOSE 8080
EXPOSE 9090
CMD ["./pingpong"]
