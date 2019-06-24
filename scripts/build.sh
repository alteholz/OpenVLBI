#!/bin/bash
sudo add-apt-repository ppa:~mutlaqja -y
sudo apt-get -qq update
sudo apt-get install indi-full libpthread-stubs0-dev libcfitsio-dev zlib1g-dev cmake

mkdir -p build
pushd build
cmake ..
make
make install
popd
