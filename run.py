#!/usr/bin/env python3

import os
from vunit import VUnit
from pathlib import Path

# Create VUnit instance by parsing command line arguments
VU = VUnit.from_argv()  # Do not use compile_builtins.
VU.add_vhdl_builtins()  # Add the VHDL builtins explicitly!
VU.add_verification_components()
# VU.add_external_library("unisim", "vivado_libs/unisim")

# Create library 'lib'
lib = VU.add_library("lib")
lib.add_source_files("sauce/*.vhd")
lib.add_source_files("sauce/*/*.vhd")
lib.add_source_files("tb/*.vhd")

# Ensure wave file contains "run -all"
def ensure_run_all(wave_file_path):
    if not wave_file_path.exists():
        wave_file_path.parent.mkdir(parents=True, exist_ok=True)
        with open(wave_file_path, "w") as wave_file:
            wave_file.write("run -all\n")
    else:
        with open(wave_file_path, "r+") as wave_file:
            lines = wave_file.readlines()
            if not any(line.strip() == "run -all" for line in lines):
                wave_file.write("run -all\n")

# Add waveform automatically when running in GUI mode.
for tb in lib.get_test_benches():
    wave_file_path = Path("waves/") / f"{tb.name}.do"
    ensure_run_all(wave_file_path)
    tb.set_sim_option("modelsim.init_file.gui", str(wave_file_path))

##NOTE - maybe add checking of _wave.do
VU.main()