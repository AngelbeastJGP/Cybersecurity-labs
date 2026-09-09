# Evidencias - 3.1 infraestructura de clave publica

Capturas de la practica:

[3.1 - Creacion de una infraestructura de clave publica](../../03-01-infraestructura-clave-publica.md)

## Indice

| Nº | Archivo | Contenido |
| --- | --- | --- |
| 001 | [virtualbox-maquina-ca-raiz](001-virtualbox-maquina-ca-raiz.png) | VM independiente para la CA raiz. |
| 002 | [ca-raiz-estructura-directorios](002-ca-raiz-estructura-directorios.png) | Estructura inicial de la CA raiz. |
| 003 | [ca-sub-estructura-directorios](003-ca-sub-estructura-directorios.png) | Estructura inicial de la CA subordinada. |
| 004 | [ca-sub-csr-verificada](004-ca-sub-csr-verificada.png) | CSR de la subordinada comprobada. |
| 005 | [ca-raiz-firma-ca-subordinada](005-ca-raiz-firma-ca-subordinada.png) | Firma de la subordinada. |
| 006 | [ca-raiz-verifica-ca-subordinada](006-ca-raiz-verifica-ca-subordinada.png) | Validacion desde la raiz. |
| 007 | [srv-alma-verifica-ca-subordinada](007-srv-alma-verifica-ca-subordinada.png) | Validacion desde SRV-ALMA. |
| 008 | [ca-sub-firma-certificado-web](008-ca-sub-firma-certificado-web.png) | Emision del certificado HTTPS. |
| 009 | [ca-sub-verifica-certificado-web](009-ca-sub-verifica-certificado-web.png) | Verificacion de la cadena completa. |
| 010 | [certificado-web-emisor-y-validez](010-certificado-web-emisor-y-validez.png) | Sujeto, emisor y vigencia. |
| 011 | [apache-configuracion-certificado-tls](011-apache-configuracion-certificado-tls.png) | Certificado y clave configurados en Apache. |
| 012 | [apache-https-activo](012-apache-https-activo.png) | Estado activo de Apache. |
| 013 | [firewall-puerto-443](013-firewall-puerto-443.png) | HTTPS permitido y puerto 443 en escucha. |
| 014 | [pc2-importa-ca-raiz](014-pc2-importa-ca-raiz.png) | Instalacion de confianza en PC2. |
| 015 | [pc2-validacion-https-final](015-pc2-validacion-https-final.png) | Certificado valido y respuesta HTTP 200. |

No se incluyen claves privadas, frases de paso ni contenidos secretos. Las
capturas solo muestran material publico, configuracion y resultados de
verificacion.
