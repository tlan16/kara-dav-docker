# README

This is a Docker image that uses https://github.com/crazywhalecc/static-php-cli and https://github.com/kd2org/karadav to create a owncloud compatible api interface. 

Tested using Swiftbackup on Android 16.

---

## Disgn goal

Minimize Docker image size. At the time of writting, the Docker image size is 6 MB (6324360 bytes). 


## Motivation

When using a out-of-box php base image, to run a tiny code base like karadav still easily result in a Dockerfile sized around 200MB. 

I consider this a waste of resource.
