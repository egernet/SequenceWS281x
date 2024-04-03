# SequenceWS281x

Swift wrapper for [rpi-ws281x-swift](https://github.com/apocolipse/rpi-ws281x-swift)

## To run

```
swift run SequenceWS281x --mode app
```
or
```
swift run SequenceWS281x --mode console
```

If you run this package on a __mac__ then the __SequenceWS281x__ will run ase a simulator.
Use a terminal with true-color mode for full color simule. You can use [iterm2](https://iterm2.com/downloads.html)

The demo will show a matrix of 3 x 55 LED

<picture>
  <img alt="Demo gif" width="450" src="/../main/Doc/demo.gif">
</picture>

</br>
or in window on you mac

</br>

<picture>
  <img alt="Demo gif" width="450" src="/../main/Doc/demo_mac.gif">
</picture>

</br>
</br>

SequenceWS281x can be use with:

```
USAGE: sequenceWS281x [--mode <mode>] [--matrix-width <matrix-width>] [--matrix-height <matrix-height>]

OPTIONS:
  --mode <mode>           Executes mode: [real, app, console] (default: real)
  --matrix-width <matrix-width>
                          Matrix width (default: 3)
  --matrix-height <matrix-height>
                          Matrix height (default: 55)
  --version               Show the version.
  -h, --help              Show help information.
```

</br>
</br>

You can now create sequences via __JavaScript__. The engine to running __JavaScript__ from [__ELK__](https://github.com/cesanta/elk). The __JavaScript__ engine is a lightweight engine.

</br>
</br>

See also [SwiftyGPIO](https://github.com/uraimo/SwiftyGPIO) </br>
See also [JS engine](https://github.com/cesanta/elk)
