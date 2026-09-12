# 4.2 - VLAN con ACL

## Resumen

Esta practica amplia el escenario de VLAN de la practica 4.1 incorporando un
router-on-a-stick y listas de control de acceso extendidas. El router permite
inicialmente el encaminamiento entre las VLAN 2, 3 y 4 y una red independiente
de servidores. Despues se aplican ACL para impedir que las redes de clientes se
comuniquen entre ellas, manteniendo el acceso a los servicios comunes.

```text
VLAN 2 --\
VLAN 3 ---- SW-CLIENTES ==== R-ACL ---- SW-SERVIDORES ---- FTP, DNS y web
VLAN 4 --/        trunk       | Fa0/1          192.168.5.0/24
                              |
                       subinterfaces 802.1Q
```

## Archivo de Packet Tracer

[Descargar practica-4-2-vlan-con-acl.pkt](packet-tracer/04-02-vlan-con-acl/practica-4-2-vlan-con-acl.pkt)

SHA-256:

```text
B1A64F533BD172F3A4C19AECA786C741C9A66C8D7AEA20CAC3481E09346029A1
```

## Objetivos

- Crear tres VLAN de clientes y asignarles puertos de acceso.
- Configurar un enlace troncal 802.1Q entre el switch y el router.
- Encaminar las VLAN mediante subinterfaces del router.
- Incorporar una red fisica independiente para los servidores.
- Comprobar la conectividad completa antes del filtrado.
- Bloquear mediante ACL el trafico entre redes de clientes.
- Mantener desde todas las VLAN el acceso a la red de servidores.
- Verificar el funcionamiento mediante pings y contadores de las ACL.

## Topologia y direccionamiento

### Clientes

| Equipo | Direccion | Puerta de enlace | Puerto de SW-CLIENTES | VLAN |
| --- | --- | --- | --- | --- |
| PC0 | `192.168.1.10/24` | `192.168.1.1` | `Fa0/1` | 2 |
| PC1 | `192.168.1.11/24` | `192.168.1.1` | `Fa0/2` | 2 |
| PC2 | `192.168.1.12/24` | `192.168.1.1` | `Fa0/3` | 2 |
| PC3 | `192.168.2.10/24` | `192.168.2.1` | `Fa0/4` | 3 |
| PC4 | `192.168.2.11/24` | `192.168.2.1` | `Fa0/5` | 3 |
| PC5 | `192.168.2.12/24` | `192.168.2.1` | `Fa0/6` | 3 |
| PC6 | `192.168.3.10/24` | `192.168.3.1` | `Fa0/7` | 4 |
| PC7 | `192.168.3.11/24` | `192.168.3.1` | `Fa0/8` | 4 |
| PC8 | `192.168.3.12/24` | `192.168.3.1` | `Fa0/9` | 4 |

### Infraestructura y servidores

| Equipo o interfaz | Direccion | Funcion |
| --- | --- | --- |
| SW-CLIENTES, VLAN 1 | `192.168.4.4/24` | Gestion del switch |
| R-ACL, `Fa0/0.1` | `192.168.4.1/24` | VLAN nativa y gestion |
| R-ACL, `Fa0/0.2` | `192.168.1.1/24` | Puerta de enlace de VLAN 2 |
| R-ACL, `Fa0/0.3` | `192.168.2.1/24` | Puerta de enlace de VLAN 3 |
| R-ACL, `Fa0/0.4` | `192.168.3.1/24` | Puerta de enlace de VLAN 4 |
| R-ACL, `Fa0/1` | `192.168.5.1/24` | Puerta de enlace de servidores |
| Server0, FTP | `192.168.5.10/24` | Servidor FTP |
| Server1, DNS | `192.168.5.11/24` | Servidor DNS |
| Server2, web | `192.168.5.12/24` | Servidor HTTP |

Los tres servidores utilizan `192.168.5.1` como puerta de enlace. El enlace
`SW-CLIENTES Gi0/1` con `R-ACL Fa0/0` funciona como troncal. El router se conecta
por `Fa0/1` al switch de servidores.

## 1. Configuracion de SW-CLIENTES

Se crean las tres VLAN:

```cisco
enable
configure terminal
hostname SW-CLIENTES

vlan 2
 name VLAN-RED1
vlan 3
 name VLAN-RED2
vlan 4
 name VLAN-RED3
```

- `vlan 2`, `vlan 3` y `vlan 4` crean los dominios logicos.
- `name` asigna un nombre reconocible a cada VLAN.
- Los numeros de VLAN deben coincidir con las etiquetas 802.1Q del router.

Los nueve puertos de clientes se dividen en tres grupos:

```cisco
interface range FastEthernet0/1-3
 switchport mode access
 switchport access vlan 2

interface range FastEthernet0/4-6
 switchport mode access
 switchport access vlan 3

interface range FastEthernet0/7-9
 switchport mode access
 switchport access vlan 4
```

