#!/bin/bash

# Configuration
ELF_FILE="$1"  # Path to your .elf file, passed as an argument
OPENOCD_CFG="/home/zacck/Documents/openocd_stlink_configs/stlink_f4_disco.cfg"  # Path to your OpenOCD config file
OPENOCD_PID=""

# Check if ELF file is provided
if [ -z "$ELF_FILE" ]; then
    echo "Error: Please provide the path to the .elf file as an argument."
    echo "Usage: $0 <path_to_elf_file>"
    exit 1
fi

# Check if ELF file exists
if [ ! -f "$ELF_FILE" ]; then
    echo "Error: ELF file '$ELF_FILE' not found."
    exit 1
fi

# Check if OpenOCD config file exists
if [ ! -f "$OPENOCD_CFG" ]; then
    echo "Error: OpenOCD config file '$OPENOCD_CFG' not found."
    exit 1
fi

# Start OpenOCD in the background
echo "Starting OpenOCD..."
openocd -f "$OPENOCD_CFG" &
OPENOCD_PID=$!

# Waiting 2 briefly for OpenOCD to initialize
sleep 2

# Check if OpenOCD is running
if ! ps -p $OPENOCD_PID > /dev/null; then
    echo "Error: OpenOCD failed to start. Check the OpenOCD output or config."
    exit 1
fi

#target extended-remote localhost:3333
#monitor init

# Create a temporary GDB script
GDB_SCRIPT=$(mktemp)
cat << EOF > "$GDB_SCRIPT"
target remote localhost:3333
monitor reset halt
load
monitor reset run
quit
EOF

# Run GDB with the script
echo "Flashing $ELF_FILE..."
arm-none-eabi-gdb -batch -x "$GDB_SCRIPT" "$ELF_FILE"

# Check GDB exit status
GDB_STATUS=$?
if [ $GDB_STATUS -ne 0 ]; then
    echo "Error: GDB flashing failed."
    kill $OPENOCD_PID 2>/dev/null
    rm "$GDB_SCRIPT"
    exit $GDB_STATUS
fi

# Clean up
echo "Flashing complete. Stopping OpenOCD..."
kill $OPENOCD_PID 2>/dev/null
rm "$GDB_SCRIPT"echo "Done!"
exit 0




