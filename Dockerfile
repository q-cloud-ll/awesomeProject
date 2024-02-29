FROM golang:1.18 as build

ENV GOPROXY http://goproxy.cn
ENV GO111MODULE on

WORKDIR /go/cache
ADD go.mod .
#ADD go.sum .
RUN go mod download

WORKDIR /go/release

ADD . .
RUN GOOS=linux CGO_ENABLED=0 go build -ldflags="-s -w -X main.__version__=1.9.0"  -installsuffix cgo -o app main.go

FROM  centos as prod

RUN mkdir -p /application/bin/ && mkdir /application/conf/ && mkdir /application/log/

COPY --from=build /go/release/app /application/bin/server
COPY --from=build /go/release/conf /application/conf/

WORKDIR /application/

EXPOSE 3000

CMD ["bin/server"]



