# 5.3 - IPsec de sitio a sitio y acceso VPN de cliente

## Resumen

Esta practica conecta dos redes internas mediante un tunel IPsec IKEv2 entre
dos routers Debian y, despues, permite que un cliente Windows acceda a la red
de servidores a traves de otra VPN IKEv2 terminada en el router de la sede A.

La primera conexion usa una clave precompartida (PSK). La segunda aprovecha la
PKI de la practica 3.1: el router se autentica con un certificado emitido por
la CA subordinada y el usuario de Windows lo hace mediante EAP-MSCHAPv2. Las
pruebas finales incluyen establecimiento de asociaciones de seguridad,
contadores de trafico, asignacion de IP, ICMP, conexion TCP y respuesta HTTP.

```text
Sede B                                             Sede A
PC-SEDE-B 10.20.0.10                              SRV-ALMA 10.0.0.20
       |                                                   |
Router B 10.20.0.1/24 -- IPsec IKEv2/PSK -- Router A 10.0.0.1/24
         172.16.50.2                 172.16.50.1
                                        |
                                  IKEv2/certificado + EAP
                                        |
                              WIN-VPN 172.16.50.100
                              IP virtual 10.30.0.10
```

## Objetivos y escenario

- Establecer un tunel protegido entre `10.0.0.0/24` y `10.20.0.0/24`.
- Permitir el acceso de un cliente Windows a `10.0.0.0/24` mediante IKEv2.
- Reutilizar la CA raiz y la CA subordinada existentes, sin distribuir claves
  privadas de las autoridades de certificacion.
- Verificar trafico y servicios, no solo el estado administrativo de la VPN.

| Equipo | Papel | Direcciones relevantes |
| --- | --- | --- |
| Router A, Debian 11 | Puerta de enlace de servidores y concentrador VPN | `10.0.0.1/24`, `172.16.50.1/24` |
| Router B, Debian 11 | Puerta de enlace de la segunda sede | `10.20.0.1/24`, `172.16.50.2/24` |
| SRV-ALMA | Servidor HTTP y CA subordinada | `10.0.0.20/24` |
| PC-SEDE-B | Cliente de la segunda sede | `10.20.0.10/24` |
| WIN-VPN | Cliente de acceso remoto | `172.16.50.100/24`; IP VPN `10.30.0.10` |

Las interfaces `172.16.50.1` y `172.16.50.2` pertenecen a la red interna
VirtualBox `WAN-IPSEC`. En Router A, `enp0s8` sirve la red de servidores,
`enp0s9` la red de clientes preexistente, `enp0s10` la red IPsec y `enp0s3`
la salida NAT de VirtualBox. En Router B, `enp0s8` conecta con `WAN-IPSEC` y
`enp0s9` con la LAN de la segunda sede.

## 1. Preparacion de red

Se comprobaron las direcciones y rutas de ambos routers con `ip -4 -br
address` e `ip -4 route`. Router A tenia `net.ipv4.ip_forward = 1`; su cadena
`forward` de nftables aceptaba el trafico y el `masquerade` se aplicaba solo
a la interfaz de salida `enp0s3`. Esto evitaba enmascarar el trafico entre las
LAN del laboratorio. Router B tambien necesitaba reenviar paquetes entre su
red local y la interfaz del tunel.

Antes de establecer IPsec se comprobo la conectividad directa entre
`172.16.50.1` y `172.16.50.2`. Desde `PC-SEDE-B` se alcanzaban el router B
y el router A, pero todavia no `10.0.0.20`: era el comportamiento esperado
antes de instalar la asociacion de seguridad y completar las pruebas de
extremo a extremo.

## 2. IPsec entre las dos sedes

Se instalo strongSwan en ambos routers con `charon-systemd` y la utilidad
`swanctl`. En Debian 11 se encontro un problema con los repositorios
ordinarios: la descarga de paquetes devolvia HTTP 404. Se actualizaron las
fuentes del sistema al archivo de Debian y, tras `apt-get update`, se pudo
instalar el software. La comprobacion posterior mostro el servicio
`strongswan` activo.

```bash
apt-get update
apt-get install strongswan-swanctl charon-systemd
systemctl is-active strongswan
```

Se genero una PSK aleatoria en Router A con `openssl rand`, se guardo con
permisos `0600` y se transfirio a Router B mediante `scp` tras habilitar SSH
en el destino. La PSK no se incluye en este repositorio. En los ficheros de
`/etc/swanctl/conf.d/` se configuraron los dos extremos IKEv2:

