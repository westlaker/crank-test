#!/bin/bash

# Default parameters
: ${DOTNET_VER:="9.0"}     # Can be either "8.0" or "9.0" for exact versions (e.g. previews) see dotnet-install.sh args below
#: ${APP_CPUSET:="26-40"}    # Affinity mask for OrcharCMS, e.g 0-14 (15 cores)
: ${APP_CPUSET:="$1-$2"}    # Affinity mask for OrcharCMS, e.g 0-14 (15 cores)
: ${WRK_CPUSET:="45"}      # Affinity mask for load generator. typically, just one core is enough, consider using more
                           # if OrchardCMS uses more than 15 cores.
: ${USE_WRK:="1"}          # if set to 0, bombardier will be used (good for fixed-rate RPS testing)
: ${WARM:="120s"}	   # warm up run time in seconds
: ${RUN:="20s"}		   # run test time

: ${WRK_CONNECTIONS:="64"} # 64 connections are enough, consider increasing if more cores are used
: ${USE_PERF:="0"}
: ${ALL_SYMBOLS:="0"}

: ${OUTPUTFILE:="results${DOTNET_VER}_${APP_CPUSET}_${WARM}_${RUN}.txt"}

echo "====================================================="
echo "run tests on cores $APP_CPUSET and wrk on $WRK_CPUSET"
echo "warm-up is $WARM and run time is $RUN"
echo "====================================================="


echo  "=====================================================" > "$OUTPUTFILE" 2>&1
echo  "run tests on cores $APP_CPUSET and wrk on $WRK_CPUSET" >> "$OUTPUTFILE" 2>&1
echo  "warm-up is $WARM and run time is $RUN" >> "$OUTPUTFILE" 2>&1
echo  "=====================================================" >> "$OUTPUTFILE" 2>&1

if [ "$(uname)" == "Darwin" ]; then
    USE_WRK=0 # wrk is not available on macOS
fi

BENCH_DIR=$(pwd)/orchard-bench$DOTNET_VER

LOCAL_DOTNET=$BENCH_DIR/dotnet
export DOTNET_ROOT=$LOCAL_DOTNET
export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:$BENCH_DIR:$PATH
export NUGET_PLUGINS_CACHE_PATH=$BENCH_DIR/NUGET_PLUGINS_CACHE_PATH
export NUGET_PACKAGES=$BENCH_DIR/NUGET_PACKAGES
export NUGET_HTTP_CACHE_PATH=$BENCH_DIR/NUGET_HTTP_CACHE_PATH
export NUGET_SCRATCH=$BENCH_DIR/NUGET_SCRATCH
export DOTNET_NUGET_SIGNATURE_VERIFICATION=false

