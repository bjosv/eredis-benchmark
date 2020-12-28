# eredis-benchmark

A repo running benchmark tests in [eredis](https://github.com/Nordix/eredis)

Uses the load generator [lasp-bench](https://github.com/lasp-lang/lasp-bench)
to benchmark the send performance in eredis.

Each night the Github Action workflow will benchmark the latest revision of eredis
master branch. Results will be auto-commited to the directory:
`results/<sha>/`

and the results from the latest revision of eredis can be found in:
`results/latest/`
