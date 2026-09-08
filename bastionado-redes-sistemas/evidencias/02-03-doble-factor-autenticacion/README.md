# Evidencias - 2.3 acceso mediante doble factor de autenticación

Esta carpeta contiene las capturas de la práctica:

[2.3 - Acceso mediante doble factor de autenticación](../../02-03-doble-factor-autenticacion.md)

## Índice de capturas

| Nº | Archivo | Qué muestra |
| --- | --- | --- |
| 001 | [srv-alma-pam-sshd-inicial](001-srv-alma-pam-sshd-inicial.png) | Configuración inicial de PAM para SSH. |
| 002 | [srv-alma-sshd-config-2fa](002-srv-alma-sshd-config-2fa.png) | Configuración de SSH para PAM y métodos interactivos. |
| 003 | [srv-alma-grep-configuracion-ssh-2fa](003-srv-alma-grep-configuracion-ssh-2fa.png) | Revisión de directivas relevantes. |
| 004 | [srv-alma-redhat-conf-bloqueo-challenge](004-srv-alma-redhat-conf-bloqueo-challenge.png) | Archivo `50-redhat.conf` que bloqueaba challenge-response. |
| 005 | [pc2-error-totp-keyboard-interactive](005-pc2-error-totp-keyboard-interactive.png) | Error de autenticación TOTP durante el diagnóstico. |
| 006 | [srv-alma-pam-sshd-solo-totp](006-srv-alma-pam-sshd-solo-totp.png) | PAM ajustado para pedir solo TOTP tras clave pública. |
| 007 | [srv-alma-permisos-google-authenticator](007-srv-alma-permisos-google-authenticator.png) | Ajuste de permisos y contexto del archivo TOTP. |
| 008 | [pc2-login-totp-correcto](008-pc2-login-totp-correcto.png) | Acceso final correcto con código TOTP. |

No se incluyen capturas del QR, clave secreta TOTP, códigos de emergencia,
contraseñas ni claves privadas.

