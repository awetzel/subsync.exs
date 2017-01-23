defmodule Sync do
  def to_ms(%Time{hour: h,minute: m,second: s,microsecond: {micro,_}}), do:
    (h*3600+m*60+s)*1000+div(micro,1000)
  def from_ms(ms), do: %Time{
    hour: div(ms,3600_000), 
    minute: div(rem(ms,3600_000),60_000),
    second: div(rem(rem(ms,3600_000),60_000),1000),
    microsecond: {rem(rem(rem(ms,3600_000),60_000),1000)*1000,3} }
  def from_list([h,m,s,ms]), do:
    %Time{hour: h,minute: m,second: s,microsecond: {ms*1000,3}}

  def transfo(time,scale,orig_before,orig_after), do:
    from_ms(max(0,trunc((to_ms(time)-to_ms(orig_before))*scale+to_ms(orig_after))))
  def time_scale({from_1,to_1},{from_2,to_2}), do:
    (to_ms(to_2)-to_ms(to_1))/(to_ms(from_2)-to_ms(from_1))
  def time_diff(from,to), do:
    to_ms(to)-to_ms(from)

  def srt_time(time), do:
    (time |> Time.to_iso8601 |> String.replace(".",","))
  def srt_mapper(from_1,to_1,scale) do
    IO.puts :stderr, "transform scale #{scale}, offset init #{time_diff(from_1,to_1)}"
    fn line-> # use regex matching to be flexible if the input srt does not pas time parts
      case Regex.run(~r/^([0-9]+):([0-9]+):([0-9]+),([0-9]+)\s*-->\s*([0-9]+):([0-9]+):([0-9]+),([0-9]+)/,line) do
        nil->line #if not a line spec line, copy as is
        [matched|nums]->  #else, afine transformation of times and replace
          {from,to} = nums |> Enum.map(&String.to_integer/1) |> Enum.split(4)
          from = transfo(from_list(from),scale,from_1,to_1); to = transfo(from_list(to),scale,from_1,to_1)
          String.replace(line,matched,"#{srt_time from} --> #{srt_time to}")
      end
    end
  end
end

case for(arg<-System.argv, {:ok,t}=Time.from_iso8601(arg), do: t) do
  [from_1,to_1,from_2,to_2]->
    scale = Sync.time_scale({from_1,to_1},{from_2,to_2})
    IO.stream(:stdio, :line) |> Stream.map(Sync.srt_mapper(from_1,to_1,scale)) |> Enum.into(IO.stream(:stdio,:line))
  [from_1,to_1]->
    IO.stream(:stdio, :line) |> Stream.map(Sync.srt_mapper(from_1,to_1,1)) |> Enum.into(IO.stream(:stdio,:line))
  _-> IO.puts """
        usage : cat in.srt | elixir subsync.exs 00:00:00.000 00:00:01.023 01:00:00.000 01:00:03.022 > res.srt
        usage : cat in.srt | elixir subsync.exs 00:00:00.000 00:00:01.023 > res.srt

        The second one only applies an offset to the subs, the first one take a last sub as reference to apply a time scale
        """
end
#File.stream!("A.Series.of.Unfortunate.Events.s01e02.WebRip.x264-FS.srt")
