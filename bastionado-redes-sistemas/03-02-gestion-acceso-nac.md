# 3.2 - Gestion de acceso mediante sistemas NAC

## Resumen

Esta practica implementa en Cisco Packet Tracer un escenario de autenticacion
centralizada mediante RADIUS y TACACS+. El punto de acceso delega la validacion
de usuarios Wi-Fi en RADIUS y dos routers delegan el acceso administrativo por
SSH en servidores AAA.

El titulo del ejercicio habla de NAC. Packet Tracer representa aqui una parte
del control de acceso a red: comprobar la identidad antes de permitir acceso.
No se implementa un NAC completo con comprobacion del estado del dispositivo,
cuarentena o remediacion.

## Archivo de Packet Tracer

[Descargar practica-3-2-nac-radius-tacacs.pkt](packet-tracer/03-02-nac-radius-tacacs/practica-3-2-nac-radius-tacacs.pkt)

SHA-256 del archivo documentado:

```text
521F6CCEA90573770965523E9B15476ED9823DE6FD5C9A4736A25EB14F76A34C
```

## Objetivos

- Construir una red de laboratorio `192.168.1.0/24`.
- Centralizar la autenticacion Wi-Fi mediante RADIUS.
- Proteger el SSID con WPA2-Enterprise y PEAP.
- Delegar el acceso SSH de un router en RADIUS.
- Delegar el acceso SSH de otro router en TACACS+.
- Conservar una cuenta local de respaldo en cada router.
- Comprobar los accesos desde un equipo administrador.

## Topologia

| Equipo | Tipo | Direccion | Funcion |
| --- | --- | --- | --- |
| R-RADIUS | Router 2811 | `192.168.1.1/24` | Administracion autenticada con RADIUS |
| R-TACACS | Router 2811 | `192.168.1.2/24` | Administracion autenticada con TACACS+ |
| PuntoAcceso | HomeRouter-PT-AC | `192.168.1.6/24` | Acceso Wi-Fi WPA2-Enterprise |
| PC-ADMIN | PC-PT | `192.168.1.10/24` | Pruebas de conectividad y SSH |
| Portatil1 | Laptop-PT | `192.168.1.20/24` | Cliente Wi-Fi autenticado |
| Portatil2 | Laptop-PT | `192.168.1.21/24` | Segundo cliente Wi-Fi |
| SRV-RADIUS | Server-PT | `192.168.1.100/24` | RADIUS para AP y router |
| SRV-TACACS | Server-PT | `192.168.1.200/24` | TACACS+ para router |
| Switch | 2960-24TT | Capa 2 | Interconexion central |

Los equipos cableados se conectan al switch mediante cobre directo. El
HomeRouter se enlaza por un puerto LAN, no por el puerto Internet, porque actua
como punto de acceso dentro de la misma red.

## 1. Configuracion basica de los routers

En `R-RADIUS` se configuran el nombre y la interfaz conectada al switch:

```cisco
enable
configure terminal
hostname R-RADIUS
interface FastEthernet0/0
ip address 192.168.1.1 255.255.255.0
no shutdown
end
write memory
```

En `R-TACACS` se repite el proceso con su direccion:

```cisco
enable
configure terminal
hostname R-TACACS
interface FastEthernet0/0
ip address 192.168.1.2 255.255.255.0
no shutdown
end
write memory
```

- `enable` entra en modo privilegiado.
- `configure terminal` abre la configuracion global.
- `hostname` asigna un nombre reconocible.
- `interface` selecciona la interfaz fisica.
- `ip address` configura IPv4 y mascara.
- `no shutdown` activa administrativamente la interfaz.
- `write memory` guarda la configuracion.

## 2. Servidor RADIUS

`SRV-RADIUS` utiliza IP estatica `192.168.1.100/24` y puerta de enlace
`192.168.1.1`. En `Services > AAA` se activa el servicio y se registran dos
clientes de red:

| Cliente AAA | IP | Tipo |
| --- | --- | --- |
| PuntoAcceso | `192.168.1.6` | RADIUS |
| R-RADIUS | `192.168.1.1` | RADIUS |

