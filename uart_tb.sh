#!/bin/bash

MODULE_NAME="${0%\.*}"
MODULE_NAME="${MODULE_NAME#\.\/}"
WAVE_FILE="wave.ghw"

mkdir work
cd work

echo "analysing ..."
ghdl -a --std=08 ../baud_rate_gen.vhd
ghdl -a --std=08 ../uart_tx.vhd
ghdl -a --std=08 ../${MODULE_NAME}.vhd
echo "elaborating ..."
ghdl -e --std=08 ${MODULE_NAME}
echo "running ..."
ghdl -r --std=08 ${MODULE_NAME} --wave=$WAVE_FILE
echo "launching gtkwave"
gtkwave $WAVE_FILE ../${MODULE_NAME}.gtkw
