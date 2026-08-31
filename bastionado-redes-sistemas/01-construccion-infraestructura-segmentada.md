# 01 - Construcción de una infraestructura segmentada

## Resumen

Esta práctica consiste en desplegar una infraestructura virtual con una red de
clientes, una red de servidores y un router Debian que comunica ambos segmentos.
El laboratorio queda preparado para prácticas posteriores de bastionado,
autenticación centralizada, LDAP, administración remota y auditoría de servicios.

Fuente de estudio: ejercicio práctico de la asignatura Bastionado de redes y
sistemas. La documentación está redactada con palabras propias y recoge el
trabajo realizado en laboratorio.

## Objetivos

- Crear una infraestructura virtual segmentada.
- Configurar un router Debian con tres interfaces de red.
- Habilitar DHCP para la red de clientes.
- Permitir salida a Internet mediante NAT.
- Promocionar un Windows Server como controlador de dominio.
- Configurar DNS interno y reenviadores.
- Integrar clientes Windows en Active Directory.
- Configurar un servidor AlmaLinux con SSH, Apache, Webmin y OpenLDAP.
- Integrar un cliente Debian con OpenLDAP.
- Documentar incidencias reales aparecidas durante el despliegue.

## Topología

```text
                         Salida exterior / NAT
                                  |
                            R-DEBIAN
                     Router, NAT, DHCP y firewall
                         /                  \
                        /                    \
    Red clientes 200.0.100.0/24        Red servidores 10.0.0.0/24
              Clientes                             Servidores
          /      |       \                    /          \
       PC0      PC1      PC2           SRV-WINDOWS     SRV-ALMA
     Windows  Windows  Debian          AD DS + DNS     LDAP/SSH/HTTP/Webmin
```

## Direccionamiento

| Equipo | Sistema | Rol | IP |
| --- | --- | --- | --- |
| R-DEBIAN | Debian 11 | Router, NAT, DHCP y firewall | `10.0.2.15` por NAT, `10.0.0.1`, `200.0.100.1` |
| SRV-WINDOWS | Windows Server | Active Directory y DNS | `10.0.0.10` |
| SRV-ALMA | AlmaLinux 9 | OpenLDAP, SSH, Apache y Webmin | `10.0.0.20` |
| PC0 | Windows 11 | Cliente de dominio | DHCP, `200.0.100.100` |
| PC1 | Windows 11 | Cliente de dominio | DHCP, `200.0.100.101` |
| PC2 | Debian 11 | Cliente LDAP | DHCP, `200.0.100.102` |

## Router Debian

Se crea una máquina Debian 11 para actuar como router de la infraestructura. La
máquina tiene tres interfaces:

| Interfaz | Uso | Configuración |
| --- | --- | --- |
| `enp0s3` | Salida exterior mediante NAT de VirtualBox | DHCP |
| `enp0s8` | Red de servidores | `10.0.0.1/24` |
| `enp0s9` | Red de clientes | `200.0.100.1/24` |

Se activa el reenvío IPv4:

```bash
cat /proc/sys/net/ipv4/ip_forward
```

Resultado esperado:

```text
1
```

Para permitir la salida de las redes internas se configura NAT con `nftables`.
La regla principal aplica masquerade sobre la interfaz de salida:

```text
oifname "enp0s3" masquerade
```

También se valida que el router tenga ruta por defecto hacia la salida NAT de
VirtualBox:

```text
default via 10.0.2.2 dev enp0s3
```

## DHCP para clientes

El router Debian ofrece DHCP en la red de clientes `200.0.100.0/24`. El rango
asignado fue:

```text
200.0.100.100 - 200.0.100.200
```

Parámetros entregados por DHCP:

| Parámetro | Valor |
| --- | --- |
| Puerta de enlace | `200.0.100.1` |
| Máscara | `255.255.255.0` |
| Dominio | `garea.local` |
| DNS | `10.0.0.10` |

Inicialmente se usaron DNS públicos para probar conectividad externa. Tras
promocionar el controlador de dominio, se cambió el DNS entregado por DHCP a
`10.0.0.10`, para que los clientes Windows pudieran localizar correctamente los
servicios de Active Directory.

## Clientes Windows

Se crean dos clientes Windows en la red de clientes:

- `PC0`
- `PC1`

`PC1` se crea clonando `PC0`, generando una nueva dirección MAC y cambiando el
nombre del equipo. Cada cliente recibe una dirección distinta por DHCP:

| Cliente | IP recibida | Gateway |
| --- | --- | --- |
| PC0 | `200.0.100.100` | `200.0.100.1` |
| PC1 | `200.0.100.101` | `200.0.100.1` |

Ambos equipos se unen posteriormente al dominio:

```text
garea.local
```

## Active Directory y DNS

`SRV-WINDOWS` se configura con IP fija `10.0.0.10` y se promociona como
controlador de dominio del bosque `garea.local`.

Configuración principal:

