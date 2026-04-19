SCRIPT=$(readlink -f $BASH_SOURCE)
ROOTDIR=$(dirname $SCRIPT)
echo "Setup \$PRJROOT : $ROOTDIR"
export PRJROOT=$ROOTDIR

IVERILOGPATH=$ROOTDIR/tools/iverilog/bin
echo "Append path to Icarus : $IVERILOGPATH"
export PATH=$PATH:$IVERILOGPATH

PYPATH=$ROOTDIR/tools/py_scripts
echo "Append path to python scripts : $PYPATH"
export PATH=$PATH:$PYPATH

SHPATH=$ROOTDIR/tools/shell_scripts
echo "Append path to shell scripts : $SHPATH"
export PATH=$PATH:$SHPATH

echo "Final PATH : $PATH"