| Parametro | Router A | Router B |
| --- | --- | --- |
| Direccion local | `172.16.50.1` | `172.16.50.2` |
| Direccion remota | `172.16.50.2` | `172.16.50.1` |
| Subred local protegida | `10.0.0.0/24` | `10.20.0.0/24` |
| Subred remota protegida | `10.20.0.0/24` | `10.0.0.0/24` |
| Autenticacion | PSK | PSK |
| IKE | AES-256-GCM, PRF SHA-384, ECP-384 | La misma propuesta |
| ESP | AES-256-GCM | La misma propuesta |

La conexion se denomino `sede-a-b` y su CHILD_SA `redes`. En Router A se
comprobaron el archivo de configuracion y los selectores `local_ts` y
`remote_ts`, y se cargaron las credenciales y conexiones:

```bash
/usr/sbin/swanctl --load-creds
/usr/sbin/swanctl --load-conns
/usr/sbin/swanctl --list-conns
/usr/sbin/swanctl --list-pols
/usr/sbin/swanctl --initiate --child redes
/usr/sbin/swanctl --list-sas
```

La iniciacion termino correctamente: IKE_SA `ESTABLISHED` y CHILD_SA
`INSTALLED`, con las subredes esperadas en cada extremo. Una primera prueba
ICMP desde `PC-SEDE-B` fallo porque `SRV-ALMA` estaba apagado; no era un
fallo de negociacion de IPsec. Tras encenderlo, `PC-SEDE-B` recibio tres
respuestas de `10.0.0.20` sin perdida. Los contadores de entrada y salida
de ambas CHILD_SA aumentaron de manera coherente, confirmando trafico real
en los dos sentidos.

## 3. Certificado del concentrador

Para el acceso de Windows se reutilizo la jerarquia PKI de la
[practica 3.1](03-01-infraestructura-clave-publica.md). En Router A se creo
una clave RSA de 3072 bits protegida con permisos restrictivos y una CSR con
identidad `CN=172.16.50.1` y SAN de tipo DNS e IP para `172.16.50.1`.
Solo se traslado la CSR publica a `SRV-ALMA`; la clave privada del router
permanecio en Router A.

`SRV-ALMA` firmo la CSR con la CA subordinada, generando un certificado de
servidor con `CA:FALSE`, usos `digitalSignature` y `keyEncipherment`, EKU
`TLS Web Server Authentication` y SAN `DNS:172.16.50.1` e
`IP Address:172.16.50.1`. La firma, el sujeto, la vigencia, los SAN y la
cadena hasta la CA raiz se comprobaron con OpenSSL. La verificacion con
`-purpose sslserver -verify_hostname 172.16.50.1` termino en `OK`.

La firma y la comprobacion de la cadena en `SRV-ALMA` quedaron registradas
con estos comandos (la clave de la CA solicito su frase de paso de forma
interactiva):

```bash
openssl x509 -req -in /root/ca-sub/csr/router-a-vpn.csr.pem \
  -CA /root/ca-sub/certs/ca-sub.cert.pem \
  -CAkey /root/ca-sub/private/ca.sub.key.pem -CAcreateserial \
  -out /root/ca-sub/certs/router-a-vpn.cert.pem \
  -days 825 -sha256 -extfile /root/ca-sub/vpn-router-a.ext \
  -extensions vpn_server

openssl verify -CAfile /root/ca-sub/certs/ca-raiz.cert.pem \
  -untrusted /root/ca-sub/certs/ca-sub.cert.pem \
  -purpose sslserver -verify_hostname 172.16.50.1 \
  /root/ca-sub/certs/router-a-vpn.cert.pem
```

La CSR se transporto con un servidor HTTP temporal iniciado en Router A;
la primera descarga apunto al puerto incorrecto (`8765`) y se repitio en
`8764`. Se comparo el SHA-256 de la CSR en origen y destino. Los certificados
publicos del router y de las dos CA se devolvieron a Router A, se compararon
sus hashes y se verifico de nuevo la cadena. El servidor HTTP temporal se
detuvo al terminar. La clave privada de la CA subordinada nunca se copio al
router ni a Windows.

En Router A se instalaron el certificado de servidor en `/etc/swanctl/x509/`,
su clave privada en `/etc/swanctl/private/` con modo `0600`, y las CA en
`/etc/swanctl/x509ca/`. `swanctl --load-creds` confirmo la carga de los
certificados, la clave RSA y la PSK de la conexion entre sedes.

## 4. Acceso remoto IKEv2

Se instalaron los componentes adicionales de strongSwan necesarios para
EAP-MSCHAPv2. `swanctl --stats` mostro cargados los plugins `eap-identity`
y `eap-mschapv2`. En Router A se creo la conexion `win-vpn` y el pool
`win-vpn-pool`. Los parametros relevantes de
`/etc/swanctl/conf.d/20-win-vpn.conf` fueron:

