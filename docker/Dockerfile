FROM alpine:3.15.4

RUN apk update && apk upgrade && apk add --no-cache python3 py3-pip
RUN pip install -U Flask

COPY app/app.py /app/app.py
WORKDIR /app
CMD [ "flask", "run", "--host=0.0.0.0" ]