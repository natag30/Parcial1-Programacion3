# Parcial 1 - Programación 3
# Integrantes: Natalia García Hidalgo, Diego Rincón Álvarez

defmodule Reportes do
  @moduledoc """
    Módulo que contiene funciones para generar reportes de la liquidación de recolectores.
  """

  @meta_diaria 400
  @minimo_pesajes_calidad 3

  @doc """
  Función que genera el reporte de Pesajes rechazados con su motivo, y cantidad de rechazos por cada motivo
  """
  def reporte_1(invalidos) do
    filas =
      for {p, motivo} <- invalidos do
        "#{Util.texto(p.recolector)} | #{Util.texto(p.lote)} | día #{Util.texto(p.dia)} | " <>
          "#{Util.texto(p.kilos)} kg | #{Util.texto(p.verdes)} % -> #{motivo}"
      end

    filas = if filas == [], do: ["No hay pesajes rechazados."], else: filas

    conteos =
      for motivo <- Validacion.motivos() do
        cantidad = Enum.count(invalidos, fn {_pesaje, m} -> m == motivo end)
        "#{motivo}: #{cantidad}"
      end

    Enum.join(["R1. Pesajes rechazados"] ++ filas ++ ["", "Rechazos por motivo"] ++ conteos, "\n")
  end

  @doc """
  Función que genera el reporte de Kilos por lote y rendimiento en kilos por hectárea, ordenados de mayor a
  menor rendimiento.
  Un lote sin pesajes válidos aparece con 0 kg.
  """
  def reporte_2(validos, lotes) do
    kilos_por_lote =
      Enum.reduce(validos, %{}, fn p, acc ->
        Map.update(acc, p.lote, p.kilos, fn kilos -> kilos + p.kilos end)
      end)

    filas =
      lotes
      |> Enum.map(fn lote ->
        kilos = Map.get(kilos_por_lote, lote.id, 0)
        {lote, kilos, rendimiento(kilos, lote.hectareas)}
      end)
      |> Enum.sort_by(fn {_lote, _kilos, rendimiento} -> rendimiento end, :desc)
      |> Enum.map(fn {lote, kilos, rendimiento} ->
        "#{lote.nombre} | #{Util.formatear_numero(kilos)} kg | #{lote.hectareas} ha | " <>
          "#{Util.formatear_decimal(rendimiento)} kg/ha"
      end)

    Enum.join(["R2. Kilos por lote" | filas], "\n")
  end

  @doc """
  Función que calcula el rendimiento en kilos por hectárea dado los kilos y las hectáreas.
  Retorna 0 si las hectáreas son 0.
  """
  defp rendimiento(kilos, hectareas) when hectareas > 0, do: kilos / hectareas
  defp rendimiento(_kilos, _hectareas), do: 0.0

  @doc """
  Función que genera el reporte de Kilos por día y si se cumplió la meta diaria de kilos.
  """
  def kilos_finca_por_dia(validos) do
    kilos_dia = Liquidacion.kilos_por_dia(validos)

    for dia <- Validacion.dias_cosecha(), into: %{} do
      {dia, Map.get(kilos_dia, dia, 0)}
    end
  end

  @doc """
  Función que genera el reporte de Kilos de la finca en cada uno de los 6 días e indicación
  de si se cumplió la meta diaria
  """
  def reporte_3(validos) do
    kilos_dia = kilos_finca_por_dia(validos)

    filas =
      for dia <- Validacion.dias_cosecha() do
        kilos = Map.fetch!(kilos_dia, dia)
        resultado = if kilos >= @meta_diaria, do: "cumplió la meta", else: "no cumplió la meta"
        "Día #{dia}: #{Util.formatear_numero(kilos)} kg -> #{resultado}"
      end

    cumplimientos = for {_dia, kilos} <- kilos_dia, do: kilos >= @meta_diaria

    todos = if Enum.all?(cumplimientos, & &1), do: "Sí", else: "No"
    alguno = if Enum.any?(cumplimientos, & &1), do: "Sí", else: "No"

    Enum.join(
      ["R3. Kilos por día (meta: #{@meta_diaria} kg)"] ++
        filas ++
        [
          "¿Se cumplió la meta todos los días? #{todos}",
          "¿Se cumplió la meta al menos un día? #{alguno}"
        ],
      "\n"
    )
  end

  @doc """
  Función que genera el reporte de Liquidación de todos los recolectores, numerada y ordenada por
  neto de mayor a menor, con kilos, suma de pesajes, bonificaciones, alimentación y neto.
  """
  def reporte_4(liquidaciones) do
    filas =
      liquidaciones
      |> Enum.sort_by(fn l -> l.neto end, :desc)
      |> Enum.with_index(1)
      |> Enum.map(fn {l, posicion} ->
        "#{posicion}. | #{l.nombre} | #{Util.formatear_numero(l.kilos)} kg | " <>
          "#{Util.formatear_moneda(l.bruto)} | #{Util.formatear_moneda(l.bonificaciones)} | " <>
          "#{Util.formatear_moneda(l.alimentacion)} | #{Util.formatear_moneda(l.neto)}"
      end)

    Enum.join(
      [
        "R4. Liquidación de la semana",
        "# | Recolector | Kilos | Pesajes | Bonificaciones | Alimentación | Neto"
      ] ++ filas,
      "\n"
    )
  end

  @doc """
  Función que genera el reporte de Mejor recolector de cada día: para cada uno de los 6 días, el recolector
  que más kilos recogió ese día y sus kilos.
  Si hay empate, aparecen todos los empatados.
  Un día sin pesajes válidos se indica como tal. Al final, el recolector que fue el mejor en más días, con
  la cantidad de días
  """
  def reporte_5(validos, recolectores) do
    kilos_rd = Liquidacion.kilos_por_recolector_dia(validos)

    mejores =
      for dia <- Validacion.dias_cosecha() do
        {dia, mejores_del_dia(dia, kilos_rd, recolectores)}
      end

    filas =
      for {dia, {ganadores, kilos}} <- mejores do
        if ganadores == [] do
          "Día #{dia}: sin pesajes"
        else
          "Día #{dia}: #{nombres(ganadores)} (#{Util.formatear_numero(kilos)} kg)"
        end
      end

    Enum.join(
      ["R5. Mejor recolector de cada día"] ++ filas ++ [linea_mas_dias(mejores, recolectores)],
      "\n"
    )
  end

  @doc """
  Función que genera el reporte de Mejor recolector de cada día: para cada uno de los 6 días, el recolector
  que más kilos recogió ese día y sus kilos.
  """
  defp mejores_del_dia(dia, kilos_rd, recolectores) do
    candidatos =
      recolectores
      |> Enum.map(fn r -> {r, kilos_rd |> Map.get(r.codigo, %{}) |> Map.get(dia)} end)
      |> Enum.reject(fn {_r, kilos} -> is_nil(kilos) end)

    if candidatos == [] do
      {[], 0}
    else
      maximo = candidatos |> Enum.map(fn {_r, kilos} -> kilos end) |> Enum.max()
      {for({r, kilos} <- candidatos, kilos == maximo, do: r), maximo}
    end
  end

  @doc """
  Funcion que genera el reporte del recolector con más días como mejor recolector, con la cantidad de días.
  """
  defp linea_mas_dias(mejores, recolectores) do
    codigos = for {_dia, {ganadores, _kilos}} <- mejores, r <- ganadores, do: r.codigo
    conteo = Enum.frequencies(codigos)

    if conteo == %{} do
      "Más días como mejor recolector: sin pesajes válidos"
    else
      maximo = conteo |> Map.values() |> Enum.max()
      lideres = Enum.filter(recolectores, fn r -> Map.get(conteo, r.codigo) == maximo end)
      unidad = if maximo == 1, do: "día", else: "días"
      "Más días como mejor recolector: #{nombres(lideres)} (#{maximo} #{unidad})"
    end
  end

  @doc """
  Funcion que trae el nombre de los recolectores en una lista y los une con comas.
  """
  defp nombres(recolectores),
    do: recolectores |> Enum.map(fn r -> r.nombre end) |> Enum.join(", ")

  @doc """
   Función que genera el reporte del recolector con mejor calidad. El de menor porcentaje de verdes
  ponderado por kilos, entre quienes tienen al menos 3 pesajes válidos.
  """
  def reporte_6(validos, recolectores) do
    por_recolector = Enum.group_by(validos, fn p -> p.recolector end)

    candidatos =
      recolectores
      |> Enum.map(fn r -> {r, Map.get(por_recolector, r.codigo, [])} end)
      |> Enum.filter(fn {_r, pesajes} -> length(pesajes) >= @minimo_pesajes_calidad end)
      |> Enum.map(fn {r, pesajes} -> {r, porcentaje_ponderado(pesajes)} end)

    titulo = "R6. Mejor calidad (mínimo #{@minimo_pesajes_calidad} pesajes válidos)"

    if candidatos == [] do
      titulo <> "\nNingún recolector tiene al menos #{@minimo_pesajes_calidad} pesajes válidos"
    else
      {recolector, porcentaje} = Enum.min_by(candidatos, fn {_r, pct} -> pct end)

      titulo <>
        "\n#{recolector.nombre}, con #{Util.formatear_decimal(porcentaje)} % de verdes ponderado por kilos"
    end
  end

  @doc """
  Función que calcula el porcentaje de verdes ponderado por kilos para una lista de pesajes.
  """
  def porcentaje_ponderado(pesajes) do
    suma_ponderada = pesajes |> Enum.map(fn p -> p.verdes * p.kilos end) |> Enum.sum()
    suma_kilos = pesajes |> Enum.map(fn p -> p.kilos end) |> Enum.sum()
    suma_ponderada / suma_kilos
  end

  @doc """
  Función que genera el reporte de Totales de la semana: total a pagar, kilos válidos y
  costo promedio por kilo.
  """
  def reporte_7(liquidaciones) do
    total = liquidaciones |> Enum.map(fn l -> l.neto end) |> Enum.sum()
    kilos = liquidaciones |> Enum.map(fn l -> l.kilos end) |> Enum.sum()
    promedio = if kilos > 0, do: total / kilos, else: 0

    Enum.join(
      [
        "R7. Totales de la semana",
        "Total a pagar: #{Util.formatear_moneda(total)}",
        "Kilos válidos: #{Util.formatear_numero(kilos)} kg",
        "Costo promedio por kilo: #{Util.formatear_moneda(promedio)}"
      ],
      "\n"
    )
  end

  @doc """
  Función que genera el reporte de Recolectores que recogieron café en todos los lotes.
  Si no hay ninguno aparece un mensaje indicando que no hay recolectores que cumplan la condición.
  """
  def reporte_8(validos, recolectores, lotes) do
    ids_lotes = Enum.map(lotes, fn lote -> lote.id end)
    lotes_por_recolector = Enum.group_by(validos, fn p -> p.recolector end, fn p -> p.lote end)

    en_todos =
      Enum.filter(recolectores, fn r ->
        trabajados = Map.get(lotes_por_recolector, r.codigo, [])
        Enum.all?(ids_lotes, fn id -> id in trabajados end)
      end)

    cuerpo =
      if en_todos == [] do
        ["Ningún recolector trabajó en todos los lotes"]
      else
        Enum.map(en_todos, fn r -> r.nombre end)
      end

    Enum.join(["R8. Recolectores que trabajaron en todos los lotes" | cuerpo], "\n")
  end

  @doc """
  Función que genera el desprendible de pago de un recolector dado su código.
  Si el código no corresponde a ningún recolector, se indica que no existe.
  """
  def desprendible(liquidaciones, codigo) do
    case Enum.find(liquidaciones, fn l -> l.codigo == codigo end) do
      nil ->
        "No existe un recolector con el código #{codigo}."

      l ->
        dias =
          for d <- l.detalle do
            "Día #{d.dia}: #{Util.formatear_numero(d.kilos)} kg | pesajes #{Util.formatear_moneda(d.valor)} | " <>
              "bonificación #{Util.formatear_moneda(d.bonificacion)}"
          end

        Enum.join(
          ["Desprendible de pago - #{l.nombre} (#{l.codigo})"] ++
            dias ++
            [
              "Suma de pesajes: #{Util.formatear_moneda(l.bruto)}",
              "Bonificaciones: #{Util.formatear_moneda(l.bonificaciones)}",
              linea_alimentacion(l),
              "Neto a pagar: #{Util.formatear_moneda(l.neto)}"
            ],
          "\n"
        )
    end
  end

  @doc """
  Funcion que crea la línea de alimentación para el desprendible, dependiendo si aplica o no.
  """
  defp linea_alimentacion(%{come: true} = l) do
    unidad = if l.dias_trabajados == 1, do: "día", else: "días"
    "Alimentación (#{l.dias_trabajados} #{unidad}): -#{Util.formatear_moneda(l.alimentacion)}"
  end

  defp linea_alimentacion(_l), do: "Alimentación (no aplica): #{Util.formatear_moneda(0)}"

  @doc """
  Función que ordena las liquidaciones según las opciones recibidas.

  ## Opciones (keyword list)
    * `:campo`  - `:neto` (por defecto), `:kilos` o `:bruto`
    * `:orden`  - `:desc` (por defecto) o `:asc`
    * `:limite` - entero positivo; por defecto, todos los recolectores

  Si una opción se repite (`campo: :kilos, campo: :neto`), `Keyword.get/3`
  devuelve el PRIMER valor.
  """
  def ranking(liquidaciones, opciones) do
    campo = Keyword.get(opciones, :campo, :neto)
    orden = Keyword.get(opciones, :orden, :desc)
    limite = Keyword.get(opciones, :limite)

    ordenadas = Enum.sort_by(liquidaciones, fn l -> Map.get(l, campo) end, orden)

    if limite, do: Enum.take(ordenadas, limite), else: ordenadas
  end

  @doc """
  Función que genera el texto para mostrar el ranking de recolectores.
  """
  def texto_ranking(ranking) do
    ranking
    |> Enum.with_index(1)
    |> Enum.map(fn {l, posicion} ->
      "#{posicion}. #{l.nombre} | #{Util.formatear_numero(l.kilos)} kg | " <>
        "bruto #{Util.formatear_moneda(l.bruto)} | neto #{Util.formatear_moneda(l.neto)}"
    end)
    |> Enum.join("\n")
  end

  @doc """
  Función que combina los kilos recolectados por día con los de la finca vecina.
  """
  def combinar_kilos_por_dia(propios, vecina) do
    Map.merge(propios, vecina, fn _dia, kilos_propios, kilos_vecina ->
      kilos_propios + kilos_vecina
    end)
  end

  @doc """
  Función que genera el texto con la producción de kilos por día.
  """
  def texto_kilos_por_dia(kilos_por_dia) do
    kilos_por_dia
    |> Enum.sort()
    |> Enum.map(fn {dia, kilos} -> "Día #{dia}: #{Util.formatear_numero(kilos)} kg" end)
    |> Enum.join("\n")
  end
end
