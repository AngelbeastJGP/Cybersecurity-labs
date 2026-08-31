# Evidencias - 01 infraestructura segmentada

Esta carpeta contiene las capturas usadas como evidencia de la práctica:

[01 - Construcción de una infraestructura segmentada](../../01-construccion-infraestructura-segmentada.md)

## Índice de capturas

| Nº | Archivo | Qué muestra |
| --- | --- | --- |
| 001 | [router-adaptadores-virtualbox](001-router-adaptadores-virtualbox.png) | Adaptadores de red de la máquina router en VirtualBox. |
| 002 | [router-interfaces-iniciales](002-router-interfaces-iniciales.png) | Interfaces detectadas inicialmente en Debian. |
| 003 | [router-error-nombres-interfaces](003-router-error-nombres-interfaces.png) | Error provocado por la configuración antigua con `eth0`. |
| 004 | [router-etc-network-interfaces](004-router-etc-network-interfaces.png) | Configuración de `/etc/network/interfaces`. |
| 005 | [router-ip-forward-activo](005-router-ip-forward-activo.png) | Reenvío IPv4 activado. |
| 006 | [router-nftables-servicio-activo](006-router-nftables-servicio-activo.png) | Servicio `nftables` habilitado y activo. |
| 007 | [router-nftables-masquerade](007-router-nftables-masquerade.png) | Regla de masquerade sobre `enp0s3`. |
| 008 | [dhcp-interfaz-enp0s9](008-dhcp-interfaz-enp0s9.png) | ISC DHCP configurado para escuchar en la red de clientes. |
| 009 | [pc0-instalacion-windows-sin-red](009-pc0-instalacion-windows-sin-red.png) | Instalación de Windows sin conectividad inicial. |
| 010 | [pc0-red-interna-clientes](010-pc0-red-interna-clientes.png) | Adaptador de PC0 conectado a la red interna de clientes. |
| 011 | [pc0-prueba-inicial-fallo-gateway-clientes](011-pc0-prueba-inicial-fallo-gateway-clientes.png) | Prueba inicial fallida contra la puerta de enlace de clientes. |
| 012 | [pc0-ip-manual-correcta](012-pc0-ip-manual-correcta.png) | PC0 con IP `200.0.100.100` y gateway `200.0.100.1`. |
| 013 | [pc1-dhcp-200-0-100-101](013-pc1-dhcp-200-0-100-101.png) | PC1 recibe `200.0.100.101`. |
| 014 | [pc2-dhcp-200-0-100-102](014-pc2-dhcp-200-0-100-102.png) | PC2 recibe `200.0.100.102`. |
| 015 | [pc2-sin-salida-internet](015-pc2-sin-salida-internet.png) | PC2 llega al router, pero aún sin salida externa. |
| 016 | [router-rutas-recuperadas](016-router-rutas-recuperadas.png) | Ruta por defecto recuperada en el router. |
| 017 | [srv-windows-ip-fija](017-srv-windows-ip-fija.png) | Configuración IP fija de `SRV-WINDOWS`. |
| 018 | [srv-windows-ad-garea-local](018-srv-windows-ad-garea-local.png) | Consola de Active Directory con el dominio `garea.local`. |
| 019 | [pc0-unido-dominio](019-pc0-unido-dominio.png) | PC0 unido al dominio. |
| 020 | [ad-equipos-pc0-pc1](020-ad-equipos-pc0-pc1.png) | Equipos PC0 y PC1 visibles en Active Directory. |
| 021 | [srv-windows-roles-ad-dns](021-srv-windows-roles-ad-dns.png) | Roles de AD DS y DNS en el servidor Windows. |
| 022 | [srv-alma-conectividad](022-srv-alma-conectividad.png) | `SRV-ALMA` con IP fija y conectividad externa. |
| 023 | [srv-alma-httpd-activo](023-srv-alma-httpd-activo.png) | Servicio Apache/httpd activo. |
| 024 | [srv-alma-sshd-activo](024-srv-alma-sshd-activo.png) | Servicio SSH activo. |
| 025 | [apache-acceso-web](025-apache-acceso-web.png) | Acceso web a Apache desde cliente. |
| 026 | [webmin-acceso-web](026-webmin-acceso-web.png) | Acceso web a Webmin. |
| 027 | [openldap-error-objectclass-posixgroup](027-openldap-error-objectclass-posixgroup.png) | Error de `objectClass` al crear el grupo LDAP. |
| 028 | [openldap-error-schema-nis](028-openldap-error-schema-nis.png) | Error relacionado con esquemas LDAP. |
| 029 | [openldap-grupo-creado](029-openldap-grupo-creado.png) | Grupo `usuariosldap` creado en LDAP. |
| 030 | [openldap-usuario-prueba01](030-openldap-usuario-prueba01.png) | Usuario `prueba01` visible con atributos POSIX; el hash de contraseña está oculto. |
| 031 | [pc2-getent-ldap-directo](031-pc2-getent-ldap-directo.png) | Consulta `getent` directa contra LDAP. |
| 032 | [pc2-nsswitch-ldap](032-pc2-nsswitch-ldap.png) | Revisión de integración NSS con LDAP. |
| 033 | [pc2-pam-mkhomedir](033-pc2-pam-mkhomedir.png) | Activación de creación automática de home. |
| 034 | [pc1-ipconfig-dominio-dns](034-pc1-ipconfig-dominio-dns.png) | PC1 con dominio, gateway y DNS interno. |
| 035 | [pc1-pruebas-dns-conectividad](035-pc1-pruebas-dns-conectividad.png) | Pruebas de DNS y conectividad desde PC1. |
| 036 | [srv-alma-servicios-ssh-http](036-srv-alma-servicios-ssh-http.png) | Verificación final de SSH y Apache. |
| 037 | [srv-alma-servicios-webmin-slapd](037-srv-alma-servicios-webmin-slapd.png) | Verificación final de Webmin y OpenLDAP. |
| 038 | [srv-alma-puertos-escucha](038-srv-alma-puertos-escucha.png) | Puertos activos en `SRV-ALMA`. |
| 039 | [router-verificacion-final-nat](039-router-verificacion-final-nat.png) | Rutas, reenvío IPv4 y NAT final en el router. |
| 040 | [dhcp-servicio-activo](040-dhcp-servicio-activo.png) | Servicio DHCP activo. |
| 041 | [dhcp-concesiones-clientes](041-dhcp-concesiones-clientes.png) | Concesiones DHCP entregadas a los clientes. |

Las capturas incluyen tanto verificaciones correctas como errores relevantes,
porque esas incidencias explican el proceso real de montaje del laboratorio.
