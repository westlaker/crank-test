# CRANK_WORK_DIR can be changed to any folder
CRANK_WORK_DIR=$(pwd)/crank_agent_home
CRANK_DOTNET=$CRANK_WORK_DIR/dotnet
export DOTNET_ROOT=$CRANK_DOTNET
export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH
export NUGET_PLUGINS_CACHE_PATH=$CRANK_WORK_DIR/NUGET_PLUGINS_CACHE_PATH
export NUGET_PACKAGES=$CRANK_WORK_DIR/NUGET_PACKAGES
export NUGET_HTTP_CACHE_PATH=$CRANK_WORK_DIR/NUGET_HTTP_CACHE_PATH
export NUGET_SCRATCH=$CRANK_WORK_DIR/NUGET_SCRATCH
export DOTNET_NUGET_SIGNATURE_VERIFICATION=false
 
# kill all active crank agents if any
pkill crank-agent || true
fuser -n tcp -k 5010 || true
fuser -n tcp -k 5014 || true
fuser -n tcp -k 5000 || true
if [ ! -d "$CRANK_WORK_DIR" ]; then
    mkdir $CRANK_WORK_DIR
    wget https://dot.net/v1/dotnet-install.sh -O $CRANK_WORK_DIR/dotnet-install.sh
    chmod +x $CRANK_WORK_DIR/dotnet-install.sh
 
    # install local .NET 8.0 for crank-agent:
    $CRANK_WORK_DIR/./dotnet-install.sh -Channel "8.0" -InstallDir $CRANK_DOTNET
    dotnet tool install Microsoft.Crank.Agent --version "0.2.0-*" --tool-path $DOTNET_ROOT/tools
fi
 
# Run the crank-agent (with nohup to keep it running, see crank_agent.log)
echo "\nStarting 'crank-agent', logs are being written at '$CRANK_WORK_DIR/crank_agent.log'"
DOTNET_NUGET_SIGNATURE_VERIFICATION=false nohup crank-agent \
 --build-path ${CRANK_WORK_DIR}/crank_buildpath \
 --dotnethome ${CRANK_WORK_DIR}/crank_dotnethome \
 --url "http://*:5010" > $CRANK_WORK_DIR/crank_agent.log 2>&1 &
  
 sleep 10
 echo "\nStarted!\n"
