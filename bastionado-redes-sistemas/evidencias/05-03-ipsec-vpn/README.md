# Evidencias - 5.3 IPsec entre sedes y VPN de cliente

Capturas de la [practica 5.3](../../05-03-ipsec-sitio-sitio-cliente-servidor.md).

| Nº | Archivo | Contenido |
| --- | --- | --- |
| 001 | [router-a-red-base](001-router-a-red-base.png) | Interfaces, rutas, reenvio IPv4 y NAT de Router A. |
| 002 | [router-b-red-base](002-router-b-red-base.png) | Direcciones y rutas de Router B. |
| 003 | [strongswan-activo](003-strongswan-activo.png) | Paquetes instalados y servicio activo. |
| 004 | [sede-a-selectores](004-sede-a-selectores.png) | Conexion IKEv2 de Router A y subredes protegidas. |
| 005 | [sedes-conexiones-cargadas](005-sedes-conexiones-cargadas.png) | Configuracion entre sedes cargada y selectores de trafico. |
| 006 | [sedes-establecidas](006-sedes-establecidas.png) | IKE_SA y CHILD_SA instaladas tras iniciar el tunel. |
| 007 | [sedes-sas-trafico](007-sedes-sas-trafico.png) | Contadores de paquetes en ambos routers. |
| 008 | [sede-b-ping-servidor](008-sede-b-ping-servidor.png) | Respuestas ICMP de SRV-ALMA a PC-SEDE-B. |
| 009 | [router-csr](009-router-csr.png) | Generacion y verificacion de la solicitud de certificado. |
| 010 | [certificado-router-firmado](010-certificado-router-firmado.png) | Firma por la CA subordinada y validacion de cadena. |
| 011 | [certificado-san-eku](011-certificado-san-eku.png) | EKU de servidor y SAN DNS/IP del certificado. |
| 012 | [router-certificados-verificados](012-router-certificados-verificados.png) | Hashes y verificacion del certificado recibido en Router A. |
| 013 | [windows-hashes-ca](013-windows-hashes-ca.png) | Integridad de las CA publicas descargadas en Windows. |
| 014 | [windows-ca-importadas](014-windows-ca-importadas.png) | CA raiz e intermedia incorporadas al almacen de confianza. |
| 015 | [router-vpn-config-cargada](015-router-vpn-config-cargada.png) | Conexiones entre sedes y de Windows, y pool cargado. |
| 016 | [router-eap-plugins](016-router-eap-plugins.png) | Plugins EAP necesarios activos en strongSwan. |
| 017 | [windows-perfil-vpn](017-windows-perfil-vpn.png) | Perfil IKEv2/EAP de tunel dividido. |
| 018 | [windows-ipsec-ruta](018-windows-ipsec-ruta.png) | Propuestas criptograficas y ruta a `10.0.0.0/24`. |
| 019 | [vpn-sa-ip-virtual](019-vpn-sa-ip-virtual.png) | Tunel de Windows instalado e IP virtual `10.30.0.10`. |
| 020 | [windows-ping-y-contadores](020-windows-ping-y-contadores.png) | Ping correcto y paquetes cifrados en ambos sentidos. |
| 021 | [windows-tcp-80](021-windows-tcp-80.png) | Conexion TCP al servidor desde el adaptador VPN. |
| 022 | [windows-http-200](022-windows-http-200.png) | Respuesta HTTP 200 y pagina de prueba. |

No se publican capturas que muestren contraseñas, PSK o claves privadas.
