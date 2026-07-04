## Paso 1 - Creación del router Debian

Se crea una máquina virtual Debian 11 que actuará como router de la infraestructura. Esta máquina tendrá tres interfaces de red: una para la salida exterior, una conectada a la red de clientes y otra conectada a la red de servidores.

La red de clientes usa el rango 200.0.100.0/24 y la red de servidores usa el rango 10.0.0.0/24, respetando el escenario propuesto en el ejercicio.
