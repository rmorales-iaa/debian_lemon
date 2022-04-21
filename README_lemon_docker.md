## docker script to run lemmon commads

There is a docker script to run lemon commands in the repo:[lemon_docker](https://github.com/rmorales-iaa/debian_lemon/blob/master/lemon_docker)

There is a docker image with docker deployed [lemon_docker_image](https://FIXME)

Please review the scritp to adapt properly the shared directories between host and container.

The dependences required by lemon are too old (2017 or older) and some lemon commands does not work, only: photometry, diffphot and juicer
This means that the user must solve the astrometry and align the images without lemon help

## Example of running lemon photometry using docker script
#start the container in the image

`./lemon_docker bash`

#running the command from docker script generates an error loading the FITS files, so it is necesary to go inside the container

`su lemon

lemon photometry ~/data/in/science_HAT-P-16-001Rbfa_OSN_1_5_2014_10_31T19_59_01_140_JOHNSON_R_30s_2048x2048_roper_OBJECT.fits  ~/data/in/*.fits ~/data/out/phot.LEMONdB

lemon diffphot ~/data/out/phot.LEMONdB ~/data/out/curves.LEMONdB

exit

exit`

#lemon juicer must be run outside of container using the docker script
`./lemon_docker "/home/lemon/lemon/lemon juicer /home/lemon/data/out/curves.LEMONdB"`
