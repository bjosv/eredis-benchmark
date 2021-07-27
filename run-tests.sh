#!/bin/sh -e
#
# Run benchmark tests in eredis and commit results
#
# Usage: $0 [-f]
#
# -f : ignore that results already exists for revision
#
# Requires eredis and lasp-bench to be checked out before
# running this script

redis_version=6.0.9

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

# Get eredis revision
cd eredis
rev=$(git rev-parse HEAD)
echo "Test eredis revision ${rev}"
cd -

# Stop if results already exists
[ -d "results/${rev}" ] && [ $force -ne 1 ] && echo "Results for ${rev} already exists." && exit 0

# Build all
make -C eredis clean compile
make -C lasp-bench clean all

# Run tests
for testname in eredis eredis_pipeline
do
    echo "Running test ${testname}..."
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
