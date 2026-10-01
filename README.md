# Parcial 1 - Liquidación de la cosecha de una finca cafetera

Programación 3 - Programación funcional en Elixir.

Integrantes: Natalia García Hidalgo, Diego Rincón Álvarez

## Estructura

| Archivo            | Módulo        | Contenido                                                                 |
|--------------------|---------------|---------------------------------------------------------------------------|
| `datos.exs`        | `Datos`       | Solo los datos: `recolectores/0`, `lotes/0`, `pesajes/0`                  |
| `util.exs`         | `Util`        | Entrada/salida (impura) y utilidades de formato y colecciones (puras)     |
| `validacion.exs`   | `Validacion`  | Regla 1: validación de pesajes y lectura del pesaje adicional             |
| `liquidacion.exs`  | `Liquidacion` | Reglas 2 a 5: valor del pesaje, bonificación, alimentación, liquidación   |
| `reportes.exs`     | `Reportes`    | Reportes R1 a R8, desprendible, `ranking/2` y combinación de fincas       |
| `programa.exs`     | `Programa`    | `main/0`: orquesta todo e imprime                                         |

## Cómo compilar y ejecutar

Los módulos de apoyo se compilan con `elixirc` y el programa se ejecuta con `elixir`.
Hay que volver a compilar **cada vez que se cambie `datos.exs`** (o cualquier otro módulo).

```bash
elixirc util.exs datos.exs validacion.exs liquidacion.exs reportes.exs
elixir programa.exs
```

El programa pide primero un pesaje adicional (`recolector;lote;dia;kilos;verdes`, o Enter
para omitir) y, al final de los reportes, el código de un recolector para mostrar su
desprendible de pago.

Ejemplo de entrada para el pesaje adicional: `R04;L3;2;92.5;3`