`switchport mode access` configura enlaces para equipos finales y
`switchport access vlan` decide a que VLAN pertenece el trafico recibido.

El enlace con el router transporta todas las VLAN necesarias:

```cisco
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 1,2,3,4
```

La VLAN 1 se usa en este laboratorio para gestionar el switch:

```cisco
interface vlan 1
 ip address 192.168.4.4 255.255.255.0
 no shutdown
exit
ip default-gateway 192.168.4.1
end
write memory
```

## 2. Configuracion del switch de servidores

Los servidores forman una red fisica independiente conectada a
SW-SERVIDORES. No se requieren VLAN adicionales porque sus puertos permanecen
en la VLAN 1 predeterminada:

```cisco
enable
configure terminal
hostname SW-SERVIDORES
end
write memory
```

## 3. Router-on-a-stick

La interfaz fisica hacia SW-CLIENTES queda activa y sin direccion IP propia:

```cisco
enable
configure terminal
hostname R-ACL

interface FastEthernet0/0
 no ip address
 no shutdown
```

Se crea una subinterfaz por cada red. `encapsulation dot1Q` asocia la
subinterfaz con la etiqueta VLAN recibida por el troncal:

```cisco
interface FastEthernet0/0.1
 encapsulation dot1Q 1 native
 ip address 192.168.4.1 255.255.255.0

interface FastEthernet0/0.2
 encapsulation dot1Q 2
 ip address 192.168.1.1 255.255.255.0

interface FastEthernet0/0.3
 encapsulation dot1Q 3
 ip address 192.168.2.1 255.255.255.0

interface FastEthernet0/0.4
 encapsulation dot1Q 4
 ip address 192.168.3.1 255.255.255.0
```

La red de servidores utiliza otra interfaz fisica:

```cisco
interface FastEthernet0/1
 ip address 192.168.5.1 255.255.255.0
 no shutdown
end
write memory
```

Al estar todas las redes directamente conectadas, el router conoce sus rutas y
no necesita rutas estaticas adicionales.

## 4. Comprobacion antes de aplicar las ACL

Primero se prueba el encaminamiento sin filtros. Por ejemplo, desde PC0:

```text
PC0> ping 192.168.2.10
PC0> ping 192.168.3.10
PC0> ping 192.168.5.10
```

Los destinos de VLAN 3, VLAN 4 y la red de servidores responden. Esta prueba es
importante porque demuestra que el direccionamiento, el troncal y las
subinterfaces funcionan antes de introducir las restricciones.

Durante la configuracion se detecto que PC3 estaba conectado inicialmente a
`Fa0/9`, puerto asignado a VLAN 4. Se corrigio el puerto fisico para situarlo en
el grupo `Fa0/4-6` de VLAN 3. Tras la correccion, PC3 alcanzo su puerta de enlace
`192.168.2.1` y el resto de redes antes de aplicar las ACL.

## 5. Creacion de las ACL extendidas

Se define una lista por cada red de clientes. La mascara wildcard
`0.0.0.255` representa todos los hosts de una red `/24`.

### Trafico procedente de VLAN 2

```cisco
ip access-list extended FILTRO-VLAN2
 permit ip 192.168.1.0 0.0.0.255 192.168.5.0 0.0.0.255
 deny ip 192.168.1.0 0.0.0.255 192.168.2.0 0.0.0.255
 deny ip 192.168.1.0 0.0.0.255 192.168.3.0 0.0.0.255
 permit ip 192.168.1.0 0.0.0.255 any
exit
```

### Trafico procedente de VLAN 3

```cisco
ip access-list extended FILTRO-VLAN3
 permit ip 192.168.2.0 0.0.0.255 192.168.5.0 0.0.0.255
 deny ip 192.168.2.0 0.0.0.255 192.168.1.0 0.0.0.255
 deny ip 192.168.2.0 0.0.0.255 192.168.3.0 0.0.0.255
 permit ip 192.168.2.0 0.0.0.255 any
exit
```

### Trafico procedente de VLAN 4

```cisco
ip access-list extended FILTRO-VLAN4
 permit ip 192.168.3.0 0.0.0.255 192.168.5.0 0.0.0.255
 deny ip 192.168.3.0 0.0.0.255 192.168.1.0 0.0.0.255
 deny ip 192.168.3.0 0.0.0.255 192.168.2.0 0.0.0.255
 permit ip 192.168.3.0 0.0.0.255 any
exit
```

El orden de las entradas es relevante porque IOS evalua una ACL de arriba hacia
abajo y se detiene en la primera coincidencia:

1. Se permite expresamente el acceso a `192.168.5.0/24`.
2. Se deniega el acceso a las otras dos redes de clientes.
3. Se permite el resto del trafico para no bloquear la gestion u otros destinos.

## 6. Aplicacion de las ACL

