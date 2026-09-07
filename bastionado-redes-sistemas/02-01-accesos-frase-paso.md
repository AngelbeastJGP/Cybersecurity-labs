# 2.1 - Accesos con protección mediante frase de paso

## Resumen

Esta práctica configura el acceso SSH mediante un par de claves protegido con
frase de paso. El objetivo es evitar depender únicamente de contraseñas de
usuario y añadir una segunda protección a la clave privada.

La clave privada queda almacenada en el cliente y nunca se copia al servidor. Al
ser protegida con frase de paso, aunque alguien consiguiera el archivo de clave,
no podría usarla directamente sin conocer esa frase.

## Objetivos

- Generar un par de claves SSH en el equipo cliente.
- Proteger la clave privada con una frase de paso.
- Copiar la clave pública al servidor autorizado.
- Probar el acceso SSH usando la clave.
- Verificar que el servidor permite el inicio de sesión correctamente.

## Máquinas usadas

| Equipo | Sistema | Rol | IP |
| --- | --- | --- | --- |
| R-DEBIAN | Debian 11 | Router entre redes | `10.0.0.1` y `200.0.100.1` |
| PC2 | Debian 11 | Cliente SSH | `200.0.100.102` |
| SRV-ALMA | AlmaLinux 9 | Servidor SSH | `10.0.0.20` |

El router Debian debe estar encendido porque `PC2` y `SRV-ALMA` están en redes
distintas.

## Generación del par de claves

En `PC2` se genera una clave SSH de tipo Ed25519:

```bash
ssh-keygen -t ed25519 -a 100
```

Durante la generación se deja la ruta por defecto:

```text
/home/pc2/.ssh/id_ed25519
```

También se introduce una frase de paso para proteger la clave privada.

Archivos creados:

| Archivo | Uso | Publicable |
| --- | --- | --- |
| `id_ed25519` | Clave privada | No |
| `id_ed25519.pub` | Clave pública | Sí, aunque no es necesario publicarla |

## Copia de la clave pública al servidor

Desde `PC2` se copia la clave pública al usuario autorizado en `SRV-ALMA`:

```bash
ssh-copy-id admin@10.0.0.20
```

Este paso añade la clave pública al archivo `authorized_keys` del usuario remoto.
Para completar la copia se usa la contraseña normal del usuario del servidor una
última vez.

## Prueba de acceso

Después se inicia sesión por SSH:

```bash
ssh admin@10.0.0.20
```

El cliente solicita la frase de paso de la clave privada. Tras introducirla, el
inicio de sesión se completa correctamente en `SRV-ALMA`.

Comprobaciones realizadas:

```bash
whoami
hostname
pwd
```

Resultado observado:

```text
Usuario remoto: admin
Servidor: SRV-alma9
```

## Evidencias

Las capturas de esta práctica se guardan en:

```text
evidencias/02-01-accesos-frase-paso/
```

| Nº | Evidencia | Qué muestra |
| --- | --- | --- |
| 001 | [generación de clave Ed25519](evidencias/02-01-accesos-frase-paso/001-pc2-generacion-clave-ed25519-passphrase.png) | Creación del par de claves en `PC2` con frase de paso. |
| 002 | [copia de clave y acceso SSH](evidencias/02-01-accesos-frase-paso/002-pc2-copia-clave-y-acceso-ssh.png) | `ssh-copy-id` hacia `SRV-ALMA` y conexión SSH posterior. |

## Seguridad

No se publica la clave privada, la frase de paso ni contraseñas de usuarios. Las
capturas muestran el proceso, pero no contienen la frase de paso introducida.

Para un entorno más endurecido, en prácticas posteriores se podría limitar el
acceso por contraseña y permitir únicamente autenticación mediante clave pública.

## Conclusión

El acceso SSH entre `PC2` y `SRV-ALMA` queda configurado mediante clave pública.
La clave privada del cliente está protegida con frase de paso, reduciendo el
riesgo de uso indebido si el archivo de clave llegara a copiarse.

