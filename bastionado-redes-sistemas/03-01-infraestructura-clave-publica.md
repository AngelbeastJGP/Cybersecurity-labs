# 3.1 - Creacion de una infraestructura de clave publica (PKI)

## Resumen

En esta practica se construye una infraestructura de clave publica con OpenSSL.
La jerarquia contiene una autoridad certificadora raiz, una CA subordinada y un
certificado final para el servicio HTTPS de Apache.

El cliente `PC2` instala como confiable el certificado publico de la CA raiz y
valida el servicio completo:

```text
Garea Root CA
└── Garea Subordinate CA
    └── Certificado HTTPS de srv-alma.garea.local (10.0.0.20)
```

## Objetivos

- Crear una CA raiz local con una clave privada protegida.
- Mantener la CA raiz fuera de linea tras emitir la CA subordinada.
- Crear una CA subordinada con capacidad para emitir certificados.
- Emitir un certificado TLS de servidor con nombre DNS y direccion IP.
- Configurar Apache para presentar el certificado y su cadena.
- Instalar la confianza raiz en un cliente Debian.
- Validar la cadena, la identidad del servidor y el acceso HTTPS.

## Maquinas utilizadas

| Equipo | Sistema | Rol | IP |
| --- | --- | --- | --- |
| CA-RAIZ | AlmaLinux 9 | Autoridad certificadora raiz | `10.0.0.30` |
| SRV-ALMA | AlmaLinux 9 | CA subordinada y servidor Apache | `10.0.0.20` |
| SRV-WINDOWS | Windows Server 2022 | Servidor DNS para resolver nombres y acceder a los repositorios | `10.0.0.10` |
| PC2 | Debian 11 | Cliente que valida el servicio | `200.0.100.102` |
| R-DEBIAN | Debian 11 | Enrutamiento entre redes | `10.0.0.1` y `200.0.100.1` |

La VM `CA-RAIZ` se obtuvo mediante un clon completo de AlmaLinux, con una nueva
direccion MAC, nombre propio e IP distinta. Una vez emitida la CA subordinada se
apaga para reducir la exposicion de su clave privada.

`SRV-WINDOWS` tambien se mantuvo encendido como DNS del laboratorio. Su funcion
en esta practica fue resolver los nombres necesarios para que AlmaLinux pudiera
consultar los repositorios e instalar paquetes como `mod_ssl`; no almaceno ni
emitio certificados de la PKI.

## 1. Preparacion de la CA raiz

Se comprueban la identidad y conectividad de la maquina:

```bash
hostname
ip -br a
ping -c 2 10.0.0.1
openssl version
```

`hostname` identifica el equipo, `ip -br a` resume sus interfaces, `ping`
comprueba la red y `openssl version` confirma que OpenSSL esta disponible.

Se crea la estructura de trabajo:

```bash
mkdir -p /root/ca/{certs,crl,newcerts,private}
chmod 700 /root/ca/private
touch /root/ca/index.txt
echo 1000 > /root/ca/serial
```

- `mkdir -p` crea los directorios de certificados, revocaciones, certificados
  emitidos y claves privadas.
- `chmod 700` permite que solo `root` acceda al directorio privado.
- `index.txt` queda preparado como base de datos de certificados.
- `serial` establece el primer numero de serie que puede usar la CA.

Se genera una clave RSA de 4096 bits cifrada con AES-256:

```bash
openssl genpkey -algorithm RSA -aes-256-cbc \
  -pkeyopt rsa_keygen_bits:4096 \
  -out /root/ca/private/ca.key.pem
chmod 400 /root/ca/private/ca.key.pem
```

`genpkey` genera la clave privada; `-aes-256-cbc` obliga a protegerla mediante
frase de paso y `chmod 400` la deja en modo de solo lectura para `root`.

El certificado raiz se autofirma porque no existe una autoridad superior:

```bash
openssl req -x509 -new -sha256 -days 3650 \
  -key /root/ca/private/ca.key.pem \
  -out /root/ca/certs/ca-raiz.cert.pem \
  -subj "/C=ES/O=Garea Lab/OU=PKI/CN=Garea Root CA" \
  -addext "basicConstraints=critical,CA:TRUE,pathlen:1" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -addext "subjectKeyIdentifier=hash"
```

- `req -x509` crea directamente un certificado autofirmado.
- `-sha256` selecciona el algoritmo de resumen para la firma.
- `-days 3650` establece una vigencia de diez anos.
- `CA:TRUE` declara que el certificado pertenece a una CA.
- `pathlen:1` permite una unica CA subordinada por debajo de la raiz.
- `keyCertSign` y `cRLSign` limitan su uso a firmar certificados y listas de
  revocacion.

