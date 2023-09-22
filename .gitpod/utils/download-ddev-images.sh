#!/bin/bash

# Get the list of images using 'docker images' and filter out the header
images=$(docker images | awk 'NR>1 {print $1":"$2}')

# Loop through each image and pull it
for image in $images
do
    docker pull "$image"
done

