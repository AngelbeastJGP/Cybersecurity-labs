# 2.2 - Acceso mediante verificación de equipo cliente

## Resumen

Esta práctica configura el acceso SSH mediante clave pública sin frase de paso.
El servidor permite el acceso porque el equipo cliente posee una clave privada
cuya clave pública ha sido autorizada previamente.

La diferencia frente a la práctica 2.1 es que la clave privada no está protegida
con passphrase. Esto hace el acceso más cómodo, pero también más sensible: si se
copia la clave privada del cliente, se podría acceder al servidor sin conocer una
frase adicional.

## Objetivos

- Crear un usuario de prueba sin privilegios en el servidor.
- Generar un par de claves SSH sin frase de paso.
- Copiar la clave pública al servidor.
- Verificar acceso SSH desde el cliente sin introducir contraseña ni passphrase.
- Documentar el riesgo de usar este método con usuarios privilegiados.

## Máquinas usadas

| Equipo | Sistema | Rol | IP |
| --- | --- | --- | --- |
| R-DEBIAN | Debian 11 | Router entre redes | `10.0.0.1` y `200.0.100.1` |
| PC2 | Debian 11 | Cliente SSH | `200.0.100.102` |
| SRV-ALMA | AlmaLinux 9 | Servidor SSH | `10.0.0.20` |

## Usuario de prueba

En `SRV-ALMA` se crea un usuario específico para la práctica:

```bash
useradd -m sshprueba
passwd sshprueba
```

Se evita usar un usuario con privilegios administrativos porque la clave privada
no tendrá frase de paso.

## Generación de clave sin passphrase

En `PC2` se genera una clave nueva, separada de la utilizada en la práctica 2.1:

```bash
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519_sin_passphrase
```

Cuando se solicita la frase de paso, se deja vacía pulsando Enter.

Archivos generados:

| Archivo | Uso | Publicable |
| --- | --- | --- |
| `id_ed25519_sin_passphrase` | Clave privada sin frase de paso | No |
| `id_ed25519_sin_passphrase.pub` | Clave pública | Sí, aunque no es necesario publicarla |

## Copia de la clave pública

La clave pública se copia al servidor:

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_sin_passphrase.pub sshprueba@10.0.0.20
```

Este paso añade la clave pública al archivo `authorized_keys` del usuario
`sshprueba`.

## Prueba de acceso

Desde `PC2` se inicia sesión usando la clave privada:

```bash
ssh -i ~/.ssh/id_ed25519_sin_passphrase sshprueba@10.0.0.20
```

El acceso se completa sin pedir contraseña del usuario ni frase de paso. Dentro
del servidor se verifica la identidad y ubicación:

```bash
whoami
hostname
pwd
```

Resultado observado:

```text
sshprueba
SRV-alma9
/home/sshprueba
```

## Evidencias

Las capturas se guardan en:

```text
evidencias/02-02-verificacion-equipo-cliente/
```

| Nº | Evidencia | Qué muestra |
| --- | --- | --- |
| 001 | [creación del usuario](evidencias/02-02-verificacion-equipo-cliente/001-srv-alma-creacion-usuario-sshprueba.png) | Alta del usuario `sshprueba` en `SRV-ALMA`. |
| 002 | [generación de clave sin passphrase](evidencias/02-02-verificacion-equipo-cliente/002-pc2-generacion-clave-sin-passphrase.png) | Creación del par de claves en `PC2` dejando la passphrase vacía. |
| 003 | [copia de clave pública](evidencias/02-02-verificacion-equipo-cliente/003-pc2-copia-clave-publica.png) | Instalación de la clave pública en el servidor. |
| 004 | [acceso SSH verificado](evidencias/02-02-verificacion-equipo-cliente/004-pc2-acceso-ssh-sin-passphrase.png) | Login correcto y comprobación con `whoami`, `hostname` y `pwd`. |

## Seguridad

Este método no debe aplicarse a usuarios con privilegios elevados. La clave
privada no tiene passphrase, por lo que debe protegerse especialmente en el
equipo cliente.

En un entorno real se recomienda combinar este tipo de acceso con controles
adicionales: permisos estrictos sobre `~/.ssh`, restricciones por usuario,
origen de conexión, firewall y auditoría de accesos.

## Conclusión

El servidor `SRV-ALMA` permite acceso SSH al usuario `sshprueba` desde `PC2`
mediante clave pública. La autenticación funciona sin contraseña porque el
cliente dispone de la clave privada autorizada.

