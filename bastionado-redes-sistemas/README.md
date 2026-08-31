# Bastionado de redes y sistemas

Laboratorios prácticos orientados a la construcción y securización progresiva de
infraestructuras de red y sistemas.

## Prácticas

| Nº | Práctica | Estado |
| --- | --- | --- |
| 01 | [Construcción de una infraestructura segmentada](01-construccion-infraestructura-segmentada.md) | Completada |

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
