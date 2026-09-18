# 5.2 - Instalacion y configuracion de un servidor de correo seguro

## Resumen

En esta practica se despliega un servidor de correo completo en `SRV-ALMA`
mediante Postfix y Dovecot. El servicio utiliza certificados emitidos por la
PKI del laboratorio, obliga a cifrar las conexiones y permite el envio
autenticado desde el cliente Debian `PC2`.

La proteccion del flujo de correo se completa con listas DNSBL, mapas locales
de bloqueo, validacion SPF y analisis antivirus con ClamAV. Las pruebas finales
demuestran tanto el funcionamiento legitimo como el rechazo controlado de
remitentes bloqueados, identidades SPF no autorizadas y el archivo de prueba
EICAR.

```text
PC2 (cliente)
  |-- SMTP Submission 587 + STARTTLS + AUTH --> Postfix
  |-- IMAPS 993 / POP3S 995 -----------------> Dovecot
                                                   |
Internet simulado --> DNSBL + SPF --> Postfix --> ClamAV milter
                                                   |
                                                   v
                                              Maildir local
```

## Objetivos

- Publicar los registros DNS necesarios para el dominio de correo.
- Emitir un certificado con nombres alternativos adecuados.
- Configurar Postfix para SMTP y Submission autenticado.
- Configurar Dovecot para buzones Maildir mediante IMAP y POP3.
- Exigir TLS y validar el certificado desde un equipo cliente.
- Restringir remitentes, clientes no confiables y servidores incluidos en DNSBL.
- Validar SPF antes de aceptar correo externo.
- Integrar ClamAV mediante un milter de Postfix.
- Verificar envio, recepcion y controles de rechazo mediante registros.

## Escenario

| Equipo | Sistema | Funcion | Direccion |
| --- | --- | --- | --- |
| SRV-ALMA | AlmaLinux 9.8 | Postfix, Dovecot, SPF y ClamAV | `10.0.0.20` |
| SRV-WINDOWS | Windows Server | DNS autoritativo de `garea.local` | `10.0.0.10` |
| PC2 | Debian 11 | Cliente SMTP, IMAP y POP3 | `200.0.100.102` |

La red de servidores y la red de clientes se comunican a traves del router
Debian preparado en practicas anteriores. La CA raiz ya era de confianza para
`PC2` como resultado de la practica 3.1.

## 1. Resolucion DNS

En el DNS de Windows Server se crean los registros siguientes:

| Tipo | Nombre | Valor |
| --- | --- | --- |
| A | `mail.garea.local` | `10.0.0.20` |
| MX | `garea.local` | `mail.garea.local`, prioridad 10 |
| TXT | `garea.local` | `v=spf1 ip4:10.0.0.20 -all` |

El registro SPF autoriza exclusivamente al servidor de correo del laboratorio
para enviar mensajes en nombre de `garea.local`.

## 2. Certificado del servicio

Se genera una clave privada y una solicitud de certificado en `SRV-ALMA`. La
CA subordinada de la practica 3.1 firma el certificado usando las extensiones
definidas en [mail-server.ext](configuraciones/05-02-correo-seguro/mail-server.ext):

```bash
openssl req -new -newkey rsa:3072 -nodes \
  -keyout /etc/pki/tls/private/mail.garea.local.key.pem \
  -out /root/ca-sub/csr/mail.garea.local.csr.pem \
  -subj "/C=ES/O=Garea Lab/OU=Correo/CN=mail.garea.local"

openssl x509 -req \
  -in /root/ca-sub/csr/mail.garea.local.csr.pem \
  -CA /root/ca-sub/certs/ca-sub.cert.pem \
  -CAkey /root/ca-sub/private/ca.sub.key.pem \
  -CAcreateserial -days 825 -sha256 \
  -extfile /root/ca-sub/mail-server.ext -extensions server_cert \
  -out /etc/pki/tls/certs/mail.garea.local.cert.pem
```

