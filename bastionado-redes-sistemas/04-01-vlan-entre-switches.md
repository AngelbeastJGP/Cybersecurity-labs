# 4.1 - VLAN entre switches

## Resumen

Esta practica crea tres VLAN en dos switches Cisco y utiliza un enlace troncal
802.1Q para extenderlas entre ambos dispositivos fisicos. Los equipos de una
misma VLAN pueden comunicarse aunque esten conectados a switches diferentes,
mientras que los equipos de VLAN distintas permanecen aislados.

```text
VLAN 2: PC0 en SW0 <----------> PC3 en SW1
VLAN 3: PC1 en SW0 <----------> PC4 en SW1
VLAN 4: PC2 en SW0 <----------> PC5 en SW1
                  enlace troncal
```

No se configura enrutamiento inter-VLAN. Por tanto, las tres VLAN se comportan
como tres dominios de broadcast independientes.

## Archivo de Packet Tracer

[Descargar practica-4-1-vlan-entre-switches.pkt](packet-tracer/04-01-vlan-entre-switches/practica-4-1-vlan-entre-switches.pkt)

SHA-256:

```text
6F426A92AF4F14D846801DE60BE4D6AFB415F7ADB2F2B871FAEAB814EFC233E7
```

## Objetivos

- Crear las VLAN 2, 3 y 4 en dos switches.
- Asignar puertos de acceso a cada VLAN.
- Configurar un enlace troncal entre los switches.
- Permitir comunicacion entre equipos de la misma VLAN en switches distintos.
- Comprobar el aislamiento entre VLAN diferentes.
- Demostrar que cambiar una IP no cambia la VLAN del puerto.

## Topologia y direccionamiento

| Equipo | Direccion | Switch | Puerto | VLAN |
| --- | --- | --- | --- | --- |
| PC0 | `192.168.1.2/24` | SW0 | `Fa0/1` | 2 |
| PC1 | `192.168.2.2/24` | SW0 | `Fa0/2` | 3 |
| PC2 | `192.168.3.2/24` | SW0 | `Fa0/3` | 4 |
| PC3 | `192.168.1.3/24` | SW1 | `Fa0/1` | 2 |
| PC4 | `192.168.2.3/24` | SW1 | `Fa0/2` | 3 |
| PC5 | `192.168.3.3/24` | SW1 | `Fa0/3` | 4 |

`Gi0/1` de SW0 se conecta con `Gi0/1` de SW1. Los PCs no necesitan puerta de
enlace porque solo se prueban comunicaciones dentro de cada red local. Para
comunicar VLAN distintas seria necesario incorporar un router o un switch de
capa 3.

## Interpretacion del enunciado

La separacion fisica procede de utilizar dos switches. La separacion logica
procede de dividir sus puertos en tres VLAN. El enlace troncal mantiene esa
division mientras transporta las tres VLAN entre SW0 y SW1.

La frase "que puedan comunicarse entre si" se aplica a los miembros de la misma
VLAN:

| Comunicacion | Resultado esperado |
| --- | --- |
| PC0 con PC3 | Permitida: ambos pertenecen a VLAN 2 |
| PC1 con PC4 | Permitida: ambos pertenecen a VLAN 3 |
| PC2 con PC5 | Permitida: ambos pertenecen a VLAN 4 |
| PC0 con PC4 | Bloqueada: VLAN 2 frente a VLAN 3 |

## 1. Creacion de VLAN en SW0

```cisco
enable
configure terminal
hostname SW0

vlan 2
name VLAN-RED1
vlan 3
name VLAN-RED2
vlan 4
name VLAN-RED3
```

- `enable` entra en el modo privilegiado de IOS.
- `configure terminal` abre la configuracion global.
- `hostname SW0` identifica el primer switch.
- `vlan` crea la VLAN en la base local del switch.
- `name` asigna una etiqueta descriptiva.

Se configuran los puertos conectados a los PCs como puertos de acceso:

```cisco
interface FastEthernet0/1
switchport mode access
switchport access vlan 2

interface FastEthernet0/2
switchport mode access
switchport access vlan 3

interface FastEthernet0/3
switchport mode access
switchport access vlan 4
```

`switchport mode access` hace que el puerto transporte una unica VLAN hacia el
equipo final. `switchport access vlan` determina a que VLAN pertenece cualquier
trama sin etiqueta que entra por ese puerto.

Se configura el enlace entre switches:

```cisco
interface GigabitEthernet0/1
switchport mode trunk
switchport trunk allowed vlan 2,3,4
end
write memory
```

- `switchport mode trunk` activa el transporte de varias VLAN mediante 802.1Q.
- `switchport trunk allowed vlan 2,3,4` limita el troncal a las VLAN utilizadas.
- `write memory` conserva la configuracion tras reiniciar el equipo.

## 2. Configuracion de SW1

En el segundo switch se crean las mismas VLAN y se asignan los mismos numeros de
puerto. Los identificadores VLAN deben coincidir en ambos extremos del troncal:

```cisco
enable
configure terminal
hostname SW1

vlan 2
name VLAN-RED1
vlan 3
name VLAN-RED2
vlan 4
name VLAN-RED3

interface FastEthernet0/1
switchport mode access
switchport access vlan 2

interface FastEthernet0/2
switchport mode access
switchport access vlan 3

interface FastEthernet0/3
switchport mode access
switchport access vlan 4

interface GigabitEthernet0/1
switchport mode trunk
switchport trunk allowed vlan 2,3,4
end
write memory
```

## 3. Verificacion de switches

En ambos switches se ejecutan:

```cisco
show vlan brief
show interfaces trunk
```

`show vlan brief` confirma:

