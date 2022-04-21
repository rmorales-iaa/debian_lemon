docker-lemon is a docker image which makes it easy to run [LEMON, the differential photometry pipeline](https://github.com/vterron/lemon)

## Building the image (just once)

`sudo docker build -t debian:lemon .`

## Starting a container with the image
`sudo docker run -it debian:lemon`

Assuming you have fits files in ~/Pictures on your PC, the following command will make them available at /data in the container

`docker run -v ~/Pictures:/data -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=unix$DISPLAY -it lemondoc bash`

## Reducing fits files

`lemon astrometry data/in/ data/out/`

### Running mosaic

An example of running against all fits files in 'data/in' dir over file 'a.fits'

`lemon mosaic data/in/*.fits data/out/a.fits`

### Run photometry

`lemon photometry main_fits /dir/*.fits data/out/phot.LEMONdB`

### Create the differential photometry data

This command will take data from the phot.LEMONdB and create a new database called curves.LEMONdB

`lemon diffphot data/out/phot.LEMONdB data/out/curves.LEMONdB`

### Run the jucier browser app

`lemon juicer data/out/curves.LEMONdB`

![screenshot](https://raw.githubusercontent.com/dokeeffe/docker-lemon/master/docs/juicer-screenshot.png)

