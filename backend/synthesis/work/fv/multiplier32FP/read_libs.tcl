add_search_path /home/tools/design_kits/cadence/GPDK045/io /home/tools/design_kits/cadence/GPDK045/gsclib045_svt_v4.4/gsclib045/lef /home/tools/design_kits/cadence/GPDK045/giolib045_v3.3/lef -library -both
read_library -liberty -both \
    /home/tools/design_kits/cadence/GPDK045/gsclib045_svt_v4.4/gsclib045/timing/slow_vdd1v0_basicCells.lib \
    /home/tools/design_kits/cadence/GPDK045/gsclib045_svt_v4.4/gsclib045/timing/fast_vdd1v2_basicCells.lib

