defmodule Util do
  @moduledoc """
  Módulo de utilidades para el programa de la finca cafetera. Maneja funciones impuras.
  """

  @doc """
  Función que lee una línea de entrada del usuario y la devuelve como una cadena de texto.
  """
  def leer_linea(mensaje) do
    case IO.gets(mensaje) do
      texto when is_binary(texto) -> String.trim(texto)
      _ -> ""
    end
  end

  @doc """
  Función que imprime un texto en la salida estándar.
  """
  def imprimir(texto) do
    IO.puts(texto)
    :ok
  end

  @doc """
  Función que indexa una lista de mapas por un campo específico, devolviendo un mapa donde
  las claves son los valores del campo y los valores son los mapas originales.
  """
  def indexar_por(lista, campo) do
    Map.new(lista, fn elemento -> {Map.get(elemento, campo), elemento} end)
  end

  @doc """
  Función que formatea un número para su presentación.
  Si es un entero, se devuelve como cadena.
  Si es un flotante, se redondea a dos decimales y se devuelve como cadena.
  Si es otro tipo, se devuelve su representación en cadena.
  """
  def formatear_numero(numero) when is_integer(numero), do: Integer.to_string(numero)

  def formatear_numero(numero) when is_float(numero) do
    redondeado = Float.round(numero, 2)

    if redondeado == Float.floor(redondeado) do
      Integer.to_string(trunc(redondeado))
    else
      Float.to_string(redondeado)
    end
  end

  def formatear_numero(otro), do: texto(otro)

  @doc """
  Funcion que formatea un decimal a dos decimales y lo devuelve como cadena.
  """
  def formatear_decimal(numero) do
    :erlang.float_to_binary(numero * 1.0, decimals: 2)
  end

  @doc """
  Función que formatea un valor monetario a una cadena con el símbolo de dólar y dos decimales.
  """
  def formatear_moneda(valor), do: "$" <> formatear_decimal(valor)

  @doc """
  Función que devuelve una representación en cadena de un valor.
  Si es una cadena, se devuelve tal cual.
  Si es un número, se convierte a cadena.
  Para otros tipos, se utiliza inspect para obtener su representación en cadena.
  """
  def texto(valor) when is_binary(valor), do: valor
  def texto(valor) when is_number(valor), do: to_string(valor)
  def texto(valor), do: inspect(valor)
end
