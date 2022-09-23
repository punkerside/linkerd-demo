FROM alpine:3.16.2

# instalando paquetes
RUN apk update && apk upgrade && apk add --no-cache python3 py3-pip
RUN pip install -U Flask requests

# creando usuario noroot
RUN adduser --disabled-password --uid 10000 noroot
USER noroot

# configurando entorno
COPY app/app.py /app/app.py
WORKDIR /app
CMD [ "flask", "run", "--host=0.0.0.0" ]