defmodule Identicon.Renderer.PNG do
  @moduledoc false

  @type rgb :: {non_neg_integer, non_neg_integer, non_neg_integer}

  def encode(width, height, bg, fg, pixel_map) do
    rows = build_rows(width, height, bg, fg, pixel_map)

    collect_bytes(fn callback ->
      png = :png.create(%{size: {width, height}, mode: {:rgb, 8}, call: callback})
      _ = :png.append(png, {:rows, rows})
      :ok = :png.close(png)
    end)
  end

  defp build_rows(width, height, bg, fg, pixel_map) do
    for y <- 0..(height - 1) do
      for x <- 0..(width - 1), into: <<>> do
        if inside_any?(x, y, pixel_map), do: rgb(fg), else: rgb(bg)
      end
    end
  end

  defp rgb({r, g, b}), do: <<r, g, b>>
  defp inside_any?(x, y, rects), do: Enum.any?(rects, &inside_rect?(x, y, &1))
  defp inside_rect?(x, y, {{x1, y1}, {x2, y2}}), do: x >= x1 and x < x2 and y >= y1 and y < y2

  defp collect_bytes(run) do
    key = {__MODULE__, make_ref()}
    Process.put(key, [])

    run.(fn io_data ->
      Process.put(key, [io_data | (Process.get(key) || [])])
      :ok
    end)

    key
    |> Process.get()
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end
end
