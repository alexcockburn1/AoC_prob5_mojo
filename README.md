# AoC_prob5_mojo

## Comparison to Python
It took Python implementation 5.9095104160078336 seconds to run 1000000 iterations.
There are 2482221626 numbers to check, so I estimate 14668 seconds ~=4 hours
## Mojo implementation
Just replacing classes with structs takes about 25 mins
## Parallelized
mojo prob5.mojo  1416.51s user 0.53s system 389% cpu 6:03.95 total 
## Vectorized and parallelized

`simdwith = simdwidthof[DType.int64]()*2`
mojo prob5.mojo  110.50s user 0.20s system 360% cpu 30.742 total
mojo prob5.mojo  109.76s user 0.07s system 366% cpu 29.930 total
mojo prob5.mojo  111.82s user 0.07s system 366% cpu 30.522 total

`simdwith = simdwidthof[DType.int64]()`
mojo prob5.mojo  120.16s user 0.05s system 365% cpu 32.931 total
mojo prob5.mojo  119.32s user 0.04s system 365% cpu 32.688 total
mojo prob5.mojo  123.58s user 0.08s system 365% cpu 33.875 total

`simdwith = 1`
mojo prob5.mojo  174.31s user 0.15s system 356% cpu 48.997 total
mojo prob5.mojo  171.92s user 0.06s system 358% cpu 47.935 total
mojo prob5.mojo  173.31s user 0.09s system 359% cpu 48.273 total