#start of Dokerfile
#docker for run lemon (https://github.com/vterron/lemon) using debian 'buster'

#set the image base
FROM debian:buster-slim

#add lemon user
RUN useradd -ms /bin/bash lemon 

#initial repo update
RUN apt-get -y update

#basic tools
RUN apt-get install -y wget vim git csh curl

#install python
RUN apt install -y python 

#python3 (used in astrometry.net)
RUN ln -s /usr/bin/python /usr/bin/python3

#install pip
RUN mkdir /home/lemon/Downloads &&  cd /home/lemon/Downloads
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
RUN python get-pip.py

#install python (2.7) common packages
RUN apt-get install -y python-gtk2-dev python-pip python-matplotlib python-scipy python-numpy python-dev
RUN pip install pyfits

#common libraries and tools
RUN apt-get install -y apt-utils x11-apps build-essential libx11-dev git csh  libhdf5-openmpi-dev csh xutils-dev ncompress fftw3-dev libatlas-base-dev libcairo2-dev libnetpbm10-dev netpbm libpng-dev libjpeg-dev zlib1g-dev libbz2-dev swig libcfitsio-dev pkg-config gcc make perl flex curl libcurl4-openssl-dev libreadline-dev libreadline6-dev libtinfo-dev bash-completion

#sextractor (2.19.5+dfsg-6)
RUN apt install sextractor

#python3 (used in astrometry.net), Use a fake python3 because it was installed automatically in the step 'common libraries and tools'
RUN mv /usr/bin/python3  /usr/bin/python3_real
RUN ln -s /usr/bin/python /usr/bin/python3

#astrometry.net (version 0.80)
RUN mkdir -p /root/Downloads && \ 
    cd /root/Downloads && \ 
    git clone https://github.com/dstndstn/astrometry.net.git  && \       
    cd astrometry.net && \
    git checkout 744be0ed1453ac9017909fdfafb7f4eddd785812 
    
RUN cd /root/Downloads/astrometry.net && \
    make && \ 
    make py && \
    make extra && \
    make install && \
    rm -fr /root/Downloads && \
    echo '#astrometry.net' >> ~/.bashrc && \
    echo 'PATH=$PATH:/usr/local/astrometry/bin' >> ~/.bashrc
    
        
#IRAF (2.17)
RUN mkdir /iraf && \
    cd /iraf && \
    git clone https://github.com/iraf-community/iraf.git && \  
    cd iraf  && \
    echo '\n \n \n \n yes' | ./install --system  && \
    make linux64 && make sysgen 2>&1 | tee build.log  && \
    echo '#IRAF' >> ~/.bashrc && \
    echo 'export iraf=/iraf/iraf/' >> ~/.bashrc && \ 
    echo 'PATH=$PATH:/usr/local/bin/' >> ~/.bashrc 

#Montage (6.0.0)
RUN apt install montage -y
USER lemon
RUN echo '#Montage' >> ~/.bashrc && >> ~/.bashrc && echo 'PATH=$PATH:/montage/Montage/bin' >> ~/.bashrc
RUN mkdir -p /home/lemon/data/in && mkdir -p /home/lemon/data/out

#openmpi (1.8.8) required by Montage. Default openmpi version generates an error: 'There are not enough slots available'
USER root
RUN mkdir -p /root/Downloads   && \
    cd /root/Downloads  && \
    wget https://download.open-mpi.org/release/open-mpi/v1.8/openmpi-1.8.8.tar.gz && \
    tar xvf openmpi-1.8.8.tar.gz   && \
    cd openmpi-1.8.8   && \
    sed -i 's/#define PROC_MOUNT_LINE_LEN 512/#define PROC_MOUNT_LINE_LEN (512*1024)/' opal/mca/hwloc/hwloc191/hwloc/src/topology-linux.c   && \
   ./configure --prefix=/usr/bin/ --disable-dlopen && make -j 8 && make install   && \
    ln -s /usr/bin/mProjExec  /usr/bin/mProjExecMPI && \
    rm -fr /root/Downloads


#clone lemon and install it
USER lemon
RUN git clone https://github.com/vterron/lemon.git /home/lemon/lemon
WORKDIR /home/lemon/lemon

#pre requirements
RUN pip install astropy==1.3.2  d2to1
RUN pip install absl-py==0.10.0 APLpy==1.1.1 scipy mock matplotlib prettytable==0.7.2 pyfits setuptools==40.6.3 
RUN pip install stsci.distutils==0.3.7 stsci.tools==3.4.11
RUN pip install pytest-runner==4.2 traitlets==4.3.3 pyraf==2.1.15 uncertainties unittest2==1.0.0 montage-wrapper requests subprocess32

#lemon setup
RUN python ./setup.py

# Add custom CCD-filters here. My 'V' filter is 'PV' in the fits headers
RUN echo '#lemon' >> ~/.bashrc
RUN echo 'PATH=$PATH:~/lemon' >> ~/.bashrc
RUN echo '[custom_filters]' >> ~/.lemonrc
RUN echo 'PV = V (BAADER V)' >> ~/.lemonrc
RUN echo 'PB = B (BAADER B)' >> ~/.lemonrc

#Reinstall matplotlib
USER root
RUN pip uninstall -y matplotlib
RUN apt-get remove -y python-matplotlib

USER lemon
RUN pip uninstall -y matplotlib
RUN pip install matplotlib --no-binary=matplotlib

#end of Dokerfile