## 2. Creacion de la CA subordinada

En `SRV-ALMA` se prepara una estructura separada:

```bash
mkdir -p /root/ca-sub/{certs,crl,csr,newcerts,private}
chmod 700 /root/ca-sub/private
touch /root/ca-sub/index.txt
echo 2000 > /root/ca-sub/serial
```

Se genera otra clave privada protegida, independiente de la raiz:

```bash
openssl genpkey -algorithm RSA -aes-256-cbc \
  -pkeyopt rsa_keygen_bits:4096 \
  -out /root/ca-sub/private/ca-sub.key.pem
chmod 400 /root/ca-sub/private/ca-sub.key.pem
```

En el laboratorio el archivo se guardo accidentalmente como `ca.sub.key.pem`.
Los comandos posteriores se adaptaron a ese nombre sin regenerar la clave.

Se crea una solicitud de firma o CSR:

```bash
openssl req -new -sha256 \
  -key /root/ca-sub/private/ca-sub.key.pem \
  -out /root/ca-sub/csr/ca-sub.csr.pem \
  -subj "/C=ES/O=Garea Lab/OU=PKI/CN=Garea Subordinate CA"
```

La CSR contiene la identidad y la clave publica de la subordinada, pero nunca
su clave privada. Se comprueba antes de firmarla:

```bash
openssl req -in /root/ca-sub/csr/ca-sub.csr.pem \
  -noout -subject -verify
```

La transferencia por `scp` fue rechazada porque `CA-RAIZ` solo admitia claves
SSH autorizadas. Al ser publica la CSR, se traslado temporalmente mediante HTTP:

```bash
# En SRV-ALMA
cp /root/ca-sub/csr/ca-sub.csr.pem /var/www/html/
chmod 644 /var/www/html/ca-sub.csr.pem

# En CA-RAIZ
curl http://10.0.0.20/ca-sub.csr.pem -o /root/ca/ca-sub.csr.pem
openssl req -in /root/ca/ca-sub.csr.pem -noout -subject -verify
```

`curl -o` descarga la CSR con el nombre indicado y la segunda orden verifica su
firma interna antes de confiar en el archivo recibido.

En `CA-RAIZ` se define la extension de una CA intermedia:

```ini
[v3_intermediate_ca]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
```

`pathlen:0` permite a la subordinada emitir certificados finales, pero evita que
cree otra CA por debajo de ella.

La CA raiz firma la CSR:

```bash
openssl x509 -req -in /root/ca/ca-sub.csr.pem \
  -CA /root/ca/certs/ca-raiz.cert.pem \
  -CAkey /root/ca/private/ca.key.pem \
  -CAcreateserial \
  -out /root/ca/certs/ca-sub.cert.pem \
  -days 1825 -sha256 \
  -extfile /root/ca/subordinate.ext \
  -extensions v3_intermediate_ca
```

- `-CA` selecciona el certificado publico de la raiz.
- `-CAkey` selecciona la clave privada que realiza la firma.
- `-CAcreateserial` genera un numero de serie para el certificado emitido.
- `-extfile` aplica las restricciones de CA subordinada.

Se valida el primer tramo de la cadena:

```bash
openssl verify \
  -CAfile /root/ca/certs/ca-raiz.cert.pem \
  /root/ca/certs/ca-sub.cert.pem
```

El resultado fue `ca-sub.cert.pem: OK`.

Los dos certificados publicos se copiaron a `SRV-ALMA`. La clave privada de la
raiz nunca abandono `CA-RAIZ`. Tras completar esta emision, la CA raiz se apago.

## 3. Certificado para el servicio HTTPS

En `SRV-ALMA` se crea una clave RSA de 2048 bits para Apache:

```bash
openssl genpkey -algorithm RSA \
  -pkeyopt rsa_keygen_bits:2048 \
  -out /etc/pki/tls/private/srv-alma.key.pem
chmod 600 /etc/pki/tls/private/srv-alma.key.pem
```

Esta clave no usa frase de paso para que Apache pueda arrancar sin intervencion
manual. Se protege mediante permisos y acceso administrativo al servidor.

Se genera la CSR del servicio:

```bash
openssl req -new -sha256 \
  -key /etc/pki/tls/private/srv-alma.key.pem \
  -out /root/ca-sub/csr/srv-alma.csr.pem \
  -subj "/C=ES/O=Garea Lab/OU=Servicios/CN=srv-alma.garea.local"
```

