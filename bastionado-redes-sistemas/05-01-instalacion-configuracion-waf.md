# 5.1 - Instalacion y configuracion de un WAF

## Resumen

En esta practica se protege el servidor Apache de `SRV-ALMA` mediante
ModSecurity y el conjunto de reglas OWASP Core Rule Set (CRS). El WAF analiza
las peticiones HTTP antes de que lleguen a la aplicacion y bloquea patrones
asociados con ataques web.

Las incidencias se conservan en el registro de auditoria de ModSecurity y se
presentan en un panel HTML generado con GoAccess. Un temporizador de systemd
actualiza el panel automaticamente cada minuto.

```text
Cliente HTTP
    |
    v
Apache 2.4 + ModSecurity + OWASP CRS
    |                  |
    | permitida        | bloqueada (HTTP 403)
    v                  v
Sitio web        Registros de Apache y ModSecurity
                           |
                           v
                  Panel HTML de GoAccess
```

## Objetivos

- Instalar un modulo WAF sobre un servidor Apache existente.
- Activar reglas mantenidas por OWASP para detectar ataques web comunes.
- Comprobar que el trafico legitimo sigue funcionando.
- Simular peticiones XSS y SQL injection dentro del laboratorio.
- Verificar el bloqueo mediante codigos HTTP y registros de auditoria.
- Crear un visor grafico de incidencias.
- Automatizar su actualizacion mediante systemd.

## Escenario

| Equipo | Sistema | Funcion | Direccion |
| --- | --- | --- | --- |
| SRV-ALMA | AlmaLinux 9.8 | Apache, WAF y panel GoAccess | `10.0.0.20` |
| SRV-WINDOWS | Windows Server | Cliente con navegador para consultar el panel | `10.0.0.10` |

Se reutiliza el servicio Apache configurado en practicas anteriores. La prueba
se realiza exclusivamente contra el servidor propio del laboratorio.

## 1. Comprobaciones iniciales

Antes de modificar el servidor se confirma el sistema, la version de Apache y
el estado del servicio:

```bash
hostnamectl
cat /etc/os-release
httpd -v
systemctl is-active httpd
```

El resultado identifica AlmaLinux 9.8, Apache 2.4.62 y el servicio `httpd`
activo. EPEL ya estaba instalado y se habilito CRB para resolver las
dependencias adicionales:

```bash
rpm -q epel-release
dnf config-manager --set-enabled crb
dnf makecache
dnf search modsecurity
dnf list --available "mod_security*"
dnf search goaccess
```

## 2. Instalacion del WAF y del visor

Se instalan el motor WAF, las reglas CRS y el analizador de registros:

```bash
dnf install -y mod_security mod_security_crs goaccess
```

La carga del modulo y la sintaxis de Apache se verifican con:

```bash
httpd -M | grep security
apachectl configtest
```

La salida incluye `security2_module (shared)` y `Syntax OK`. El aviso sobre la
ausencia de un nombre de servidor completo no impide el funcionamiento del
servicio.

## 3. Verificacion de ModSecurity y OWASP CRS

Se revisa el estado del motor:

```bash
grep -Rns "SecRuleEngine" /etc/httpd/conf.d /etc/httpd/modsecurity.d
```

La directiva activa encontrada es:

```apache
SecRuleEngine On
```

Por tanto, ModSecurity esta en modo de bloqueo. No se limita a observar las
peticiones.

Las reglas CRS instaladas se comprueban con:

```bash
ls -l /etc/httpd/modsecurity.d/
ls -l /etc/httpd/modsecurity.d/activated_rules/ | head
```

El directorio `activated_rules` contiene enlaces a las reglas de OWASP CRS. La
auditoria queda configurada para registrar respuestas relevantes:

```bash
grep -RnsE "SecAuditEngine|SecAuditLog " \
  /etc/httpd/conf.d /etc/httpd/modsecurity.d
```

Los valores observados son:

```apache
SecAuditEngine RelevantOnly
SecAuditLog /var/log/httpd/modsec_audit.log
```

Se reinicia Apache para aplicar la configuracion:

```bash
systemctl restart httpd
systemctl is-active httpd
```

## 4. Pruebas de deteccion y bloqueo

Primero se envia una peticion normal para comprobar que el WAF no impide el uso
legitimo del servidor:

```bash
curl -s -o /dev/null \
  -w "Peticion normal: HTTP %{http_code}\n" \
  http://127.0.0.1/
```

El servidor devuelve `HTTP 200`.

Despues se envian dos peticiones controladas con patrones de XSS y SQL
injection:

```bash
curl -s -o /dev/null \
  -w "Prueba XSS: HTTP %{http_code}\n" \
  'http://127.0.0.1/?q=%3Cscript%3Ealert%281%29%3C%2Fscript%3E'

curl -s -o /dev/null \
  -w "Prueba SQLi: HTTP %{http_code}\n" \
  'http://127.0.0.1/?id=1%20OR%201%3D1--'
```

Ambas reciben `HTTP 403`. El funcionamiento normal permanece disponible, pero
el WAF interrumpe las solicitudes que superan el umbral de anomalia de CRS.

Las reglas responsables se consultan en el registro de auditoria:

```bash
grep "Message:" /var/log/httpd/modsec_audit.log | tail -n 10
```

La salida contiene, entre otros, los mensajes `XSS Attack Detected`,
`SQL Injection Attack Detected` e `Inbound Anomaly Score Exceeded`.

## 5. Panel grafico de incidencias

Apache registra todas las solicitudes, incluidas las bloqueadas. Para este
panel se filtran las respuestas `403` y se genera un informe HTML:

