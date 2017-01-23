# subsync.exs

Elixir Script (elixir > 1.3) to re-sync SRT subtitle files.

## Usage

Take input srt file in STDIN, output synced srt file to STDOUT.

parameters are :

```
elixir subsync.exs s1-orig s1-movie s2-orig s2-movie
```

`s1-orig`,`s1-movie`,`s2-orig`,`s2-movie` are time in format ISO with
millisecond precision (00:00:00.000).

- `s1` is a subtitle at the beginig of the file
- `s2` is a subtitle at the end of the file
- `*-orig` is the original subtitle time
- `*-movie` is the observed time of the start of the associated sentence in the movie.

If `s2` is not defined, then the script will just translate
all the subtitles by the computed offset according to `s1` offset.

If `s2` is defined, then the script will "scale" time in order
to sync s1 and s2 as defined in the output subtitle.

## Sync process example

- `less in.srt` to read the subtitle file
- at the begining, choose the first sentence easy to identify
  precisely, and note the starting time. (ex: `s1-orig=00:00:53.542`)
- at the end, choose the last sentence easy to identify precisely,
  and note the starting time. (`s2-orig=00:00:47.000`)
- play the movie, listen and find the begining time of the chosen first
  sentence, note it (`s1-movie=01:01:43.250`)
- play the movie, listen and find the begining time of the chosen last
  sentence, note it (`s2-movie=01:01:37.000`)
- then just execute `subsync.exs s1-orig s1-movie s2-orig s2-movie` so
  `cat in.srt | elixir subsync.exs 00:00:53.542 00:00:47.000 01:01:43.250 01:01:37.000 > out.srt`

If you do not want to scale subtitle and shorten the process, just skip the
`s2` subtitle and identify original and movie times for only one subtitle `s1`,
so in the example : `cat in.srt | elixir subsync.exs 00:00:53.542 00:00:47.000 > out.srt`