La cadena servida contiene el certificado del servidor y la CA subordinada:

```bash
cat /etc/pki/tls/certs/mail.garea.local.cert.pem \
    /root/ca-sub/certs/ca-sub.cert.pem \
  > /etc/pki/tls/certs/mail.garea.local-fullchain.pem
```

La comprobacion confirma una cadena valida y los SAN
`mail.garea.local`, `srv-alma.garea.local` y `10.0.0.20`.

## 3. Postfix: SMTP seguro y autenticado

Se instalan los componentes principales:

```bash
dnf install -y postfix dovecot s-nail
```

La configuracion aplicada se conserva como
[main.cf.fragment](configuraciones/05-02-correo-seguro/main.cf.fragment). Sus
puntos principales son:

- Identidad SMTP `mail.garea.local` para el dominio `garea.local`.
- Buzones locales en formato Maildir.
- TLS obligatorio y autenticacion disponible solo despues de cifrar.
- Autenticacion SASL delegada en Dovecot.
- Restriccion de relay a redes y usuarios autorizados.
- Filtros por cliente, remitente, DNSBL y SPF.
- Integracion con ClamAV mediante Milter.

El puerto `587/tcp` se configura como servicio Submission independiente. Su
fragmento se encuentra en
[master.cf.fragment](configuraciones/05-02-correo-seguro/master.cf.fragment).
Solo acepta destinatarios cuando la sesion esta cifrada y autenticada.

## 4. Dovecot: IMAP, POP3 y Maildir

Se crean las cuentas locales `correo1` y `correo2`. Dovecot utiliza el mismo
certificado de servicio y guarda los mensajes en `~/Maildir`.

La configuracion completa del laboratorio se mantiene en
[99-garea-mail.conf](configuraciones/05-02-correo-seguro/99-garea-mail.conf).
Las medidas principales son:

- Protocolos IMAP y POP3 habilitados.
- `ssl = required` para impedir autenticacion sin TLS.
- TLS 1.2 como version minima.
- Metodos SASL `PLAIN` y `LOGIN` permitidos unicamente dentro del canal TLS.
- Socket de autenticacion accesible para Postfix en su entorno aislado.

Se habilitan ambos servicios:

```bash
systemctl enable --now dovecot postfix
systemctl is-active dovecot postfix
```

## 5. Cortafuegos y puertos

Se publican SMTP, IMAPS, POP3S y Submission:

```bash
firewall-cmd --permanent --add-service=smtp
firewall-cmd --permanent --add-service=imaps
firewall-cmd --permanent --add-service=pop3s
firewall-cmd --permanent --add-port=587/tcp
firewall-cmd --reload
```

Los puertos `110` y `143` pueden permanecer en escucha para STARTTLS, pero no
se publican en el cortafuegos. Dovecot exige TLS incluso en esas interfaces.

## 6. Control de acceso y DNSBL

Se crean mapas para bloquear una direccion de origen y una cuenta remitente:

- [client_access](configuraciones/05-02-correo-seguro/client_access)
- [sender_access](configuraciones/05-02-correo-seguro/sender_access)

Los mapas se compilan y Postfix se recarga:

```bash
postmap /etc/postfix/client_access
postmap /etc/postfix/sender_access
postfix check
systemctl reload postfix
```

Las restricciones de destinatario consultan dos listas DNSBL independientes:
`zen.spamhaus.org` y `bl.spamcop.net`. Antes de usarlas en produccion deben
revisarse sus condiciones de uso, politica de consultas y procedimiento de
exclusion.

Una prueba desde `PC2` con `bloqueado@ejemplo.invalid` recibe
`554 5.7.1 Sender address rejected`. El registro de Postfix confirma la regla
que produjo el rechazo y el buzón de destino mantiene el mismo numero de
mensajes.

## 7. Validacion SPF

Se instala `pypolicyd-spf` y se registra como servicio de politica de Postfix:

```bash
dnf install -y pypolicyd-spf
```

