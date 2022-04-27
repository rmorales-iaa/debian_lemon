docker-lemon is a docker image which makes it easy to run [LEMON, the differential photometry pipeline](https://github.com/vterron/lemon)

## Building the image (just once)

`sudo docker build -t local_repo:debian_buster_lemon .`

## docker script to run lemmon commads

There is a docker script to run lemon commands in the repo:[lemon_docker](https://github.com/rmorales-iaa/debian_lemon/blob/master/lemon_docker)

There is a docker image with docker deployed [lemon_docker_image](https://hub.docker.com/repository/docker/rmoralesiaa/debian)

Please review the scritp to adapt properly the shared directories between host and container.

Running the photometry command using docker script generates an error loading the FITS files, so it is necesary to go inside the container


## Example of running lemon astrometry using docker script
#start the container in the image

`./lemon_docker`

`lemon astrometry --radius=0.5 /home/lemon/data/in/*.fits /home/lemon/data/out`


## Example of running lemon mosaic using docker script
#start the container in the image

`./lemon_docker` 

`lemon mosaic /home/lemon/data/in/*.fits /home/lemon/data/out/mosaic.fits`

## Example of running lemon photometry using docker script
#start the container in the image

`./lemon_docker`

`lemon photometry ~/data/in/science_HAT-P-16-001Rbfa_OSN_1_5_2014_10_31T19_59_01_140_JOHNSON_R_30s_2048x2048_roper_OBJECT.fits  ~/data/in/*.fits ~/data/out/phot.LEMONdB`

`lemon diffphot ~/data/out/phot.LEMONdB ~/data/out/curves.LEMONdB`

#lemon juicer it a GUI, so it must be run outside of container using the docker script

`./lemon_docker "/home/lemon/lemon/lemon juicer /home/lemon/data/out/curves.LEMONdB"`

![screenshot](https://raw.githubusercontent.com/dokeeffe/docker-lemon/master/docs/juicer-screenshot.png)

