# credit: https://askubuntu.com/questions/850281/opencl-on-ubuntu-16-04-intel-sandy-bridge-cpu
# website saved in https://web.archive.org/web/20190308021648/https://askubuntu.com/questions/850281/opencl-on-ubuntu-16-04-intel-sandy-bridge-cpu in case it is deleted
# archive saved on 07/03/2019 (dd/mm/yyyy) 
sudo aptitude install ocl-icd-libopencl1 opencl-headers clinfo opencl-icd-opencl-dev
# since I made it just to fix my issues, the following code will only work on Intel products.
sudo aptitude install beignet
cd /tmp
mkdir openclinstaller
cd openclinstaller
wget https://codeload.github.com/hpc12/tools/tar.gz/master
# https://web.archive.org/web/20190308021848/https://codeload.github.com/hpc12/tools/tar.gz/master
# archive saved on 07/03/2019 (dd/mm/yyyy) 
mv master master.tar.gz
tar xzvf master.tar.gz
cd tools-master
make
./print-devices
./cl-demo
cd ..
rmdir openclinstaller
