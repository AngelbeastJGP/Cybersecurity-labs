# Configuracion reproducible - servidor de correo seguro

Fragmentos saneados asociados a la practica
[5.2 - Servidor de correo seguro](../../05-02-servidor-correo-seguro.md).

| Archivo | Destino orientativo | Funcion |
| --- | --- | --- |
| `main.cf.fragment` | `/etc/postfix/main.cf` | Parametros principales de Postfix. |
| `master.cf.fragment` | `/etc/postfix/master.cf` | Submission y servicio SPF. |
| `99-garea-mail.conf` | `/etc/dovecot/conf.d/99-garea-mail.conf` | Dovecot, Maildir y TLS. |
| `mail-server.ext` | Archivo temporal de OpenSSL | Extensiones y SAN del certificado. |
| `client_access` | `/etc/postfix/client_access` | Bloqueo de clientes SMTP. |
| `sender_access` | `/etc/postfix/sender_access` | Bloqueo de remitentes. |
| `policyd-spf.conf` | `/etc/python-policyd-spf/policyd-spf.conf` | Politica SPF. |
| `clamav-milter.conf` | `/etc/mail/clamav-milter.conf` | Conexion entre ClamAV y Postfix. |
| `dns-records.txt` | DNS de `garea.local` | Registros A, MX y TXT requeridos. |

No se incluyen claves privadas, certificados propios del laboratorio,
contraseñas ni ficheros `.db` generados por `postmap`.

Estos archivos documentan las directivas relevantes, no sustituyen los
ficheros completos instalados por los paquetes. Deben integrarse y validarse
con `postfix check`, `postconf -n` y `doveconf -n`.
