SCRIPT=$(readlink -f $BASH_SOURCE)
BASEDIR=$(dirname $SCRIPT)

IVERILOGPATH=$BASEDIR/tools/iverilog/bin
echo "Append path to Icarus : $IVERILOGPATH"
export PATH=$PATH:$IVERILOGPATH

echo "Final PATH : $PATH"