# install .NET 8.0 and 9.0
#####################################################
if [ ! -d "$BENCH_DIR" ]; then
    echo 'Install dependencies...'
    
    # kill active benchmarks (JIC)
    pkill OrchardCore || true
    pkill wrk || true
    pkill bombardier || true
    fuser -n tcp -k 5014 || true
    rm -rf $BENCH_DIR || true # it may appear after process kill ^
    mkdir $BENCH_DIR

    TARGET_ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')"
    TARGET_OS="$(uname | tr '[:upper:]' '[:lower:]')"

    # normalize x86_64 to amd64 and aarch64 to arm64
    if [ "$TARGET_ARCH" == "x86_64" ]; then
        TARGET_ARCH="amd64"
    fi
    if [ "$TARGET_ARCH" == "aarch64" ]; then
        TARGET_ARCH="arm64"
    fi

    wget https://github.com/codesenberg/bombardier/releases/download/v1.2.6/bombardier-$TARGET_OS-$TARGET_ARCH -O $BENCH_DIR/bombardier
    chmod +x $BENCH_DIR/bombardier

    #if [ "$(uname)" == "Darwin" ]; then
    #    brew install cpuset
    #else
    #    apt-get update
    #    apt-get install -y wrk || exit 1
    #fi

    git clone https://github.com/orchardcms/orchardcore.git $BENCH_DIR/orchardcore
    # We need to checkout a branch that supports .NET 9.0 (to be removed once .NET 9.0 reaches GA)
    if [ "$DOTNET_VER" = "9.0" ]; then
        git -C $BENCH_DIR/orchardcore checkout sebros/net90
    fi
    wget https://dot.net/v1/dotnet-install.sh -O $BENCH_DIR/dotnet-install.sh
    chmod +x $BENCH_DIR/dotnet-install.sh
    $BENCH_DIR/./dotnet-install.sh -Channel "8.0" -InstallDir $LOCAL_DOTNET
    $BENCH_DIR/./dotnet-install.sh -Channel "9.0" -InstallDir $LOCAL_DOTNET
    echo "Building..."
    dotnet publish -c Release --sc -f net$DOTNET_VER $BENCH_DIR/orchardcore/src/OrchardCore.Cms.Web/OrchardCore.Cms.Web.csproj
    if [ "$USE_PERF" = "1" ]; then
        dotnet tool install dotnet-symbol --tool-path $DOTNET_ROOT/tools
        TFM_FOLDER=$(find "$BENCH_DIR/orchardcore/src/OrchardCore.Cms.Web/bin/Release/net$DOTNET_VER" -mindepth 1 -maxdepth 1 -type d | head -n 1)
        PUBLISH_FOLDER=$TFM_FOLDER/publish
        dotnet-symbol --symbols $PUBLISH_FOLDER/libcoreclr.*
        dotnet-symbol --symbols $PUBLISH_FOLDER/libclrjit.*
        dotnet-symbol --symbols $PUBLISH_FOLDER/System.Private.CoreLib.dll
        if [ "$ALL_SYMBOLS" = "1" ]; then
            dotnet-symbol --symbols $PUBLISH_FOLDER/*.dll
            dotnet-symbol --symbols $PUBLISH_FOLDER/*.so
        fi
    fi
else
    echo 'Environment is already prepared, skipping..'
fi
#####################################################

# kill active benchmarks (JIC)
pkill OrchardCore || true
pkill wrk || true
pkill bombardier || true
fuser -n tcp -k 5014 || true

export OrchardCore__OrchardCore_AutoSetup__Tenants__0__ShellName="Default"
export OrchardCore__OrchardCore_AutoSetup__Tenants__0__SiteName="Benchmark"
export OrchardCore__OrchardCore_AutoSetup__Tenants__0__SiteTimeZone="Europe/Amsterdam"
export OrchardCore__OrchardCore_AutoSetup__Tenants__0__AdminUsername="admin"
export OrchardCore__OrchardCore_AutoSetup__Tenants__0__AdminEmail="info@orchardproject.net"
export OrchardCore__OrchardCore_AutoSetup__Tenants__0__AdminPassword="Password1!"
export OrchardCore__OrchardCore_AutoSetup__Tenants__0__DatabaseProvider="Sqlite"
export OrchardCore__OrchardCore_AutoSetup__Tenants__0__RecipeName="Blog"
export DOTNET_GCDynamicAdaptationMode=0 # DATAS has to be disabled for such workloads (15% perf overhead)
export DOTNET_HillClimbing_Disable=1    # we get to the steady-state faster

# Perf quirks
#export DOTNET_ReadyToRun=0
#export DOTNET_JitGuardedDevirtualizationMaxTypeChecks=3
#export DOTNET_HillClimbing_Disable=1
#export DOTNET_BGCSpin=10
#export DOTNET_GCgen0size=0x8000000

if [ "$USE_PERF" = "1" ]; then
    export DOTNET_JitEnableOptionalRelocs=0
    export DOTNET_JitStdOutFile=""
    export DOTNET_PerfMapShowOptimizationTiers=1
    export DOTNET_JitFramed=1
    export DOTNET_PerfMapEnabled=1
    export DOTNET_EnableWriteXorExecute=0
fi

##export DOTNET_GCWriteBarrier=1
##DEFAULT=0,REGION_BIT=1,REGION_BYTE=2,SERVER=3
#export DOTNET_ThreadPool_UnfairSemaphoreSpinLimit=0

SERVER_ADDRESS="$(hostname)"
echo "Starting..."
pushd $BENCH_DIR/orchardcore/src/OrchardCore.Cms.Web > /dev/null
TFM_FOLDER=$(find "$BENCH_DIR/orchardcore/src/OrchardCore.Cms.Web/bin/Release/net$DOTNET_VER" -mindepth 1 -maxdepth 1 -type d | head -n 1)
nohup taskset -c $APP_CPUSET $TFM_FOLDER/publish/./OrchardCore.Cms.Web --urls http://$SERVER_ADDRESS:5014 > orchard.log 2>&1 &
sleep 5 # give it some time to bind a socket (or wait for 'Now listening on:' in its stdout)
popd > /dev/null
echo "Started..."

#####################################################
# Load generation (can be run on a different machine)
#####################################################
trap "exit" INT

#
#MAX=$WARM
#for (( i=0; i<MAX; i++ )) ; {
#    taskset -c $WRK_CPUSET wrk -d 10s -c $WRK_CONNECTIONS http://$SERVER_ADDRESS:5014/about --latency --header "Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7" --header "Connection: keep-alive"
#}

if [ "$USE_WRK" = "1" ]; then
	echo "start #0 wrk for warm-up $WARM..."
	taskset -c $WRK_CPUSET wrk -d $WARM -c $WRK_CONNECTIONS http://$SERVER_ADDRESS:5014/about --latency --header "Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7" --header "Connection: keep-alive" >> "$OUTPUTFILE" 2>&1 #>> results${DOTNET_VER}_${APP_CPUSET}_$(WARM)_$(RUN).txt 2>&1
	echo "start #1 wrk for $RUN..."
	taskset -c $WRK_CPUSET wrk -d $RUN -c $WRK_CONNECTIONS http://$SERVER_ADDRESS:5014/about --latency --header "Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7" --header "Connection: keep-alive" >> "$OUTPUTFILE" 2>&1 #>> results${DOTNET_VER}_${APP_CPUSET}_$(WARM)_$(RUN).txt 2>&1
	echo "start #2 wrk for $RUN..."
	taskset -c $WRK_CPUSET wrk -d $RUN -c $WRK_CONNECTIONS http://$SERVER_ADDRESS:5014/about --latency --header "Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7" --header "Connection: keep-alive" >> "$OUTPUTFILE" 2>&1 #>> results${DOTNET_VER}_${APP_CPUSET}_$(WARM)_$(RUN).txt 2>&1
    #taskset -c $WRK_CPUSET wrk -d 20s -c $WRK_CONNECTIONS http://$SERVER_ADDRESS:5014/about --latency --header "Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7" --header "Connection: keep-alive" | grep "Requests/sec" > results${DOTNET_VER}_1.txt 2>&1
    #taskset -c $WRK_CPUSET wrk -d 20s -c $WRK_CONNECTIONS http://$SERVER_ADDRESS:5014/about --latency --header "Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7" --header "Connection: keep-alive" | grep "Requests/sec" > results${DOTNET_VER}_2.txt 2>&1
else
    taskset -c $WRK_CPUSET $BENCH_DIR/./bombardier -d $WARM -c $WRK_CONNECTIONS -t 2s --insecure -l --fasthttp --header "Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7" --header "Connection: keep-alive" http://$SERVER_ADDRESS:5014/about
    taskset -c $WRK_CPUSET $BENCH_DIR/./bombardier -d $RUN -c $WRK_CONNECTIONS -t 2s --insecure -l --fasthttp --header "Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7" --header "Connection: keep-alive" http://$SERVER_ADDRESS:5014/about | grep "Reqs/sec" > results${DOTNET_VER}_1.txt 2>&1
    taskset -c $WRK_CPUSET $BENCH_DIR/./bombardier -d $RUN -c $WRK_CONNECTIONS -t 2s --insecure -l --fasthttp --header "Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7" --header "Connection: keep-alive" http://$SERVER_ADDRESS:5014/about | grep "Reqs/sec" > results${DOTNET_VER}_2.txt 2>&1
fi

# rm perf.data || true
# rm perfjit.data || true
# perf record -k 1 -g -F 999 -p $(pgrep OrchardCore.Cms) sleep 3
# perf inject --input perf.data --jit --output perfjit.data
# perf report --input perfjit.data --no-children --percent-limit 2

#echo "RPS: $(cat results${DOTNET_VER}_${APP_CPUSET}.txt)"
#echo "RPS2: $(cat results${DOTNET_VER}_2.txt)"
pkill OrchardCore || true

