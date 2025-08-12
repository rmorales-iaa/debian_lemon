#start of Dokerfile
#docker for run lemon (https://github.com/vterron/lemon) using debian 'buster'

#set the image base
FROM debian:buster-slim

#add lemon user
RUN useradd -ms /bin/bash lemon 

#initial repo update
RUN apt-get -y update# Dockerfile for running lemon[](https://github.com/vterron/lemon) using Debian Buster

# Set the image base (using slim variant for smaller size)
FROM debian:buster-slim

# Update apt sources to use archive.debian.org and add security archive
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i '/buster-updates/d' /etc/apt/sources.list && \
    sed -i '/buster\/updates/d' /etc/apt/sources.list && \
    echo 'deb http://archive.debian.org/debian-security buster/updates main' >> /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

# Add non-root user:
#match with the UID/GID of the user $USERNAME
ARG USERNAME
ARG UID
ARG GID
RUN groupadd -g "${GID}" "${USERNAME}" && \
    useradd -m -u "${UID}" -g "${GID}" -s /bin/bash "${USERNAME}"
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# Update package lists
RUN apt-get update -y && apt-get upgrade -y

# Install core system packages
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    wget vim git csh curl apt-utils x11-apps \
    gcc make perl flex pkg-config bash-completion && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python and related packages with all dependencies
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends --allow-downgrades --allow-change-held-packages \
    python python-pip python-numpy python-scipy python-matplotlib \
    python-dev libpython-dev python2.7-dev python2-dev libpython2.7-dev libexpat1-dev \
    python-gtk2-dev libglib2.0-dev libgtk2.0-dev python-gobject-2-dev \
    libmount-dev libpcre3-dev libselinux1-dev zlib1g-dev=1:1.2.11.dfsg-1+deb10u2 \
    libgdk-pixbuf2.0-dev libpango1.0-dev libcairo2-dev \
    libfontconfig1-dev libfreetype6-dev libc6-dev libblkid-dev libharfbuzz-dev libxft-dev && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install development libraries
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    build-essential libx11-dev xutils-dev ncompress fftw3-dev libatlas-base-dev \
    libcairo2-dev libnetpbm10-dev netpbm libpng-dev libjpeg62-turbo-dev \
    zlib1g-dev libbz2-dev swig libcfitsio-dev libcurl4-openssl-dev \
    libreadline-dev libtinfo-dev libhdf5-openmpi-dev sextractor montage && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install pip for Python 2.7 using the official bootstrap script
RUN mkdir /tmp/Downloads && \
    cd /tmp/Downloads && \
    curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py && \
    python get-pip.py && \
    rm -rf /tmp/Downloads

# Install required Python packages for lemon and dependencies
RUN pip install --no-cache-dir \
    pyfits astropy==1.3.2 d2to1 absl-py==0.10.0 APLpy==1.1.1 \
    scipy mock matplotlib prettytable==0.7.2 setuptools==40.6.3 \
    stsci.distutils==0.3.7 stsci.tools==3.4.11 pytest-runner==4.2 \
    traitlets==4.3.3 pyraf==2.1.15 uncertainties unittest2==1.0.0 \
    montage-wrapper requests subprocess32

# Create a fake Python 3 symlink to Python 2.7 (hack for software expecting Python 3)
RUN mv /usr/bin/python3 /usr/bin/python3_real 2>/dev/null || true && \
    ln -s /usr/bin/python /usr/bin/python3

# Install Astrometry.net from source (specific commit for version 0.80)
RUN mkdir -p /tmp/Downloads && \
    cd /tmp/Downloads && \
    git clone https://github.com/dstndstn/astrometry.net.git && \
    cd astrometry.net && \
    git checkout 744be0ed1453ac9017909fdfafb7f4eddd785812 && \
    make && make py && make extra && make install && \
    rm -rf /tmp/Downloads

# Install IRAF from source (version 2.17)
RUN mkdir /iraf && \
    cd /iraf && \
    git clone https://github.com/iraf-community/iraf.git && \
    cd iraf && \
    git checkout v2.17 && \
    chmod +x install && \
    echo '\n \n \n \n yes' | ./install --system && \
    make linux64 && \
    make sysgen 2>&1 | tee build.log

# Install OpenMPI 1.8.8 from source with patch
RUN mkdir -p /tmp/Downloads && \
    cd /tmp/Downloads && \
    wget https://download.open-mpi.org/release/open-mpi/v1.8/openmpi-1.8.8.tar.gz && \
    tar xvf openmpi-1.8.8.tar.gz && \
    cd openmpi-1.8.8 && \
    sed -i 's/#define PROC_MOUNT_LINE_LEN 512/#define PROC_MOUNT_LINE_LEN (512*1024)/' opal/mca/hwloc/hwloc191/hwloc/src/topology-linux.c && \
    ./configure --prefix=/usr --disable-dlopen && \
    make -j8 && make install && \
    ln -s /usr/bin/mProjExec /usr/bin/mProjExecMPI && \
    rm -rf /tmp/Downloads

# Switch to non-root user '${USERNAME}'
USER "${USERNAME}"

# Set up data directories
RUN mkdir -p /home/"${USERNAME}"/data/in /home/"${USERNAME}"/data/out

# Clone the lemon repository
RUN git clone https://github.com/vterron/lemon.git /home/"${USERNAME}"/lemon

# Set working directory to lemon
WORKDIR /home/"${USERNAME}"/lemon

# Install lemon using setup.py with --user flag
RUN python setup.py install --user

# Configure environment variables and PATH in .bashrc
RUN echo '# astrometry.net\nPATH=$PATH:/usr/local/astrometry/bin\n' >> ~/.bashrc && \
    echo '# IRAF\nexport iraf=/iraf/iraf/\nPATH=$PATH:/usr/local/bin/\n' >> ~/.bashrc && \
    echo '# Montage\nPATH=$PATH:/usr/bin\n' >> ~/.bashrc && \
    echo '# lemon\nPATH=$PATH:~/lemon:~/.local/bin\n' >> ~/.bashrc

# Add custom filters to .lemonrc
RUN echo '[custom_filters]\nPV = V (BAADER V)\nPB = B (BAADER B)' >> ~/.lemonrc

# Switch back to root to uninstall system-wide matplotlib
USER root

# Set system hostname to "docker"
RUN echo "docker" > /etc/hostname

# Uninstall system-wide matplotlib
RUN pip uninstall -y matplotlib || true && \
    apt-get purge -y python-matplotlib || true && \
    apt-get autoremove -y

# Switch back to user
USER "${USERNAME}"

# Uninstall user-installed matplotlib and reinstall from source
RUN pip uninstall -y matplotlib || true && \
    pip install matplotlib --no-binary=matplotlib --user



#basic tools
RUN apt-get install -y wget vim git csh curl

#install python
RUN apt install -y python 

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

RUN echo '#astrometry.net' >> ~/.bashrc && \
    echo 'PATH=$PATH:/usr/local/astrometry/bin' >> ~/.bashrc

RUN echo '#IRAF' >> ~/.bashrc && \
    echo 'export iraf=/iraf/iraf/' >> ~/.bashrc && \ 
    echo 'PATH=$PATH:/usr/local/bin/' >> ~/.bashrc 
    

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