El archivo `/root/ca-sub/server.ext` define un certificado final de servidor:

```ini
[server_cert]
basicConstraints = critical, CA:false
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = srv-alma.garea.local
DNS.2 = SRV-alma9
IP.1 = 10.0.0.20
```

`CA:false` impide usar el certificado como autoridad certificadora,
`serverAuth` lo limita a autenticacion de servidor y SAN declara las identidades
DNS e IP que los clientes pueden aceptar.

La CA subordinada firma el certificado del servicio. En el laboratorio se uso
el nombre real `ca.sub.key.pem` de su clave:

```bash
openssl x509 -req -in /root/ca-sub/csr/srv-alma.csr.pem \
  -CA /root/ca-sub/certs/ca-sub.cert.pem \
  -CAkey /root/ca-sub/private/ca.sub.key.pem \
  -CAcreateserial \
  -out /etc/pki/tls/certs/srv-alma.cert.pem \
  -days 825 -sha256 \
  -extfile /root/ca-sub/server.ext \
  -extensions server_cert
```

Se verifica la cadena completa usando la raiz como ancla de confianza y la
subordinada como certificado intermedio:

```bash
openssl verify \
  -CAfile /root/ca-sub/certs/ca-raiz.cert.pem \
  -untrusted /root/ca-sub/certs/ca-sub.cert.pem \
  /etc/pki/tls/certs/srv-alma.cert.pem
```

El resultado fue `srv-alma.cert.pem: OK`. Tambien se revisaron identidad, emisor
y vigencia:

```bash
openssl x509 -in /etc/pki/tls/certs/srv-alma.cert.pem \
  -noout -subject -issuer -dates
```

## 4. Configuracion de Apache con TLS

Se instala el modulo SSL:

```bash
dnf install mod_ssl -y
```

Apache debe presentar el certificado final y el intermedio. Por ello se crea un
archivo de cadena completa:

```bash
cp /etc/pki/tls/certs/srv-alma.cert.pem \
  /etc/pki/tls/certs/srv-alma-fullchain.pem
cat /root/ca-sub/certs/ca-sub.cert.pem \
  >> /etc/pki/tls/certs/srv-alma-fullchain.pem
chmod 644 /etc/pki/tls/certs/srv-alma-fullchain.pem
restorecon -Rv /etc/pki/tls/
```

`restorecon` aplica los contextos SELinux esperados en las rutas de certificados
y claves. En `/etc/httpd/conf.d/ssl.conf` se configuran:

```apache
SSLCertificateFile /etc/pki/tls/certs/srv-alma-fullchain.pem
SSLCertificateKeyFile /etc/pki/tls/private/srv-alma.key.pem
```

Se reinicia Apache y se abre HTTPS en el cortafuegos:

```bash
systemctl restart httpd
systemctl status httpd
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
ss -lntp | grep :443
```

`systemctl` aplica y comprueba la configuracion; `firewall-cmd` permite HTTPS de
forma persistente y `ss` confirma que Apache escucha en el puerto TCP 443.

Para obtener una respuesta HTTP normal se creo `/var/www/html/index.html`, se
ajustaron sus permisos y se restauro su contexto SELinux:

```bash
chmod 644 /var/www/html/index.html
restorecon -Rv /var/www/html/
systemctl reload httpd
```

## 5. Confianza y validacion desde PC2

El certificado raiz es publico y se copia al almacen de confianza de Debian:

```bash
cp ~/garea-root-ca.pem \
  /usr/local/share/ca-certificates/garea-root-ca.crt
/usr/sbin/update-ca-certificates
```

`update-ca-certificates` incorpora la raiz al conjunto de autoridades en las que
confia el sistema. No se instala la clave privada ni se confia directamente en
el certificado del servidor.

La prueba final se realiza con:

```bash
curl -v -o /dev/null https://10.0.0.20
```

La salida confirma simultaneamente:

```text
subjectAltName: host "10.0.0.20" matched cert's IP address
issuer: Garea Subordinate CA
SSL certificate verify ok
HTTP/1.1 200 OK
```

## Incidencias y aprendizaje

### Certificado raiz y clave privada no coincidentes

Durante el proceso se detecto el error `CA certificate and CA private key do not
match`. Los modulos de ambas claves se compararon mediante:

```bash
openssl rsa -in /root/ca/private/ca.key.pem -noout -modulus | openssl sha256
openssl x509 -in /root/ca/certs/ca.cert.pem -noout -modulus | openssl sha256
```

