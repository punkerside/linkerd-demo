1. Iniciando cluster de Kubernetes:

```console
make minikube
```

2. Desplegando aplicacion:

```console
make release DOCKER_USER=${DOCKER_USER} DOCKER_PASS=${DOCKER_PASS}
make deploy DOCKER_USER=${DOCKER_USER}
```

Para validar el servicio desplegado:

```console
kubectl port-forward svc/linkerd-lab-a 8080:80
```

http://localhost:8080/status

http://localhost:8080/mesh/linkerd-lab-b

3. Instalando Linkerd:

```console
make linkerd
```

4. Agregando aplicacion de prueba a la malla de servicio:

```console
make mesh
```

Para validar el funcionamiento de la malla:

```console
linkerd viz tap deploy/linkerd-lab-a
```