La configuracion usada aparece en
[policyd-spf.conf](configuraciones/05-02-correo-seguro/policyd-spf.conf). En la
version instalada, `TestOnly = 1` activa las decisiones de rechazo. Una
consulta de politica controlada simula un origen no autorizado y obtiene:

```text
action=550 5.7.23 Message rejected due to: SPF fail - not authorized
```

## 8. Antivirus ClamAV

Se instalan el motor, el actualizador de firmas y el milter:

```bash
dnf install -y clamav clamd clamav-freshclam clamav-milter
systemctl enable --now clamav-freshclam clamd@scan clamav-milter
```

`clamd` escucha exclusivamente en `127.0.0.1:3310` y `clamav-milter` en
`127.0.0.1:7357`; ninguno de estos puertos se expone a otras maquinas. El
fragmento [clamav-milter.conf](configuraciones/05-02-correo-seguro/clamav-milter.conf)
documenta la conexion entre ambos componentes.

Primero se envia un mensaje limpio, que llega correctamente. Despues se adjunta
el archivo estandar EICAR, diseñado para comprobar antivirus sin utilizar
codigo malicioso real. ClamAV registra `Eicar-Signature FOUND` y Postfix genera
`milter-reject`, devuelve `5.7.1 Command rejected` y no entrega el mensaje.

## 9. Pruebas de envio y recepcion

Desde `PC2`, `swaks` establece STARTTLS en `587`, valida la cadena de confianza
y autentica a `correo1`. La respuesta `235 2.7.0 Authentication successful` y
el identificador de cola confirman la aceptacion del mensaje.

La recepcion se verifica mediante dos metodos:

```bash
doveadm search -u correo2 ALL
doveadm fetch -u correo2 'hdr.subject hdr.from hdr.to' ALL
```

```bash
curl --url 'imaps://mail.garea.local/INBOX' \
  --user correo2 --request 'SEARCH ALL' \
  --cacert /usr/local/share/ca-certificates/garea-root-ca.crt
```

El buzón contiene tres mensajes legitimos, incluido el enviado desde `PC2`.

Tambien se comprueba el comportamiento negativo del servicio Submission. Una
sesion en `587` que intenta enviar antes de STARTTLS recibe:

```text
530 5.7.0 Must issue a STARTTLS command first
```

Finalmente, POP3S en `995` negocia TLS 1.3, presenta el certificado de
`mail.garea.local` y devuelve `Verify return code: 0 (ok)`.

## Incidencias encontradas

### Repositorios archivados de Debian 11

`PC2` utiliza Debian 11, cuyos repositorios dejaron de estar disponibles en
los mirrors ordinarios del laboratorio. La instalacion de `swaks` devolvia
errores HTTP 404. Para finalizar la practica se apuntaron temporalmente las
fuentes a `archive.debian.org` y se desactivo la comprobacion de caducidad.

Esta solucion permite reproducir la prueba, pero el equipo debe migrarse a una
version de Debian con soporte vigente.

### Nombres de servicios de firewalld

La zona activa no incluia servicios llamados `submission` ni `pop3`. Se usaron
los servicios disponibles `smtp`, `imaps` y `pop3s`, y se abrio explicitamente
`587/tcp` para Submission.

### Prueba interactiva con credenciales

Una primera prueba mostro la contraseña introducida en la terminal. La clave se
cambio inmediatamente y esa captura se excluyo del repositorio. Las pruebas
posteriores utilizaron una solicitud protegida de contraseña y no publican
credenciales.

## Resultados

| Prueba | Resultado |
| --- | --- |
| Cadena y SAN del certificado | Validos |
| SMTP en puerto 25 | TLS obligatorio |
| Submission en puerto 587 | STARTTLS y SASL correctos |
| IMAPS y POP3S | Certificado validado desde `PC2` |
| Entrega local en Maildir | Correcta |
| Remitente bloqueado | Rechazado con `554` |
| Cliente no confiable | Mapa de rechazo operativo |
| DNSBL | Dos proveedores configurados |
| SPF no autorizado | Rechazado con `550 5.7.23` |
| Mensaje limpio | Entregado |
| EICAR | Detectado y rechazado por el milter |
| Comprobacion de Postfix | Codigo de salida `0` |
| Servicios finales | Todos activos |