Cada ACL se aplica en entrada sobre la subinterfaz de su red de origen:

```cisco
interface FastEthernet0/0.2
 ip access-group FILTRO-VLAN2 in

interface FastEthernet0/0.3
 ip access-group FILTRO-VLAN3 in

interface FastEthernet0/0.4
 ip access-group FILTRO-VLAN4 in

end
copy running-config startup-config
```

La direccion `in` filtra los paquetes cuando llegan al router desde los
clientes. De esta forma se bloquea el trafico no autorizado cerca de su origen.

## 7. Pruebas finales

Desde PC0, perteneciente a VLAN 2, se repiten las pruebas:

```text
PC0> ping 192.168.2.10
Destination host unreachable

PC0> ping 192.168.3.10
Destination host unreachable

PC0> ping 192.168.5.10
Reply from 192.168.5.10

PC0> ping 192.168.5.11
Reply from 192.168.5.11
```

El resultado confirma que VLAN 2 ya no alcanza VLAN 3 ni VLAN 4, pero conserva
el acceso a los servidores. Las listas de VLAN 3 y VLAN 4 aplican la misma
politica de forma reciproca.

Los contadores se consultan con:

```cisco
show access-lists
```

La salida muestra coincidencias tanto en las reglas `permit` hacia servidores
como en las reglas `deny` entre VLAN. Esto demuestra que el filtrado no se debe
a una averia de conectividad, sino a la politica aplicada por el router.

## Resultados

| Origen | Destino | Resultado antes de ACL | Resultado despues de ACL |
| --- | --- | --- | --- |
| VLAN 2 | VLAN 3 | Permitido | Bloqueado |
| VLAN 2 | VLAN 4 | Permitido | Bloqueado |
| VLAN 3 | VLAN 4 | Permitido | Bloqueado |
| VLAN 2, 3 o 4 | Red de servidores | Permitido | Permitido |

## Evidencias

| Nº | Evidencia | Que muestra |
| --- | --- | --- |
| 001 | [Configuracion de SW-CLIENTES](evidencias/04-02-vlan-con-acl/001-configuracion-sw-clientes.png) | Creacion de VLAN, puertos de acceso, troncal y direccion de gestion. |
| 002 | [Subinterfaces del router](evidencias/04-02-vlan-con-acl/002-router-subinterfaces-y-servidores.png) | Router-on-a-stick y enlace con la red de servidores. |
| 003 | [SW-SERVIDORES](evidencias/04-02-vlan-con-acl/003-configuracion-sw-servidores.png) | Switch fisico dedicado a los servidores. |
| 004 | [Enlace troncal](evidencias/04-02-vlan-con-acl/004-troncal-sw-clientes.png) | `Gi0/1` transporta las VLAN 1, 2, 3 y 4 mediante 802.1Q. |
| 005 | [VLAN y puertos](evidencias/04-02-vlan-con-acl/005-vlan-y-puertos-sw-clientes.png) | Distribucion final de los nueve puertos de acceso. |
| 006 | [Conectividad previa](evidencias/04-02-vlan-con-acl/006-conectividad-previa-acl.png) | Comunicacion inter-VLAN y con servidores antes del filtrado. |
| 007 | [Definicion de ACL](evidencias/04-02-vlan-con-acl/007-definicion-acl.png) | Reglas permit y deny de las tres listas extendidas. |
| 008 | [Aplicacion de ACL](evidencias/04-02-vlan-con-acl/008-aplicacion-acl-subinterfaces.png) | ACL aplicadas en entrada y configuracion guardada. |
| 009 | [Pruebas finales](evidencias/04-02-vlan-con-acl/009-aislamiento-y-acceso-servidores.png) | Trafico entre VLAN bloqueado y acceso a servidores permitido. |
| 010 | [Contadores de ACL](evidencias/04-02-vlan-con-acl/010-contadores-acl.png) | Coincidencias registradas por las reglas de filtrado. |

## Consideraciones de seguridad

- Las ACL extendidas se colocan cerca del origen para descartar pronto el
  trafico no autorizado.
- Las reglas explicitas facilitan la auditoria y permiten observar contadores.
- En produccion convendria utilizar una VLAN de gestion distinta de VLAN 1.
- Los puertos no utilizados deberian apagarse y asignarse a una VLAN sin uso.
- Las ACL de un router no sustituyen a un firewall con seguimiento de estado.
- El acceso real a FTP, DNS y HTTP puede limitarse por protocolo y puerto en vez
  de permitir toda la red de servidores.

## Conclusion

El router-on-a-stick proporciona conectividad de capa 3 entre las VLAN y la red
de servidores. Las ACL extendidas cambian esa conectividad abierta por una
politica controlada: las redes de clientes quedan aisladas entre si, mientras
que todas conservan acceso a los recursos compartidos. Las pruebas y los
contadores de IOS confirman que el resultado procede de las reglas configuradas.