```bash
awk '$9 == 403' /var/log/httpd/access_log > /tmp/waf-incidents.log

goaccess /tmp/waf-incidents.log \
  --log-format=COMBINED \
  --html-report-title="Incidencias WAF - SRV-ALMA" \
  --output=/var/www/html/waf-incidents.html

restorecon -v /var/www/html/waf-incidents.html
```

`restorecon` aplica el contexto SELinux previsto para el contenido servido por
Apache. Se valida la publicacion con:

```bash
curl -s -o /dev/null \
  -w "Visor WAF: HTTP %{http_code}\n" \
  http://127.0.0.1/waf-incidents.html
```

El resultado es `HTTP 200`. Desde Windows Server se abre:

```text
http://10.0.0.20/waf-incidents.html
```

El panel muestra cantidad de solicitudes bloqueadas, URL solicitada, fecha,
volumen de trafico y otros datos obtenidos del registro de acceso. El detalle
de reglas, puntuaciones y mensajes permanece en `modsec_audit.log`.

## 6. Actualizacion automatica

El script utilizado se conserva en:

[update-waf-dashboard.sh](configuraciones/05-01-waf/update-waf-dashboard.sh)

En el servidor se instala como:

```text
/usr/local/sbin/update-waf-dashboard.sh
```

Se protege y se restaura su contexto SELinux:

```bash
chmod 750 /usr/local/sbin/update-waf-dashboard.sh
restorecon -v /usr/local/sbin/update-waf-dashboard.sh
```

La unidad [waf-dashboard.service](configuraciones/05-01-waf/waf-dashboard.service)
ejecuta el script mediante Bash. El temporizador
[waf-dashboard.timer](configuraciones/05-01-waf/waf-dashboard.timer) lo activa
cada minuto.

Los archivos se despliegan en `/etc/systemd/system/` y se habilita el
temporizador:

```bash
systemctl daemon-reload
systemctl enable --now waf-dashboard.timer
systemctl status waf-dashboard.timer --no-pager
systemctl list-timers waf-dashboard.timer
```

Para probar el flujo completo se envio una tercera peticion XSS:

```bash
curl -s -o /dev/null \
  -w "Nueva prueba XSS: HTTP %{http_code}\n" \
  'http://127.0.0.1/?search=%3Cimg%20src=x%20onerror=alert%281%29%3E'
```

El WAF devolvio `403`. Tras la siguiente ejecucion del temporizador, el panel
aumento automaticamente de dos a tres incidencias.

## Incidencia encontrada

El script se guardo inicialmente como `update-waf.dashboard.sh`, con un punto
en lugar de un guion. La unidad esperaba
`/usr/local/sbin/update-waf-dashboard.sh`, por lo que systemd mostro:

```text
status=203/EXEC
No such file or directory
```

Se corrigio el nombre del archivo y se configuro una ejecucion explicita con:

```ini
ExecStart=/usr/bin/bash /usr/local/sbin/update-waf-dashboard.sh
```

La prueba posterior termino con `status=0/SUCCESS`. En un servicio
`Type=oneshot`, el estado `inactive (dead)` despues de finalizar es normal; el
temporizador permanece `active (waiting)`.

## Resultados

| Prueba | Resultado |
| --- | --- |
| Peticion HTTP normal | Permitida, `HTTP 200` |
| Patron XSS con etiqueta `script` | Bloqueado, `HTTP 403` |
| Patron SQL injection | Bloqueado, `HTTP 403` |
| Segundo patron XSS | Bloqueado, `HTTP 403` |
| Registro detallado | Disponible en `modsec_audit.log` |
| Panel grafico | Publicado por Apache |
| Actualizacion periodica | Timer activo, cada minuto |

## Evidencias

| Nº | Evidencia | Que demuestra |
| --- | --- | --- |
| 001 | [ModSecurity cargado](evidencias/05-01-waf/001-modsecurity-cargado.png) | Modulo `security2_module` y sintaxis de Apache valida. |
| 002 | [CRS y auditoria](evidencias/05-01-waf/002-crs-y-auditoria.png) | Motor activo, reglas enlazadas y ruta del registro. |
| 003 | [Bloqueos XSS y SQLi](evidencias/05-01-waf/003-bloqueo-xss-sqli.png) | Respuesta 200 legitima, respuestas 403 y mensajes de CRS. |
| 004 | [Panel GoAccess](evidencias/05-01-waf/004-panel-goaccess.png) | Primer visor grafico con dos incidencias. |
| 005 | [Actualizacion automatica](evidencias/05-01-waf/005-panel-actualizacion-automatica.png) | Timer activo, servicio correcto y panel con tres incidencias. |

## Consideraciones de seguridad

- Las pruebas se realizaron unicamente contra infraestructura propia y
  controlada.
- Un codigo `403` en el registro de acceso no identifica por si solo la causa;
  la confirmacion de ModSecurity se obtiene de su registro de auditoria.
- El panel se publica sin autenticacion solo dentro de la red del laboratorio.
  En produccion deberia restringirse por red, autenticacion o VPN.
- ModSecurity y CRS requieren actualizaciones y ajuste de falsos positivos.
- Los registros pueden contener URLs, direcciones IP y parametros sensibles;
  deben protegerse y conservarse durante un periodo definido.
- El WAF complementa, pero no sustituye, la correccion de vulnerabilidades en
  las aplicaciones web.

## Conclusion

Apache queda protegido con ModSecurity en modo de bloqueo y reglas OWASP CRS.
Las pruebas confirman que el trafico normal recibe `HTTP 200`, mientras que los
patrones XSS y SQL injection reciben `HTTP 403` y generan trazabilidad en el
registro de auditoria. GoAccess proporciona el visor grafico solicitado y
systemd mantiene su contenido actualizado automaticamente.