| Parámetro | Valor |
| --- | --- |
| Dominio | `garea.local` |
| Nivel funcional del bosque | Windows Server 2016 |
| Nivel funcional del dominio | Windows Server 2016 |
| DNS | Instalado junto a AD DS |
| Delegación DNS | No creada |

No se crea delegación DNS porque el dominio `garea.local` es una zona nueva de
laboratorio y no depende de una zona DNS superior existente.

Tras la promoción, se configuran reenviadores DNS para permitir resolución
externa:

```text
8.8.8.8
1.1.1.1
```

Los clientes Windows usan como DNS el controlador de dominio `10.0.0.10`, no
servidores DNS públicos directamente.

## SRV-ALMA

`SRV-ALMA` se instala en la red de servidores con IP fija:

```text
IP: 10.0.0.20
Máscara: 255.255.255.0
Gateway: 10.0.0.1
DNS: 10.0.0.10
```

Servicios configurados:

| Servicio | Estado | Puerto |
| --- | --- | --- |
| SSH | Activo | `22/tcp` |
| Apache/httpd | Activo | `80/tcp` |
| Webmin | Activo | `10000/tcp` |
| OpenLDAP/slapd | Activo | `389/tcp` |

Apache se valida desde clientes accediendo a:

```text
http://10.0.0.20
```

Webmin se valida desde clientes accediendo a:

```text
https://10.0.0.20:10000
```

## OpenLDAP

En `SRV-ALMA` se instala OpenLDAP y se configura la base:

```text
dc=garea,dc=local
```

Estructura inicial:

```text
dc=garea,dc=local
├── ou=usuarios
└── ou=grupos
```

Se cargan los esquemas necesarios para trabajar con usuarios y grupos POSIX:

```text
cosine
nis
inetorgperson
```

Se crea un grupo LDAP:

```text
cn=usuariosldap,ou=grupos,dc=garea,dc=local
```

Y un usuario de prueba:

```text
uid=prueba01,ou=usuarios,dc=garea,dc=local
```

El usuario incluye atributos POSIX para permitir integración con clientes Linux:

```text
uidNumber: 10001
gidNumber: 10001
homeDirectory: /home/prueba01
loginShell: /bin/bash
```

La búsqueda LDAP se valida con:

```bash
ldapsearch -x -H ldap://10.0.0.20 -b dc=garea,dc=local uid=prueba01
```

## PC2 como cliente LDAP

`PC2` es un Debian 11 conectado a la red de clientes. Recibe IP por DHCP:

```text
200.0.100.102/24
```

Se configura como cliente LDAP contra:

```text
ldap://10.0.0.20/
```

Base DN:

```text
dc=garea,dc=local
```

Se valida la integración con:

```bash
getent passwd prueba01
getent group usuariosldap
```

Resultado esperado:

```text
prueba01:x:10001:10001:Usuario LDAP 01:/home/prueba01:/bin/bash
usuariosldap:*:10001:prueba01
```

Finalmente se habilita la creación automática de directorio personal y se prueba
inicio de sesión:

```bash
su - prueba01
whoami
pwd
id
```

Resultado esperado:

```text
whoami -> prueba01
pwd -> /home/prueba01
id -> uid=10001(prueba01) gid=10001(usuariosldap)
```

## Problemas encontrados

### Interfaz `eth0` inexistente

Durante el reinicio del servicio de red en Debian apareció un error porque
existía un archivo adicional en `/etc/network/interfaces.d/setup` que intentaba
levantar `eth0`. El sistema usaba nombres predictivos de interfaz:

```text
enp0s3
enp0s8
enp0s9
```

Se movió el archivo de configuración antiguo y se dejó la configuración válida
en `/etc/network/interfaces`.

### Interfaces internas cruzadas

PC0 recibía una dirección APIPA y no alcanzaba la puerta de enlace
`200.0.100.1`. Al asignar IP manual se comprobó que sí respondía `10.0.0.1`,
lo que indicaba que las interfaces internas del router estaban cruzadas.

Se corrigió intercambiando la asignación de IP de las interfaces internas y
ajustando DHCP para escuchar en la interfaz real de la red de clientes.

### Falta de ruta por defecto

PC2 alcanzaba la puerta de enlace pero no tenía salida a Internet. El router no
tenía ruta por defecto porque la interfaz NAT `enp0s3` estaba apagada. Se levantó
la interfaz, recibió IP por DHCP y se recuperó la ruta:

```text
default via 10.0.2.2 dev enp0s3
```

### Uso de nftables en lugar de iptables

En Debian 11 no estaba disponible el comando `iptables` clásico. Se configuró
NAT usando `nftables`, manteniendo una regla de masquerade sobre `enp0s3`.

### Firewall de Windows e ICMP

Los clientes Windows podían iniciar conexión hacia otros equipos, pero no
respondían a ping entrante. Al desactivar temporalmente el firewall, el ping
funcionaba, por lo que se creó una regla específica para permitir ICMPv4 entrante
en el laboratorio sin apagar el firewall completo.

### Webmin y firewalld