Cada cliente se registra con un secreto compartido propio. Tambien se crean
usuarios de laboratorio para Wi-Fi y administracion del router.

Un cliente AAA no es el usuario final: es el dispositivo, como el AP o el
router, autorizado a consultar al servidor RADIUS.

## 3. Punto de acceso y WPA2-Enterprise

El HomeRouter-PT-AC se configura desde su interfaz LAN:

```text
IP LAN: 192.168.1.6
Mascara: 255.255.255.0
SSID 2.4 GHz: GAREA-NAC
Seguridad: WPA2-Enterprise / WPA2-EAP
Cifrado: AES
Servidor RADIUS: 192.168.1.100
```

El secreto compartido del AP debe coincidir exactamente con el configurado
para `192.168.1.6` en `SRV-RADIUS`. El servidor DHCP del HomeRouter se desactiva
para evitar que funcione como router domestico dentro de este escenario.

## 4. Clientes inalambricos

Los portatiles necesitaron el modulo `WPC300N`. Para instalarlo se apago cada
equipo desde `Physical`, se retiro el modulo Ethernet, se inserto `WPC300N` y se
volvio a encender.

En `Desktop > PC Wireless > Profiles` se creo un perfil para `GAREA-NAC`:

```text
Modo: Infrastructure
Seguridad: WPA2-Enterprise
Autenticacion: PEAP
Usuario: usuario de laboratorio registrado en RADIUS
Direccion: estatica dentro de 192.168.1.0/24
```

La contrasena no se muestra en las evidencias. Tras asociarse al SSID, los
clientes pueden comprobar el AP, el servidor RADIUS y el equipo administrador
mediante `ping`.

## 5. Acceso administrativo mediante RADIUS

Antes de activar AAA se crea en `R-RADIUS` una cuenta local de emergencia. Los
valores sensibles aparecen como marcadores en esta documentacion:

```cisco
enable
configure terminal
username respaldo privilege 15 secret <CLAVE_LOCAL>
ip domain-name garea.local
crypto key generate rsa
ip ssh version 2
```

`crypto key generate rsa` crea las claves del router necesarias para SSH. En el
laboratorio se seleccionaron 1024 bits por las limitaciones del simulador.

Se configura la consulta al servidor RADIUS:

```cisco
aaa new-model
radius-server host 192.168.1.100 key <CLAVE_RADIUS_ROUTER>
aaa authentication login ACCESO-RADIUS group radius local
line vty 0 4
login authentication ACCESO-RADIUS
transport input ssh
end
write memory
```

- `aaa new-model` activa el sistema AAA de IOS.
- `radius-server host` identifica el servidor y su secreto compartido.
- `group radius local` consulta primero RADIUS y usa la base local si el
  servidor no responde.
- `line vty 0 4` selecciona las sesiones remotas.
- `login authentication` aplica la lista `ACCESO-RADIUS`.
- `transport input ssh` evita accesos VTY mediante Telnet.

Desde `PC-ADMIN` se prueba:

```text
ssh -l <USUARIO_RADIUS> 192.168.1.1
```

El prompt de `R-RADIUS` confirma que el servidor central acepto las
credenciales.

## 6. Acceso administrativo mediante TACACS+

En `SRV-TACACS`, con IP `192.168.1.200/24`, se activa `Services > AAA`, se
registra `R-TACACS` (`192.168.1.2`) como cliente de tipo TACACS y se crea un
usuario administrativo de laboratorio.

El router se prepara para SSH y conserva una cuenta local de respaldo:

```cisco
enable
configure terminal
username respaldo privilege 15 secret <CLAVE_LOCAL>
ip domain-name garea.local
crypto key generate rsa
ip ssh version 2
aaa new-model
tacacs-server host 192.168.1.200 key <CLAVE_TACACS_ROUTER>
aaa authentication login ACCESO-TACACS group tacacs+ local
line vty 0 4
login authentication ACCESO-TACACS
transport input ssh
end
write memory
```

La prueba desde `PC-ADMIN` es:

