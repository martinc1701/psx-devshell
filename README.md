# PSX Devshell Docker Image

This Dockerfile create a development environment for PSX application development.
The environment contains a working GCC 12 C/C++ cross-compiler and a pre-compiled
copy of [libpsn00b](https://github.com/Lameguy64/PSn00bSDK/tree/v0.19).

The `run` script will build (with `-b`) and run the docker image. The
current working directory will be mounted to `/opt/src`. Start a new project like
so:
```bash
cp -R /usr/local/share/psn00bsdk/template .
cmake --preset default .
cmake --build ./build/
```
See https://github.com/Lameguy64/PSn00bSDK/blob/v0.19/doc/installation.md#creating-a-project
for more details.