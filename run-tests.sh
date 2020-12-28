#!/bin/sh
#
# Run benchmark tests in eredis and commit results
#
# Usage: $0 [-f]
#
# -f : ignore that results already exists for revision

redis_version=6.0.9
lasp_bench_rev=d9b3e78d64ea4709ca10ec062c7fc969c1c503d4

# Parse arguments
force=0
for arg in "$@"
do
    case $arg in
        -f|--force)
        force=1
        shift
        ;;
    esac
done

# Prepare eredis
rm -rf eredis
git clone git@github.com:Nordix/eredis.git
cd eredis

# Use correct path
sed -i 's|../eredis/|_build/default/lib/eredis/|' priv/basho_bench_eredis.config
sed -i 's|{duration, 15}|{duration, 1}|' priv/basho_bench_eredis.config
sed -i 's|../eredis/|_build/default/lib/eredis/|' priv/basho_bench_eredis_pipeline.config
sed -i 's|{duration, 15}|{duration, 1}|' priv/basho_bench_eredis_pipeline.config
# Modify timeout from 100ms to 500ms
sed -i 's|, 100)|, 200)|g' src/basho_bench_driver_eredis.erl

rev=$(git rev-parse HEAD)
cd -

# Stop if results already exists
[ -d "results/${rev}" ] && [ $force -ne 1 ] && echo "Results for ${rev} already exists." && exit 0

# Prepare lasp-bench
rm -rf lasp-bench
git clone git@github.com:lasp-lang/lasp-bench.git
cd lasp-bench
git reset --hard ${lasp_bench_rev}
cd -

# Build all
make -C eredis compile
make -C lasp-bench all

# Run tests
for testname in eredis eredis_pipeline
do
    cd eredis
    docker run --name redis -d --net=host redis:${redis_version}
    ../lasp-bench/_build/default/bin/lasp_bench priv/basho_bench_${testname}.config
    docker rm -f redis
    Rscript --vanilla ../lasp-bench/priv/summary.r -i tests/current
    cd -

    mkdir -p "results/${rev}/${testname}/"
    cp -r eredis/tests/current/* "results/${rev}/${testname}/"
done

# Create link to latest test run
cd results
rm latest
ln -s "${rev}" latest
cd -

# Push results
git config --global user.name 'Bjorn Svensson (cron)'
git config --global user.email 'bjosv@users.noreply.github.com'
git add results
git commit --allow-empty -m "Add results for eredis ${rev}"
git push