```text
VLAN 2  VLAN-RED1  Fa0/1
VLAN 3  VLAN-RED2  Fa0/2
VLAN 4  VLAN-RED3  Fa0/3
```

El puerto troncal no aparece como puerto de acceso dentro de `show vlan brief`.
`show interfaces trunk` confirma que `Gi0/1` esta en estado `trunking`, utiliza
802.1Q y permite las VLAN 2, 3 y 4.

## 4. Pruebas de comunicacion

Una vez configuradas las IP, se comprueban las parejas de cada VLAN:

```text
PC0> ping 192.168.1.3
PC1> ping 192.168.2.3
PC2> ping 192.168.3.3
```

Las tres pruebas responden. En cada caso, la trama entra por un puerto de acceso,
atraviesa el troncal identificada con su VLAN y sale por el puerto equivalente
del segundo switch.

Desde PC0 se prueba un destino de VLAN 3:

```text
PC0> ping 192.168.2.3
```

La solicitud agota el tiempo de espera. SW0 no reenvia la trama de VLAN 2 hacia
un puerto perteneciente a VLAN 3 y no existe ningun equipo que enrute entre
ambas.

## 5. Prueba cambiando solamente la IP

Para demostrar que la direccion IP no determina la VLAN, PC0 se mantiene
conectado a `SW0 Fa0/1`, que continua asignado a VLAN 2, pero cambia temporalmente
su direccion:

```text
IP original: 192.168.1.2/24
IP temporal: 192.168.2.10/24
```

Aunque PC0 parece estar ahora en la misma subred IPv4 que PC1 y PC4, estas
pruebas fallan:

```text
PC0> ping 192.168.2.2
PC0> ping 192.168.2.3
```

PC0 sigue enviando sus tramas dentro de VLAN 2 porque la pertenencia se define
en el puerto del switch. PC1 y PC4 pertenecen a VLAN 3 y, por tanto, quedan en
otro dominio de capa 2. Finalmente se devuelve PC0 a `192.168.1.2/24`.

## Resultados

| Origen | Destino | Relacion | Resultado |
| --- | --- | --- | --- |
| PC0 | PC3 | VLAN 2, switches diferentes | Correcto |
| PC1 | PC4 | VLAN 3, switches diferentes | Correcto |
| PC2 | PC5 | VLAN 4, switches diferentes | Correcto |
| PC0 | PC4 | VLAN 2 hacia VLAN 3 | Bloqueado |
| PC0 con IP `192.168.2.10` | PC1 y PC4 | Misma subred IP aparente, VLAN distinta | Bloqueado |

## Evidencias

| Nº | Evidencia | Que muestra |
| --- | --- | --- |
| 001 | [Topologia](evidencias/04-01-vlan-entre-switches/001-topologia-vlan-dos-switches.png) | Dos switches, seis PCs y enlace entre switches. |
| 002 | [Configuracion de SW0](evidencias/04-01-vlan-entre-switches/002-configuracion-sw0.png) | VLAN, puertos de acceso y troncal en SW0. |
| 003 | [Configuracion de SW1](evidencias/04-01-vlan-entre-switches/003-configuracion-sw1.png) | VLAN, puertos de acceso y troncal en SW1. |
| 004 | [VLAN y troncal de SW0](evidencias/04-01-vlan-entre-switches/004-sw0-vlan-y-trunk.png) | Puertos por VLAN y `Gi0/1` en trunking. |
| 005 | [VLAN de SW1](evidencias/04-01-vlan-entre-switches/005-sw1-vlan-brief.png) | VLAN 2, 3 y 4 activas en SW1. |
| 006 | [Troncal de SW1](evidencias/04-01-vlan-entre-switches/006-sw1-enlace-troncal.png) | VLAN permitidas y activas en el troncal. |
| 007 | [VLAN 2 y aislamiento](evidencias/04-01-vlan-entre-switches/007-pc0-vlan2-y-aislamiento-vlan3.png) | PC0 alcanza PC3, pero no un destino de VLAN 3. |
| 008 | [Cambio de IP](evidencias/04-01-vlan-entre-switches/008-cambio-ip-no-cambia-vlan.png) | PC0 con `192.168.2.10` sigue aislado de VLAN 3. |
| 009 | [Comunicacion VLAN 3](evidencias/04-01-vlan-entre-switches/009-comunicacion-vlan3.png) | PC1 alcanza PC4 a traves del troncal. |
| 010 | [Comunicacion VLAN 4](evidencias/04-01-vlan-entre-switches/010-comunicacion-vlan4.png) | PC2 alcanza PC5 a traves del troncal. |

## Consideraciones de seguridad

Una VLAN reduce el alcance de broadcasts y separa dominios de capa 2, pero no
debe considerarse por si sola una frontera de seguridad completa. En una red
real tambien se aplicarian:

- VLAN de gestion independiente.
- Puertos no utilizados apagados y asignados a una VLAN sin uso.
- VLAN nativa distinta de VLAN 1.
- Troncales configurados de forma estatica y con lista de VLAN permitidas.
- Desactivacion de negociacion DTP cuando el equipo lo permita.
- ACL o firewall para controlar cualquier enrutamiento inter-VLAN.
- Protecciones contra DHCP spoofing, ARP spoofing y VLAN hopping.

## Conclusion

Las VLAN 2, 3 y 4 se extienden correctamente entre SW0 y SW1 mediante un troncal
802.1Q. Los equipos de cada pareja se comunican a traves de switches fisicamente
distintos, mientras que las VLAN permanecen aisladas. La prueba de cambiar solo
la IP de PC0 confirma que la pertenencia a una VLAN depende del puerto del switch
y no de la direccion de capa 3 configurada en el equipo.