```bash
apt-get install libcharon-extra-plugins strongswan-pki
systemctl restart strongswan
/usr/sbin/swanctl --stats
```

```ini
connections {
  win-vpn {
    version = 2
    local_addrs = 172.16.50.1
    remote_addrs = %any
    proposals = aes256-sha256-modp2048
    pools = win-vpn-pool
    local {
      auth = pubkey
      certs = router-a-vpn.cert.pem
      id = @172.16.50.1
    }
    remote {
      auth = eap-mschapv2
      eap_id = %any
    }
    children {
      win-lan {
        local_ts = 10.0.0.0/24
        remote_ts = dynamic
        esp_proposals = aes256-sha256-modp2048
      }
    }
  }
}
pools {
  win-vpn-pool {
    addrs = 10.30.0.10-10.30.0.30
  }
}
```

La identidad `@172.16.50.1` corresponde al nombre DNS incluido en el SAN
del certificado, aunque ese nombre tenga formato de direccion IP. Un fichero
separado de secretos, con permisos `0600`, almacena el usuario EAP `winvpn`
y su contraseña privada. Aqui no se publica el valor del secreto. Tras
reiniciar strongSwan se cargaron de nuevo credenciales, conexiones y pool;
`--list-conns` mostraba tanto `sede-a-b` como `win-vpn`, y `--list-pools`
mostraba 21 direcciones disponibles.

## 5. Preparacion del cliente Windows

La interfaz de `WIN-VPN` se conecto en VirtualBox a `WAN-IPSEC` en lugar de
la red interna de clientes anterior. Se fijo `172.16.50.100/24`, sin puerta
de enlace predeterminada, y se comprobo que alcanzaba `172.16.50.1`.

Windows descargo los certificados publicos de la CA raiz y subordinada.
Los SHA-256 calculados en Windows coincidieron con los obtenidos en Router A.
En PowerShell elevado se importaron respectivamente en los almacenes de
entidades raiz de confianza e intermedias:

```powershell
certutil.exe -addstore -f Root "$env:USERPROFILE\Downloads\ca-raiz.cert.pem"
certutil.exe -addstore -f CA "$env:USERPROFILE\Downloads\ca-sub.cert.pem"
```

Se creo una VPN IKEv2 de tunel dividido con EAP-MSCHAPv2, se fijaron los
algoritmos IPsec para que coincidieran con los del router y se agrego la
ruta de la red de servidores:

```powershell
$eap = New-EapConfiguration
Add-VpnConnection -Name "VPN-Garea" -ServerAddress "172.16.50.1" `
  -TunnelType Ikev2 -AuthenticationMethod Eap `
  -EapConfigXmlStream $eap.EapConfigXmlStream `
  -EncryptionLevel Maximum -SplitTunneling -PassThru

Set-VpnConnectionIPsecConfiguration -ConnectionName "VPN-Garea" `
  -AuthenticationTransformConstants SHA256128 `
  -CipherTransformConstants AES256 `
  -EncryptionMethod AES256 -IntegrityCheckMethod SHA256 `
  -DHGroup Group14 -PfsGroup PFS2048 -PassThru -Force

Add-VpnConnectionRoute -ConnectionName "VPN-Garea" `
  -DestinationPrefix "10.0.0.0/24" -PassThru
```

En la interfaz de Windows se introdujeron `winvpn` y su contraseña sin
mostrarlos en la documentacion. El estado paso a `Connected`. En Router A,
`swanctl --list-sas` mostro la IKE_SA `ESTABLISHED`, la CHILD_SA `INSTALLED`
y la IP virtual `10.30.0.10` asignada al cliente. Los selectores eran
`10.0.0.0/24` y `10.30.0.10/32`.

## 6. Pruebas de extremo a extremo

| Comprobacion | Resultado observado |
| --- | --- |
| PC-SEDE-B a `10.0.0.20` | 3 respuestas ICMP, 0 % de perdida despues de encender SRV-ALMA. |
| SA entre sedes | IKE `ESTABLISHED`, CHILD `INSTALLED`; contadores en ambos routers. |
| Estado de `VPN-Garea` | `Connected`. |
| Asignacion de IP de Windows | `10.30.0.10` dentro del pool `10.30.0.10-10.30.0.30`. |
| Windows a `10.0.0.20` | 4 respuestas ICMP, 0 % de perdida. |
| Contadores IPsec cliente/servidor | 4 paquetes y 240 bytes en cada sentido tras el ping. |
| TCP desde Windows a `10.0.0.20:80` | `TcpTestSucceeded : True`, interfaz `VPN-Garea`, origen `10.30.0.10`. |
| Solicitud HTTP al servidor | `Invoke-WebRequest http://10.0.0.20` devolvio `200 OK` y la pagina de prueba. |