Webmin estaba activo en `SRV-ALMA`, pero no era accesible hasta recargar
`firewalld`. Se añadió el puerto `10000/tcp` de forma permanente y se aplicó la
configuración con `firewall-cmd --reload`.

### Esquemas LDAP

Al crear grupos y usuarios POSIX aparecieron errores de `objectClass`. Se
detectó que faltaban esquemas LDAP necesarios. Se cargaron `cosine`, `nis` e
`inetorgperson`, permitiendo usar `posixGroup`, `posixAccount` e
`inetOrgPerson`.

### Integración NSS en PC2

`ldapsearch` funcionaba, pero `getent` no mostraba inicialmente los usuarios
LDAP. Se revisaron `nslcd`, `/etc/nslcd.conf` y `/etc/nsswitch.conf` hasta que
el sistema pudo consultar usuarios y grupos LDAP mediante NSS.

## Verificación final

| Prueba | Resultado |
| --- | --- |
| PC0 recibe DHCP | Correcto |
| PC1 recibe DHCP con IP distinta | Correcto |
| PC2 recibe DHCP | Correcto |
| PC2 llega al router | Correcto |
| PC2 tiene salida a Internet | Correcto |
| PC0 y PC1 unidos al dominio | Correcto |
| DNS interno `garea.local` | Correcto |
| Apache accesible desde clientes | Correcto |
| Webmin accesible desde clientes | Correcto |
| OpenLDAP responde a búsquedas | Correcto |
| PC2 resuelve usuarios LDAP con `getent` | Correcto |
| PC2 permite login con usuario LDAP | Correcto |

## Evidencias incluidas

Las capturas de esta práctica se guardan en:

```text
evidencias/01-infraestructura-segmentada/
```

La lista completa está en el [README de evidencias](evidencias/01-infraestructura-segmentada/README.md).

Capturas principales:

| Bloque | Evidencias |
| --- | --- |
| Router Debian | [adaptadores](evidencias/01-infraestructura-segmentada/001-router-adaptadores-virtualbox.png), [configuración de interfaces](evidencias/01-infraestructura-segmentada/004-router-etc-network-interfaces.png), [NAT con nftables](evidencias/01-infraestructura-segmentada/007-router-nftables-masquerade.png), [verificación final](evidencias/01-infraestructura-segmentada/039-router-verificacion-final-nat.png) |
| DHCP y clientes | [PC0](evidencias/01-infraestructura-segmentada/012-pc0-ip-manual-correcta.png), [PC1](evidencias/01-infraestructura-segmentada/034-pc1-ipconfig-dominio-dns.png), [PC2](evidencias/01-infraestructura-segmentada/014-pc2-dhcp-200-0-100-102.png), [concesiones DHCP](evidencias/01-infraestructura-segmentada/041-dhcp-concesiones-clientes.png) |
| Active Directory y DNS | [dominio garea.local](evidencias/01-infraestructura-segmentada/018-srv-windows-ad-garea-local.png), [equipos unidos al dominio](evidencias/01-infraestructura-segmentada/020-ad-equipos-pc0-pc1.png), [pruebas DNS desde cliente](evidencias/01-infraestructura-segmentada/035-pc1-pruebas-dns-conectividad.png) |
| SRV-ALMA | [conectividad](evidencias/01-infraestructura-segmentada/022-srv-alma-conectividad.png), [Apache](evidencias/01-infraestructura-segmentada/025-apache-acceso-web.png), [Webmin](evidencias/01-infraestructura-segmentada/026-webmin-acceso-web.png), [puertos activos](evidencias/01-infraestructura-segmentada/038-srv-alma-puertos-escucha.png) |
| OpenLDAP y PC2 | [usuario LDAP](evidencias/01-infraestructura-segmentada/030-openldap-usuario-prueba01.png), [getent LDAP](evidencias/01-infraestructura-segmentada/031-pc2-getent-ldap-directo.png), [PAM mkhomedir](evidencias/01-infraestructura-segmentada/033-pc2-pam-mkhomedir.png) |
| Incidencias | [interfaz eth0 inexistente](evidencias/01-infraestructura-segmentada/003-router-error-nombres-interfaces.png), [PC0 sin gateway correcto](evidencias/01-infraestructura-segmentada/011-pc0-prueba-inicial-fallo-gateway-clientes.png), [PC2 sin salida inicial](evidencias/01-infraestructura-segmentada/015-pc2-sin-salida-internet.png), [errores de esquema LDAP](evidencias/01-infraestructura-segmentada/027-openldap-error-objectclass-posixgroup.png) |

## Conclusión

La infraestructura base queda desplegada y verificada. El laboratorio dispone de
segmentación entre clientes y servidores, salida a Internet mediante router
Debian, autenticación centralizada con Active Directory para clientes Windows y
autenticación LDAP para cliente Debian.

Esta práctica sirve como punto de partida para ejercicios posteriores de
bastionado: restricción de accesos, reglas de firewall entre redes, hardening de
SSH, protección de Webmin, auditoría de servicios expuestos y revisión de
políticas de dominio.