## Evidencias

| Nº | Evidencia | Que demuestra |
| --- | --- | --- |
| 001 | [Certificado verificado](evidencias/05-02-correo-seguro/001-certificado-correo-verificado.png) | Cadena valida, identidad y SAN del servicio. |
| 002 | [Postfix TLS y SASL](evidencias/05-02-correo-seguro/002-postfix-tls-sasl.png) | Parametros principales del MTA. |
| 003 | [Dovecot TLS y Maildir](evidencias/05-02-correo-seguro/003-dovecot-tls-maildir.png) | Configuracion efectiva de acceso al buzón. |
| 004 | [Rechazo SPF](evidencias/05-02-correo-seguro/004-spf-rechazo.png) | Politica SPF aplicada a un origen no autorizado. |
| 005 | [Servicios ClamAV](evidencias/05-02-correo-seguro/005-clamav-servicios-puertos.png) | Motor y milter activos solo en loopback. |
| 006 | [EICAR rechazado](evidencias/05-02-correo-seguro/006-clamav-eicar-rechazado.png) | Deteccion antivirus y rechazo en Postfix. |
| 007 | [SMTP autenticado](evidencias/05-02-correo-seguro/007-smtp-starttls-autenticado.png) | STARTTLS, AUTH y aceptacion en cola. |
| 008 | [Mensajes recibidos](evidencias/05-02-correo-seguro/008-mensajes-recibidos-maildir.png) | Entrega de los tres mensajes legitimos. |
| 009 | [Remitente bloqueado](evidencias/05-02-correo-seguro/009-remitente-bloqueado.png) | Rechazo SMTP del remitente excluido. |
| 010 | [Mapas y registro](evidencias/05-02-correo-seguro/010-mapas-acceso-registro.png) | Reglas compiladas y trazabilidad del rechazo. |
| 011 | [STARTTLS obligatorio](evidencias/05-02-correo-seguro/011-submission-exige-starttls.png) | Submission impide enviar en texto claro. |
| 012 | [POP3S verificado](evidencias/05-02-correo-seguro/012-pop3s-certificado-valido.png) | TLS 1.3 y cadena valida en el puerto 995. |

## Consideraciones de seguridad

- No se publican contraseñas, claves privadas ni bases de datos compiladas.
- Los ficheros de configuracion del repositorio son fragmentos saneados y deben
  revisarse antes de aplicarlos en otro entorno.
- Las cuentas locales se usan solo para el laboratorio; en produccion conviene
  separar identidades del sistema y buzones virtuales.
- DNSBL y SPF reducen abuso y suplantacion, pero no sustituyen DKIM, DMARC,
  control de reputacion ni filtrado de contenido adicional.
- Las firmas de ClamAV deben mantenerse actualizadas y sus fallos deben
  supervisarse.
- El puerto 25 normalmente requiere interoperabilidad con otros MTA. Forzar
  TLS es adecuado para este laboratorio cerrado, pero en Internet puede
  impedir la recepcion desde servidores sin TLS.
- Debian 11 debe actualizarse a una version con soporte vigente.

## Conclusion

`SRV-ALMA` queda configurado como servidor de correo seguro para
`garea.local`. Postfix y Dovecot proporcionan envio y recepcion cifrados,
Submission exige autenticacion y la cadena de certificados se valida desde el
cliente. Los controles DNSBL, mapas de acceso, SPF y ClamAV actuan antes de la
entrega y dejan evidencias en los registros. Las pruebas positivas y negativas
confirman que los mensajes legitimos llegan al buzón y que los casos definidos
como no confiables son rechazados.