```text
ssh -l <USUARIO_TACACS> 192.168.1.2
```

Tras un intento rechazado con credenciales incorrectas, el acceso valido mostro
el prompt de `R-TACACS`.

## RADIUS frente a TACACS+

| Caracteristica | RADIUS | TACACS+ |
| --- | --- | --- |
| Uso habitual | Acceso a red, Wi-Fi y VPN | Administracion de dispositivos |
| Transporte | UDP | TCP |
| Separacion AAA | Menos granular | Separa autenticacion, autorizacion y contabilidad |
| Cifrado | Protege principalmente la contrasena | Protege el contenido de la comunicacion AAA |
| Uso en la practica | AP y R-RADIUS | R-TACACS |

La configuracion `group ... local` no usa la cuenta local cuando el servidor
rechaza correctamente un usuario. La alternativa local se aplica cuando el
servidor AAA no esta disponible o no responde.

## Incidencias resueltas

### Falta de interfaz inalambrica

Packet Tracer mostro que era necesaria una interfaz `WMP300N` o `WPC300N`. En
los portatiles se instalo `WPC300N` desde la pestaña fisica.

### SSID con nombre Default

El adaptador detectaba varias redes `Default`. Se cambio el nombre de la banda
de 2.4 GHz a `GAREA-NAC` en la configuracion basica del HomeRouter.

### Perfil obligatorio para WPA2-EAP

La conexion directa mostro el aviso de crear un perfil. Desde `Profiles` se
definieron la red, direccion IP, WPA2-Enterprise, PEAP y las credenciales.

### Primer intento SSH rechazado

La prueba TACACS+ incluyo un intento con credenciales incorrectas y despues un
acceso correcto. Esto demuestra que el router no acepta cualquier inicio de
sesion y que la validacion centralizada esta activa.

## Evidencias

| Nº | Evidencia | Que muestra |
| --- | --- | --- |
| 001 | [Topologia final](evidencias/03-02-nac-radius-tacacs/001-topologia-final-packet-tracer.png) | Equipos cableados y portatiles asociados al AP. |
| 002 | [IP de R-RADIUS](evidencias/03-02-nac-radius-tacacs/002-router-radius-ip.png) | Interfaz `192.168.1.1` activa y configuracion guardada. |
| 003 | [IP de R-TACACS](evidencias/03-02-nac-radius-tacacs/003-router-tacacs-ip.png) | Interfaz `192.168.1.2` activa y configuracion guardada. |
| 004 | [IP del servidor RADIUS](evidencias/03-02-nac-radius-tacacs/004-servidor-radius-ip.png) | Configuracion estatica de `SRV-RADIUS`. |
| 005 | [SSID WPA2-EAP](evidencias/03-02-nac-radius-tacacs/005-ssid-garea-nac-wpa2-eap.png) | Deteccion de `GAREA-NAC` con seguridad empresarial. |
| 006 | [Perfil WPA2-Enterprise](evidencias/03-02-nac-radius-tacacs/006-cliente-perfil-wpa2-enterprise.png) | PEAP y usuario, con contrasena oculta. |
| 007 | [Acceso TACACS+](evidencias/03-02-nac-radius-tacacs/007-acceso-ssh-tacacs.png) | Rechazo inicial y acceso posterior al router. |

## Seguridad

- Las capturas elegidas no muestran contrasenas ni secretos compartidos.
- Los comandos publicados usan marcadores para los valores sensibles.
- El archivo `.pkt` contiene exclusivamente credenciales desechables del
  laboratorio y no deben reutilizarse en otros sistemas.
- En produccion se usarian claves largas, SSH moderno, registros de
  contabilidad, redundancia AAA y protocolos EAP con validacion de certificado.

## Conclusion

La simulacion demuestra autenticacion centralizada en tres puntos: acceso
inalambrico mediante WPA2-Enterprise y RADIUS, acceso SSH al primer router con
RADIUS y acceso SSH al segundo router con TACACS+. Los equipos de red delegan la
validacion de credenciales en los servidores AAA y conservan una cuenta local
de recuperacion para una interrupcion del servicio central.
