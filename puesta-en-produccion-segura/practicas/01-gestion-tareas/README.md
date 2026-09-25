# Aplicación web de gestión de tareas

Práctica correspondiente a la actividad 1.13 de **Puesta en producción
segura**. Se desarrollará de forma progresiva y partiendo de conocimientos
básicos.

## Estado

En preparación. Todavía no se ha implementado la aplicación.

## Objetivo funcional

Construir una aplicación web sencilla que permita crear, consultar, actualizar
y eliminar tareas. Cada tarea tendrá título, descripción y estado.

## Tecnologías previstas por la actividad

- JavaScript como lenguaje.
- Node.js y Express para el servidor.
- React para la interfaz.
- MongoDB para almacenar las tareas.
- Jest para pruebas unitarias.
- Selenium para pruebas de interfaz.
- Jenkins para automatizar comprobaciones. Es una de las dos alternativas que
  permite la actividad.

No se sustituirá ninguna de estas tecnologías. Ubuntu Server se utilizará
únicamente como entorno de ejecución dentro de una máquina virtual.

## Entorno que se preparará

### En la máquina virtual

- Ubuntu Server 24.04.4 LTS.
- Git, curl, certificados y GnuPG.
- Node.js 24 LTS y npm.
- MongoDB Community Server 8.0.
- OpenJDK 21.
- Jenkins LTS.
- Navegador para las pruebas automatizadas con Selenium.

### Dependencias del proyecto

- React y React DOM.
- Express.
- Controlador oficial de MongoDB para Node.js.
- Jest.
- Selenium WebDriver.

Las versiones exactas de las dependencias del proyecto quedarán registradas en
`package.json` y en el archivo de bloqueo cuando comience la implementación.

## Método de trabajo

Antes de utilizar una tecnología se explicarán su finalidad, funcionamiento y
relación con el resto del sistema. La implementación se dividirá en pasos
pequeños y verificables:

1. Conceptos básicos de aplicaciones web.
2. Preparación y comprobación del entorno.
3. Fundamentos mínimos de JavaScript.
4. Primer servidor con Node.js y Express.
5. Datos y operaciones básicas sin base de datos.
6. Persistencia con MongoDB.
7. Interfaz con React.
8. Pruebas unitarias, integración, sistema y aceptación.
9. Regresión, seguridad, usabilidad y compatibilidad.
10. Pipeline CI/CD y documentación final.

## Criterios de publicación

- No se publicarán secretos ni datos personales.
- Cada cambio incluirá una explicación y una comprobación.
- Las pruebas y sus resultados se conservarán como parte de la práctica.
- No se marcará una fase como completada hasta haberla ejecutado y verificado.
