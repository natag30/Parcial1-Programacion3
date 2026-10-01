# Parcial 1 - Programación 3
# Integrantes: Natalia García Hidalgo, Diego Rincón Álvarez

defmodule Programa do
  @moduledoc """
  Modulo principal del programa de liquidación de recolectores de una finca caetera
  """

  @pregunta_pesaje "Ingrese un pesaje adicional (recolector;lote;dia;kilos;verdes) o Enter para omitir: "
  @pregunta_codigo "Ingrese el código del recolector para ver su desprendible: "
  @finca_vecina %{1 => 520.5, 2 => 610, 3 => 480, 5 => 700, 7 => 300}

  @doc """
  Función principal del programa que ejecuta la lógica de liquidación de recolectores.
  """
  def main do
    recolectores = Datos.recolectores()
    lotes = Datos.lotes()
    recolectores_por_codigo = Util.indexar_por(recolectores, :codigo)
    lotes_por_id = Util.indexar_por(lotes, :id)

    {validos, invalidos} =
      Validacion.separar_pesajes(Datos.pesajes(), recolectores_por_codigo, lotes_por_id)

    validos = agregar_pesaje_adicional(validos, recolectores_por_codigo, lotes_por_id)
    Util.imprimir("")

    liquidaciones = Liquidacion.liquidar_todos(recolectores, validos)

    [
      Reportes.reporte_1(invalidos),
      Reportes.reporte_2(validos, lotes),
      Reportes.reporte_3(validos),
      Reportes.reporte_4(liquidaciones),
      Reportes.reporte_5(validos, recolectores),
      Reportes.reporte_6(validos, recolectores),
      Reportes.reporte_7(liquidaciones),
      Reportes.reporte_8(validos, recolectores, lotes)
    ]
    |> Enum.each(fn reporte -> Util.imprimir(reporte <> "\n") end)

    mostrar_rankings(liquidaciones)

    mostrar_combinacion(validos)

    codigo = Util.leer_linea(@pregunta_codigo)
    Util.imprimir(Reportes.desprendible(liquidaciones, codigo))

    :ok
  end

  @doc """
  Función que agrega un pesaje adicional a la lista de pesajes válidos si el
  usuario lo ingresa correctamente.
  """
  defp agregar_pesaje_adicional(validos, recolectores, lotes) do
    linea = Util.leer_linea(@pregunta_pesaje)

    if linea == "" do
      Util.imprimir("No se agregó ningún pesaje adicional.")
      validos
    else
      with {:ok, pesaje} <- Validacion.parsear_pesaje(linea),
           {:ok, pesaje} <- Validacion.validar_pesaje(pesaje, recolectores, lotes) do
        Util.imprimir(
          "Pesaje agregado: #{pesaje.recolector} en #{pesaje.lote}, día #{pesaje.dia}, " <>
            "#{pesaje.kilos} kg, #{pesaje.verdes} % de verdes."
        )

        validos ++ [pesaje]
      else
        {:error, motivo} ->
          Util.imprimir("Pesaje rechazado: #{motivo}")
          validos
      end
    end
  end

  @doc """
  Función que muestra los rankings de recolectores según diferentes criterios.
  """
  defp mostrar_rankings(liquidaciones) do
    Util.imprimir("C.1. Ranking de recolectores (keyword list)\n")

    llamadas = [
      {"Reportes.ranking(liquidaciones, [])", []},
      {"Reportes.ranking(liquidaciones, campo: :kilos, limite: 3)", [campo: :kilos, limite: 3]},
      {"Reportes.ranking(liquidaciones, orden: :asc, campo: :bruto)",
       [orden: :asc, campo: :bruto]},
      {"Reportes.ranking(liquidaciones, campo: :kilos, campo: :neto)",
       [campo: :kilos, campo: :neto]}
    ]

    Enum.each(llamadas, fn {etiqueta, opciones} ->
      Util.imprimir(etiqueta)
      Util.imprimir(Reportes.texto_ranking(Reportes.ranking(liquidaciones, opciones)) <> "\n")
    end)
  end

  @doc """
  Función que muestra la producción combinada con la finca vecina.
  """
  defp mostrar_combinacion(validos) do
    propios = Reportes.kilos_finca_por_dia(validos)
    combinado = Reportes.combinar_kilos_por_dia(propios, @finca_vecina)

    Util.imprimir("C.2. Producción combinada con la finca vecina (Map.merge/3)")
    Util.imprimir(Reportes.texto_kilos_por_dia(combinado) <> "\n")
  end
end

Programa.main()
