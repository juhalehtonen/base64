defmodule Base64 do
  @moduledoc """
  Encode and decode binary data with base64.
  """

  @base64_table "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  @pad "="
  @source_chunk_size 3

  @doc """
  Encode binary file using base64
  """
  @spec encode_file(binary(), binary()) :: :ok | {:error, term()}
  def encode_file(input_path, output_path) do
    input_path
    |> read_file()
    |> encode()
    |> write_file(output_path)
  end

  @doc """
  Encode binary data as ASCII text

  ## Examples

      iex> Base64.encode("M")
      "TQ=="

      iex> Base64.encode("Ma")
      "TWE="

      iex> Base64.encode("Man")
      "TWFu"

  """
  @spec encode(binary()) :: binary()
  def encode(data) do
    {data, n_padding} = ensure_size(data)
    do_encode(data, n_padding)
  end

  @spec do_encode(binary(), non_neg_integer()) :: binary()
  defp do_encode(data, n_padding) do
    data
    |> chunk_by(6)
    |> convert_to_ascii(n_padding)
  end

  @spec convert_to_ascii([<<_::6>>], non_neg_integer()) :: binary()
  defp convert_to_ascii(sixtets, n_padding) do
    result = sixtets
      |> Enum.map(&table_lookup/1)
      |> Enum.join("")

    result <> String.duplicate(@pad, n_padding)
  end

  @spec table_lookup(<<_::6>>) :: binary() | nil
  defp table_lookup(<<sixtet_value::6>>), do: String.at(@base64_table, sixtet_value)

  @spec chunk_by(bitstring(), 6) :: [<<_::6>>]
  defp chunk_by(data, n_chunk) do
    for << c::size(n_chunk) <- data >>, do: <<c::size(n_chunk)>>
  end

  @spec ensure_size(bitstring()) :: {bitstring(), integer()}
  defp ensure_size(data) do
    n_padding = rem(bit_size(data), @source_chunk_size)
    x = 6 - n_padding

    if n_padding == 0 do
      {data, n_padding}
    else
      {<< data::bits, <<0::size(x)>> >>, n_padding}
    end
  end

  @spec write_file(binary(), binary()) :: :ok | {:error, atom()}
  defp write_file(data, path) do
    with {:ok, file_handle} <- File.open(path, [:write]) do
      file_handle
      |> IO.binwrite(data)
    end
  end

  @spec read_file(binary()) :: :eof | binary() | [byte()] | {:error, atom() | {:no_translation, :unicode, :latin1}}
  defp read_file(path) do
    with {:ok, file_handle} <- File.open(path) do
      file_handle
      |> IO.binread(:all)
    end
  end
end