Los hashes distintos demostraron que no formaban pareja. Como aun no se habia
emitido ningun certificado valido, se genero `ca-raiz.cert.pem` desde la clave
raiz actual y se uso ese certificado para toda la cadena definitiva.

### Error HTTP 403 tras validar TLS

La primera prueba devolvio `SSL certificate verify ok`, pero termino en HTTP
`403 Forbidden`. La PKI ya funcionaba; el error pertenecia al contenido web de
Apache. Al crear un `index.html` accesible, la respuesta paso a `200 OK`.

## Evidencias

Las capturas estan en `evidencias/03-01-infraestructura-clave-publica/`.

| Nº | Evidencia | Que demuestra |
| --- | --- | --- |
| 001 | [VM CA raiz](evidencias/03-01-infraestructura-clave-publica/001-virtualbox-maquina-ca-raiz.png) | CA raiz separada en VirtualBox. |
| 002 | [estructura CA raiz](evidencias/03-01-infraestructura-clave-publica/002-ca-raiz-estructura-directorios.png) | Directorios, permisos, indice y serie. |
| 003 | [estructura CA subordinada](evidencias/03-01-infraestructura-clave-publica/003-ca-sub-estructura-directorios.png) | Estructura independiente de la subordinada. |
| 004 | [CSR subordinada](evidencias/03-01-infraestructura-clave-publica/004-ca-sub-csr-verificada.png) | Identidad y verificacion de la solicitud. |
| 005 | [firma de la subordinada](evidencias/03-01-infraestructura-clave-publica/005-ca-raiz-firma-ca-subordinada.png) | Firma realizada por la CA raiz. |
| 006 | [verificacion en la raiz](evidencias/03-01-infraestructura-clave-publica/006-ca-raiz-verifica-ca-subordinada.png) | Primer tramo de la cadena valido. |
| 007 | [verificacion en SRV-ALMA](evidencias/03-01-infraestructura-clave-publica/007-srv-alma-verifica-ca-subordinada.png) | Certificados recibidos y validados. |
| 008 | [firma del certificado web](evidencias/03-01-infraestructura-clave-publica/008-ca-sub-firma-certificado-web.png) | Emision por la CA subordinada. |
| 009 | [verificacion del certificado web](evidencias/03-01-infraestructura-clave-publica/009-ca-sub-verifica-certificado-web.png) | Cadena completa verificada con OpenSSL. |
| 010 | [identidad, emisor y vigencia](evidencias/03-01-infraestructura-clave-publica/010-certificado-web-emisor-y-validez.png) | Sujeto del servicio y CA emisora. |
| 011 | [configuracion TLS de Apache](evidencias/03-01-infraestructura-clave-publica/011-apache-configuracion-certificado-tls.png) | Rutas del certificado y clave en Apache. |
| 012 | [Apache activo](evidencias/03-01-infraestructura-clave-publica/012-apache-https-activo.png) | Servicio escuchando en HTTP y HTTPS. |
| 013 | [firewall y puerto 443](evidencias/03-01-infraestructura-clave-publica/013-firewall-puerto-443.png) | Regla HTTPS y socket TCP 443. |
| 014 | [confianza en PC2](evidencias/03-01-infraestructura-clave-publica/014-pc2-importa-ca-raiz.png) | Incorporacion de la raiz al cliente. |
| 015 | [validacion HTTPS final](evidencias/03-01-infraestructura-clave-publica/015-pc2-validacion-https-final.png) | SAN correcto, cadena valida y HTTP 200. |

## Seguridad

- No se publican frases de paso ni claves privadas.
- La clave privada raiz permanece unicamente en `CA-RAIZ`.
- La CA raiz se mantiene apagada fuera de las operaciones de firma necesarias.
- Los intercambios temporales por HTTP solo contenian CSR y certificados
  publicos; los archivos se eliminaron al terminar.
- La clave del servicio se protege con permisos `600` y contexto SELinux.

En un entorno real se anadirian listas de revocacion, perfiles de emision,
auditoria, copias de seguridad cifradas, renovacion automatizada y una CA
subordinada dedicada, separada del servidor web.

## Conclusion

La PKI local queda operativa con una CA raiz, una CA subordinada y un certificado
HTTPS final. `PC2` valida la identidad `10.0.0.20`, reconoce como emisor a
`Garea Subordinate CA`, construye la confianza hasta `Garea Root CA` y recibe una
respuesta `HTTP/1.1 200 OK` sin omitir la comprobacion del certificado.
