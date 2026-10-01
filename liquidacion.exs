# Parcial 1 - Programación 3
# Integrantes: Natalia García Hidalgo, Diego Rincón Álvarez

defmodule Liquidacion do
  @moduledoc """
  Módulo para la liquidación de recolectores.
  """

  @tarifa_base 1_000
  @kilos_bonificacion 120
  @bonificacion_diaria 8_000
  @descuento_alimentacion 12_000

  @doc """
  Función que calcula el valor de un pesaje según la cantidad de kilos y el porcentaje de verdes.
  """
  def valor_pesaje(%{kilos: kilos, verdes: verdes}) do
    kilos * @tarifa_base * factor_calidad(verdes) / 100
  end

  @doc """
  Función que calcula el porcentaje ponderado de verdes en una lista de pesajes.
  Retorna 105 si el porcentaje de verdes es menor o igual a 2, 100 si es menor o igual a 5,
  90 si es menor o igual a 10, y 70 si es mayor a 10.
  """
  defp factor_calidad(verdes) when verdes <= 2, do: 105
  defp factor_calidad(verdes) when verdes <= 5, do: 100
  defp factor_calidad(verdes) when verdes <= 10, do: 90
  defp factor_calidad(_verdes), do: 70

  @doc """
  Función que calcula la bonificación diaria según la cantidad de kilos recolectados.
  Retorna 8_000 si los kilos son mayores o iguales a 120, y 0 en caso contrario.
  """
  def bonificacion_dia(kilos) when kilos >= @kilos_bonificacion, do: @bonificacion_diaria
  def bonificacion_dia(_kilos), do: 0

  @doc """
  Función que calcula la bonificación total de un recolector según los kilos recolectados por día.
  """
  def bonificacion(kilos_por_dia) do
    kilos_por_dia |> Map.values() |> Enum.map(&bonificacion_dia/1) |> Enum.sum()
  end

  @doc """
  Función que calcula el descuento por alimentación según el estado de alimentación del recolector y los días trabajados.
  """
  def descuento_alimentacion(%{alimentacion: true}, dias_trabajados),
    do: dias_trabajados * @descuento_alimentacion

  def descuento_alimentacion(_recolector, _dias_trabajados), do: 0

  @doc """
  Función que reporta los kilos recolectados por día en una lista de pesajes.
  """
  def kilos_por_dia(pesajes) do
    Enum.reduce(pesajes, %{}, fn p, acc ->
      Map.update(acc, p.dia, p.kilos, fn kilos -> kilos + p.kilos end)
    end)
  end

  @doc """
  Función que calcula los kilos recolectados por cada recolector por día en una lista de
  pesajes.
  """
  def kilos_por_recolector_dia(pesajes) do
    pesajes
    |> Enum.group_by(fn p -> p.recolector end)
    |> Map.new(fn {codigo, lista} -> {codigo, kilos_por_dia(lista)} end)
  end

  @doc """
  Función que liquida un recolector según sus pesajes y devuelve un mapa con la información de
  la liquidación.
  """
  def liquidar_recolector(recolector, pesajes) do
    kilos_dia = kilos_por_dia(pesajes)
    valores_dia = valores_por_dia(pesajes)

    bruto = valores_dia |> Map.values() |> Enum.sum()
    bonificaciones = bonificacion(kilos_dia)
    dias_trabajados = map_size(kilos_dia)
    alimentacion = descuento_alimentacion(recolector, dias_trabajados)

    detalle =
      for dia <- Enum.sort(Map.keys(kilos_dia)) do
        kilos = Map.fetch!(kilos_dia, dia)

        %{
          dia: dia,
          kilos: kilos,
          valor: Map.fetch!(valores_dia, dia),
          bonificacion: bonificacion_dia(kilos)
        }
      end

    %{
      codigo: recolector.codigo,
      nombre: recolector.nombre,
      come: recolector.alimentacion,
      kilos: kilos_dia |> Map.values() |> Enum.sum(),
      bruto: bruto,
      bonificaciones: bonificaciones,
      alimentacion: alimentacion,
      dias_trabajados: dias_trabajados,
      neto: bruto + bonificaciones - alimentacion,
      detalle: detalle
    }
  end

  @doc """
  Función que liquida todos los recolectores según sus pesajes válidos y devuelve una lista de
  mapas con la información de cada liquidación.
  """
  def liquidar_todos(recolectores, pesajes_validos) do
    por_recolector = Enum.group_by(pesajes_validos, fn p -> p.recolector end)

    for recolector <- recolectores do
      liquidar_recolector(recolector, Map.get(por_recolector, recolector.codigo, []))
    end
  end

  @doc """
  Función que filtra los pesajes válidos según los lotes existentes.
  """
  defp valores_por_dia(pesajes) do
    Enum.reduce(pesajes, %{}, fn p, acc ->
      valor = valor_pesaje(p)
      Map.update(acc, p.dia, valor, fn acumulado -> acumulado + valor end)
    end)
  end
end
