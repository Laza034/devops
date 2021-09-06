FROM golang:1.16.4-alpine

WORKDIR /app

COPY go.mod ./
COPY . ./

RUN go build -o /devops_test

EXPOSE 8080

CMD [ "/devops_test" ]