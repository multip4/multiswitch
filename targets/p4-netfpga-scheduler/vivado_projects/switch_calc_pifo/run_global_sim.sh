cd $P4_PROJECT_DIR && make
cp config_writes.txt nf_sume_sdnet_ip/SimpleSumeSwitch/
make config_writes
make uninstall_sdnet && make install_sdnet
cd $NF_DESIGN_DIR/test/sim_switch_default && make
cd $SUME_FOLDER
./tools/scripts/nf_test.py sim --major switch --minor default