FROM debian:jessie

#add lemon user
RUN useradd -ms /bin/bash lemon

#initial repo update
RUN apt-get -y update

#basic tools
RUN apt-get install -y wget vim git csh

#python tools
RUN apt-get install -y python-gtk2-dev python-pip python-matplotlib python-scipy python-numpy python-pyfits python-dev

#common libraries and tools
RUN apt-get install -y libopenmpi-dev apt-utils x11-apps build-essential checkinstall python libx11-dev git csh  openmpi-bin libhdf5-openmpi-dev csh xutils-dev ncompress fftw3-dev libatlas-base-dev libcairo2-dev libnetpbm10-dev netpbm libpng12-dev libjpeg-dev zlib1g-dev libbz2-dev swig libcfitsio-dev pkg-config gcc make perl flex curl ibcurl4-openssl-dev libreadline-dev libreadline6-dev libtinfo-dev bash-completion

#update 
RUN apt-get -y upgrade

#sextractor
RUN apt install sextractor

#astrometry.net
RUN mkdir -p /root/Downloads && \ 
    cd /root/Downloads && \ 
    wget http://astrometry.net/downloads/astrometry.net-0.76.tar.gz  && \ 
    tar xvf astrometry.net-0.76.tar.gz && \ 
    cd astrometry.net-0.76 && \
    make && \
    make py && \
    make extra && \
    make install  && \
    echo 'PATH=$PATH:/usr/local/astrometry/bin' >> ~/.bashrc
    
#IRAF
RUN mkdir /iraf
RUN git clone https://github.com/iraf-community/iraf.git 
RUN cd /iraf && echo '\n \n \n \n yes' | ./install --system 
RUN make linux64 && make sysgen 2>&1 | tee build.log 
RUN echo 'export iraf=/iraf/iraf/' >> ~/.bashrc 
RUN echo 'PATH=$PATH:/usr/local/bin/' >> ~/.bashrc 

#Montage
WORKDIR /montage
RUN git clone https://github.com/dokeeffe/Montage.git
WORKDIR /montage/Montage
RUN sed -i "s|# MPICC  =	mpicc|MPICC  =	mpicc |g" Montage/Makefile.LINUX
RUN sed -i "s|# BINS = 	|BINS =  |g" Montage/Makefile.LINUX
RUN make 
USER lemon
RUN echo 'PATH=$PATH:/montage/Montage/bin' >> ~/.bashrc

# clone lemon and install (using lemon user)
USER root
RUN git clone https://github.com/vterron/lemon.git /home/lemon/lemon
WORKDIR /home/lemon/lemon
#pre requirements
RUN pip install astropy==1.3.2  d2to1
RUN pip install absl-py==0.10.0 APLpy==1.1.1 scipy matplotlib mock prettytable==0.7.2 pyfits setuptools==40.6.3 
RUN pip install stsci.distutils==0.3.7 stsci.tools==3.4.11
RUN pip install pytest-runner==4.2 traitlets==4.3.3 pyraf==2.1.15 uncertainties unittest2==1.0.0 montage-wrapper requests subprocess32
#lemon setup
RUN python ./setup.py
# Add custom CCD-filters here. My 'V' filter is 'PV' in the fits headers
RUN echo 'PATH=$PATH:~/lemon' >> ~/.bashrc
RUN echo '[custom_filters]' >> ~/.lemonrc
RUN echo 'PV = V (BAADER V)' >> ~/.lemonrc
RUN echo 'PB = B (BAADER B)' >> ~/.lemonrc
