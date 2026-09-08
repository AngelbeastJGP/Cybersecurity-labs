# 2.3 - Acceso mediante doble factor de autenticación

## Resumen

Esta práctica añade doble factor de autenticación al acceso SSH. El usuario debe
presentar dos factores:

- Algo que tiene: la clave privada SSH del equipo cliente.
- Algo que genera: un código TOTP temporal en una aplicación autenticadora.

El laboratorio se realiza sobre el servicio SSH de `SRV-ALMA` y el usuario de
prueba `sshprueba`. No se aplica al inicio de sesión gráfico ni a Windows para
mantener el alcance controlado y evitar modificar servicios de autenticación no
necesarios para esta práctica.

## Objetivos

- Instalar y configurar autenticación TOTP en Linux.
- Asociar un secreto TOTP al usuario `sshprueba`.
- Integrar Google Authenticator con PAM.
- Configurar SSH para exigir clave pública y código TOTP.
- Diagnosticar el bloqueo producido por SELinux en modo Enforcing.
- Validar el acceso con SELinux en modo Permissive.

## Máquinas usadas

| Equipo | Sistema | Rol | IP |
| --- | --- | --- | --- |
| R-DEBIAN | Debian 11 | Router entre redes | `10.0.0.1` y `200.0.100.1` |
| PC2 | Debian 11 | Cliente SSH | `200.0.100.102` |
| SRV-ALMA | AlmaLinux 9 | Servidor SSH y PAM/TOTP | `10.0.0.20` |

## Preparación del usuario

La práctica usa el usuario sin privilegios creado en la práctica 2.2:

```text
sshprueba
```

Se utiliza este usuario porque no conviene experimentar con doble factor sobre
cuentas administrativas hasta validar bien el flujo de acceso.

## Configuración TOTP

En `SRV-ALMA` se instala el módulo de Google Authenticator para PAM y se ejecuta
la configuración para el usuario `sshprueba`.

Durante la configuración se genera un secreto TOTP que se añade a una aplicación
autenticadora móvil. No se documenta ni se publica el QR, la clave secreta ni los
códigos de emergencia.

Respuestas usadas durante la configuración:

```text
Tokens basados en tiempo: sí
Actualizar archivo .google_authenticator: sí
Evitar reutilización de códigos: se probó durante el diagnóstico
Ampliar ventana de tiempo: no
Limitar intentos: sí
```

## Integración con PAM

En `/etc/pam.d/sshd` se añade el módulo:

```text
auth required pam_google_authenticator.so
```

Para evitar que PAM pidiera además la contraseña del usuario, se comentó la
línea de autenticación por contraseña dentro de la sección `auth`:

```text
#auth       substack     password-auth
```

Con esto el flujo queda centrado en clave pública SSH y código TOTP.

## Configuración de SSH

En la configuración de SSH se habilitan PAM, autenticación por clave pública y
autenticación interactiva:

```text
UsePAM yes
PubkeyAuthentication yes
KbdInteractiveAuthentication yes
ChallengeResponseAuthentication yes
AuthenticationMethods publickey,keyboard-interactive:pam
```

Durante el proceso se detectó que AlmaLinux incluye configuración adicional en:

```text
/etc/ssh/sshd_config.d/50-redhat.conf
```

Este archivo tenía `ChallengeResponseAuthentication no`, lo que impedía que SSH
aceptara `keyboard-interactive` como método válido.

## Incidencia con SELinux

Con SELinux en modo Enforcing, el inicio de sesión pedía el código TOTP pero no
terminaba correctamente. En los logs de `sshd` aparecía:

```text
Failed to update secret file "/home/sshprueba/.google_authenticator": Permission denied
```

Se revisaron propietario, permisos y contexto del archivo `.google_authenticator`.
El acceso funcionó al pasar SELinux temporalmente a modo Permissive:

```bash
setenforce 0
```

Conclusión de la incidencia:

```text
El doble factor funciona correctamente con clave pública + TOTP.
SELinux Enforcing bloquea la gestión del archivo .google_authenticator.
Queda pendiente crear una política SELinux específica para mantener Enforcing.
```

## Prueba de acceso

Desde `PC2` se prueba el acceso:

```bash
ssh -i ~/.ssh/id_ed25519_sin_passphrase sshprueba@10.0.0.20
```

El servidor solicita:

```text
Verification code:
```

Tras introducir el código TOTP válido, el acceso se completa correctamente.

## Evidencias

Las capturas se guardan en:

```text
evidencias/02-03-doble-factor-autenticacion/
```

| Nº | Evidencia | Qué muestra |
| --- | --- | --- |
| 001 | [PAM sshd inicial](evidencias/02-03-doble-factor-autenticacion/001-srv-alma-pam-sshd-inicial.png) | Archivo `/etc/pam.d/sshd` antes del ajuste final. |
| 002 | [configuración SSH 2FA](evidencias/02-03-doble-factor-autenticacion/002-srv-alma-sshd-config-2fa.png) | Opciones de SSH relacionadas con PAM e interacción. |
| 003 | [grep configuración SSH](evidencias/02-03-doble-factor-autenticacion/003-srv-alma-grep-configuracion-ssh-2fa.png) | Revisión de directivas activas en `sshd_config`. |
| 004 | [bloqueo en 50-redhat.conf](evidencias/02-03-doble-factor-autenticacion/004-srv-alma-redhat-conf-bloqueo-challenge.png) | Directiva que desactivaba `ChallengeResponseAuthentication`. |
| 005 | [error de TOTP](evidencias/02-03-doble-factor-autenticacion/005-pc2-error-totp-keyboard-interactive.png) | SSH pide código TOTP pero falla la autenticación. |
| 006 | [PAM solo TOTP](evidencias/02-03-doble-factor-autenticacion/006-srv-alma-pam-sshd-solo-totp.png) | Ajuste para evitar petición adicional de contraseña. |
| 007 | [permisos del archivo TOTP](evidencias/02-03-doble-factor-autenticacion/007-srv-alma-permisos-google-authenticator.png) | Revisión de propietario, permisos y contexto. |
| 008 | [login correcto con TOTP](evidencias/02-03-doble-factor-autenticacion/008-pc2-login-totp-correcto.png) | Acceso correcto desde `PC2` tras introducir el código TOTP. |

## Seguridad

No se publican el QR, la clave secreta TOTP, códigos de emergencia, contraseñas
ni claves privadas. Las capturas seleccionadas documentan la configuración y el
resultado sin exponer secretos.

En un entorno real no se debería dejar SELinux en modo Permissive de forma
permanente. El siguiente paso de hardening sería crear o ajustar una política
SELinux que permita el funcionamiento del módulo manteniendo Enforcing.

## Conclusión

El acceso SSH a `SRV-ALMA` queda validado con doble factor: clave pública SSH y
código TOTP. La práctica también deja documentada una incidencia real de
integración con SELinux, que se resolvió para el laboratorio usando modo
Permissive y queda pendiente para una fase posterior de endurecimiento.

