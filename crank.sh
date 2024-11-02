# CRANK_WORK_DIR can be changed to any folder
CRANK_WORK_DIR=$(pwd)/crank_controller_home
CRANK_DOTNET=$CRANK_WORK_DIR/dotnet
export DOTNET_ROOT=$CRANK_DOTNET
export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH
if [ ! -d "$CRANK_WORK_DIR" ]; then
    mkdir $CRANK_WORK_DIR
    wget https://dot.net/v1/dotnet-install.sh -O $CRANK_WORK_DIR/dotnet-install.sh
    chmod +x $CRANK_WORK_DIR/dotnet-install.sh
    $CRANK_WORK_DIR/./dotnet-install.sh -Channel "8.0" -InstallDir $CRANK_DOTNET
    dotnet tool install Microsoft.Crank.Controller --version "0.2.0-*" --tool-path $DOTNET_ROOT/tools
fi
 
# TE Json:
#crank --profile CedarCrestProfile --config json.yaml --scenario json
 
# for OrcardCMS:
crank --profile CedarCrestProfile --config orchard.yaml --scenario about-sqlite
