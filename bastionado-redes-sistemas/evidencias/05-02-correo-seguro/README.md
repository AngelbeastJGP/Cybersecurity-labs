# Evidencias - 5.2 Servidor de correo seguro

Capturas asociadas a la practica:

[5.2 - Instalacion y configuracion de un servidor de correo seguro](../../05-02-servidor-correo-seguro.md)

| Nº | Archivo | Contenido |
| --- | --- | --- |
| 001 | [certificado-correo-verificado](001-certificado-correo-verificado.png) | Cadena, sujeto, emisor, vigencia y SAN del certificado. |
| 002 | [postfix-tls-sasl](002-postfix-tls-sasl.png) | Identidad, TLS, SASL y rutas criptograficas de Postfix. |
| 003 | [dovecot-tls-maildir](003-dovecot-tls-maildir.png) | Configuracion efectiva de Dovecot y socket SASL. |
| 004 | [spf-rechazo](004-spf-rechazo.png) | Rechazo SPF de una direccion no autorizada. |
| 005 | [clamav-servicios-puertos](005-clamav-servicios-puertos.png) | Servicios ClamAV habilitados y puertos solo en loopback. |
| 006 | [clamav-eicar-rechazado](006-clamav-eicar-rechazado.png) | Deteccion EICAR, rechazo del milter y mensaje rebotado. |
| 007 | [smtp-starttls-autenticado](007-smtp-starttls-autenticado.png) | Envio remoto con TLS y autenticacion correcta. |
| 008 | [mensajes-recibidos-maildir](008-mensajes-recibidos-maildir.png) | Mensajes legitimos almacenados para `correo2`. |
| 009 | [remitente-bloqueado](009-remitente-bloqueado.png) | Respuesta SMTP `554` para una cuenta excluida. |
| 010 | [mapas-acceso-registro](010-mapas-acceso-registro.png) | Resultado de los mapas y entrada de rechazo en el journal. |
| 011 | [submission-exige-starttls](011-submission-exige-starttls.png) | Respuesta `530` antes de iniciar TLS en el puerto 587. |
| 012 | [pop3s-certificado-valido](012-pop3s-certificado-valido.png) | POP3S con TLS 1.3 y verificacion de certificado correcta. |

No se incluye la captura de una prueba inicial que mostro una contraseña. La
credencial se cambio y las evidencias publicadas no contienen secretos.
