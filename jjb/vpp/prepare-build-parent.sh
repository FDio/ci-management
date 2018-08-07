cd $WORKSPACE
cp dpdk/vpp-dpdk-dkms*.deb build-root/
rm -rf build_new
cp -r build-root build_new
git checkout HEAD~
