# PractRand Testing

This project uses [PractRand](https://github.com/imneme/PractRand) for
statistical testing. The test suite is not included by default and must be
downloaded and built separately.

## Building PractRand

1. Clone PractRand into the repository root:
   ```bash
   git clone https://github.com/imneme/PractRand.git practrand
   ```
2. Build the `RNG_test` tool:
   ```bash
   cd practrand
   make -j
   ```

After building, the executable should be available as `practrand/RNG_test`.
The script `tests/stats/practrand.sh` expects this exact path when running the
full statistical tests.

## Running the tests

First build Cromulent PRNG (which produces `build/dump_raw`). Then execute:

```bash
tests/stats/practrand.sh
```

Results are written to `tests/results/practrand128TB.txt`.
