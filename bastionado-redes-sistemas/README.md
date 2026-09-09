# Bastionado de redes y sistemas

Laboratorios prácticos orientados a la construcción y securización progresiva de
infraestructuras de red y sistemas.

## Prácticas

| Nº | Práctica | Estado |
| --- | --- | --- |
| 01 | [Construcción de una infraestructura segmentada](01-construccion-infraestructura-segmentada.md) | Completada |
| 2.1 | [Accesos con protección mediante frase de paso](02-01-accesos-frase-paso.md) | Completada |
| 2.2 | [Acceso mediante verificación de equipo cliente](02-02-verificacion-equipo-cliente.md) | Completada |
| 2.3 | [Acceso mediante doble factor de autenticación](02-03-doble-factor-autenticacion.md) | Completada |
| 3.1 | [Creación de una infraestructura de clave pública (PKI)](03-01-infraestructura-clave-publica.md) | Completada |

## Escenario base

La primera práctica construye una infraestructura con:

- Red de clientes: `200.0.100.0/24`
- Red de servidores: `10.0.0.0/24`
- Router Debian como puerta de enlace, NAT y DHCP.
- Windows Server como controlador de dominio y DNS de Active Directory.
- AlmaLinux como servidor de servicios internos: SSH, HTTP, Webmin y OpenLDAP.
- Clientes Windows integrados en dominio.
- Cliente Debian integrado con OpenLDAP.

## Evidencias

Las capturas de cada práctica se guardan en carpetas separadas dentro de:

```text
evidencias/
```

Para esta práctica:

- [Evidencias de la infraestructura segmentada](evidencias/01-infraestructura-segmentada/)
- [Evidencias de accesos con frase de paso](evidencias/02-01-accesos-frase-paso/)
- [Evidencias de verificación de equipo cliente](evidencias/02-02-verificacion-equipo-cliente/)
- [Evidencias de doble factor de autenticación](evidencias/02-03-doble-factor-autenticacion/)
- [Evidencias de infraestructura de clave pública](evidencias/03-01-infraestructura-clave-publica/)