Las pruebas del cliente se ejecutaron en PowerShell con:

```powershell
Get-VpnConnection -Name "VPN-Garea" | Select-Object Name,ConnectionStatus
ping 10.0.0.20
Test-NetConnection 10.0.0.20 -Port 80
Invoke-WebRequest -UseBasicParsing http://10.0.0.20
```

Estas comprobaciones distinguen tres niveles: la VPN negociada, la
transmision real de paquetes por el tunel y la respuesta de un servicio de
aplicacion. Una prueba TCP positiva por si sola no habria acreditado que el
servidor HTTP entregase contenido; la solicitud `Invoke-WebRequest` si lo
confirmo.

## Incidencias y decisiones

- **Repositorios Debian 11:** las URL iniciales devolvian HTTP 404. Se uso
`archive.debian.org` para instalar los paquetes del laboratorio.
- **Primera prueba entre sedes:** el destino `SRV-ALMA` estaba apagado. El
  tunel ya estaba instalado; al encenderlo, ICMP y contadores funcionaron.
- **Transferencia de la CSR:** el intento en el puerto `8765` fue rechazado;
  el servicio temporal escuchaba en `8764` y la descarga se repitio ahi.
- **Cliente Windows:** la interfaz se paso a `WAN-IPSEC`, se importo la
  cadena de confianza y se ajustaron propuestas IKE/ESP y ruta de tunel
  dividido antes de conectar.

## Seguridad y limites

- Las capturas y este texto no incluyen la PSK, la contraseña EAP ni ninguna
  clave privada. Los ficheros de secretos del laboratorio tienen modo `0600`.
- La CA raiz y la CA subordinada se distribuyeron solo como certificados
  publicos; la clave privada de la CA permanecio en `SRV-ALMA`.
- Los ficheros publicos usados para la transferencia HTTP permanecen como
  material de intercambio del laboratorio. Se deben retirar de los
  directorios web cuando ya no sean necesarios.
- El uso de HTTP para transferir certificados no aporta confidencialidad;
  por eso se compararon hashes y se verifico la cadena. Para un despliegue
  real se preferiria un canal de distribucion autenticado.
- La autenticacion EAP-MSCHAPv2 con usuario y contraseña fue una eleccion
  para este laboratorio. Un entorno de produccion requiere politicas de
  identidad, rotacion, registro, mantenimiento y actualizaciones adecuadas.
- Debian 11 y los repositorios archivados no son una base apropiada para
  exponer este servicio fuera de un entorno aislado.

## Evidencias

El [indice de capturas](evidencias/05-03-ipsec-vpn/README.md) describe cada
imagen. Las principales son:

| Nº | Evidencia | Demuestra |
| --- | --- | --- |
| 004 | [Configuracion entre sedes](evidencias/05-03-ipsec-vpn/004-sede-a-selectores.png) | Direcciones y selectores del tunel. |
| 007 | [Trafico entre sedes](evidencias/05-03-ipsec-vpn/007-sedes-sas-trafico.png) | CHILD_SA instaladas y contadores en ambos sentidos. |
| 010 | [Certificado emitido](evidencias/05-03-ipsec-vpn/010-certificado-router-firmado.png) | Firma de la CA subordinada. |
| 017 | [Perfil Windows](evidencias/05-03-ipsec-vpn/017-windows-perfil-vpn.png) | VPN IKEv2 con EAP y tunel dividido. |
| 019 | [Conexion establecida](evidencias/05-03-ipsec-vpn/019-vpn-sa-ip-virtual.png) | IKE/CHILD instaladas e IP virtual. |
| 020 | [Ping a SRV-ALMA](evidencias/05-03-ipsec-vpn/020-windows-ping-y-contadores.png) | Paquetes ICMP y contadores IPsec. |
| 021 | [Puerto HTTP](evidencias/05-03-ipsec-vpn/021-windows-tcp-80.png) | Acceso TCP por `VPN-Garea`. |
| 022 | [HTTP 200](evidencias/05-03-ipsec-vpn/022-windows-http-200.png) | Pagina servida a traves de la VPN. |

## Conclusion

Se validaron las dos modalidades solicitadas: IPsec entre las LAN de las
sedes y acceso IKEv2 de un cliente Windows a la red de servidores. Los
estados `ESTABLISHED` e `INSTALLED` se respaldaron con pruebas de paquetes
en ambos sentidos y, en el caso de Windows, con una respuesta HTTP `200 OK`
del servidor interno.
