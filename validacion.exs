# Parcial 1 - Programación 3
# Integrantes: Natalia García Hidalgo, Diego Rincón Álvarez

defmodule Validacion do
  @moduledoc """
  Módulo que contiene funciones para validar los pesajes de los recolectores.
  """

  @dias_cosecha 1..6
  @maximo_kilos 250

  @motivos [
    :recolector_desconocido,
    :lote_desconocido,
    :dia_invalido,
    :kilos_fuera_de_rango,
    :porcentaje_invalido
  ]

  def dias_cosecha, do: @dias_cosecha

  def motivos, do: @motivos

  @doc """
  Función que valida un pesaje según los criterios establecidos.
  """
  def validar_pesaje(pesaje, recolectores, lotes) do
    with :ok <- validar_recolector(pesaje.recolector, recolectores),
         :ok <- validar_lote(pesaje.lote, lotes),
         :ok <- validar_dia(pesaje.dia),
         :ok <- validar_kilos(pesaje.kilos),
         :ok <- validar_verdes(pesaje.verdes) do
      {:ok, pesaje}
    end
  end

  @doc """
  Función que separa los pesajes en válidos e inválidos según los criterios de validación.
  """
  def separar_pesajes(pesajes, recolectores, lotes) do
    resultados = Enum.map(pesajes, fn p -> {p, validar_pesaje(p, recolectores, lotes)} end)

    validos = for {_pesaje, {:ok, p}} <- resultados, do: p
    invalidos = for {pesaje, {:error, motivo}} <- resultados, do: {pesaje, motivo}

    {validos, invalidos}
  end

  @doc """
  Función que parsea una línea de texto en un mapa de pesaje.
  """
  def parsear_pesaje(linea) do
    campos = linea |> String.split(";") |> Enum.map(&String.trim/1)

    with [recolector, lote, dia, kilos, verdes] <- campos,
         {dia, ""} <- Integer.parse(dia),
         {kilos, ""} <- Float.parse(kilos),
         {verdes, ""} <- Float.parse(verdes) do
      {:ok, %{recolector: recolector, lote: lote, dia: dia, kilos: kilos, verdes: verdes}}
    else
      _ -> {:error, :formato_invalido}
    end
  end

  @doc """
  Funcion que valida si el recolector existe en la lista de recolectores.
  """
  defp validar_recolector(codigo, recolectores) do
    if Map.has_key?(recolectores, codigo), do: :ok, else: {:error, :recolector_desconocido}
  end

  @doc """
  Funcion que valida si el lote existe en la lista de lotes.
  """
  defp validar_lote(id, lotes) do
    if Map.has_key?(lotes, id), do: :ok, else: {:error, :lote_desconocido}
  end

  @doc """
  Funcion que valida si el dia es un dia de cosecha valido.
  """
  defp validar_dia(dia) when is_integer(dia) and dia in @dias_cosecha, do: :ok
  defp validar_dia(_dia), do: {:error, :dia_invalido}

  @doc """
  Funcion que valida si los kilos estan dentro del rango permitido.
  """
  defp validar_kilos(kilos) when is_number(kilos) and kilos > 0 and kilos <= @maximo_kilos,
    do: :ok

  defp validar_kilos(_kilos), do: {:error, :kilos_fuera_de_rango}

  @doc """
  Funcion que valida si el porcentaje de verdes esta dentro del rango permitido.
  """
  defp validar_verdes(verdes) when is_number(verdes) and verdes >= 0 and verdes <= 100, do: :ok
  defp validar_verdes(_verdes), do: {:error, :porcentaje_invalido}
end
