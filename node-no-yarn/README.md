[![dockeri.co](https://dockeri.co/image/creemama/node-no-yarn)](https://hub.docker.com/r/creemama/node-no-yarn)

# Supported tags and respective `Dockerfile` links

- [`12.19.0-alpine3.12` _(12/alpine/Dockerfile)_](https://github.com/creemama/docker/blob/node-no-yarn-12.19.0-alpine3.12/node-no-yarn/12/alpine3.12/Dockerfile)

# A Node.js Docker image without Yarn

All of the
[Docker official images of Node.js](https://hub.docker.com/_/node/?tab=description)
contain pre-installed versions of [`node`](http://nodejs.org),
[`npm`](https://www.npmjs.com/), and [`yarn`](https://yarnpkg.com/).

Simply put, the images here do not contain pre-installed versions of Yarn.

The `Dockerfile`s used to build the images are the exact same as the offical
`Dockerfile`s except, as you guessed, we deleted the Yarn part.

| Image                                    |   Size |
| ---------------------------------------- | -----: |
| creemama/node-no-yarn:12.19.0-alpine3.12 | 82.2MB |
| node:12.19.0-alpine3.12                  |   90MB |

# Example

```sh
docker run --rm creemama/node-no-yarn:12.19.0-alpine3.12 -e "console.log(process.version)"
```

[comment]: # "Build this image locally by executing the following:"
[comment]: # "$ cd node-no-yarn/12/alpine3.12"
[comment]: # "$ docker build --tag creemama/node-no-yarn:12.19.0-alpine3.12 ."
[comment]: # "Get images sizes by executing the following:"
[comment]: # "$ docker pull docker pull node:12.19.0-alpine3.12 # Pull the correct node version."
[comment]: # "$ docker images"
[comment]: # "Prettify this Markdown file by executing the following:"
[comment]: # "$ docker run -it --rm --volume $(pwd):/tmp --workdir /tmp creemama/node-no-yarn:12.19.0-alpine3.12 sh -c 'npm install -g prettier@2.1.2 && prettier -w README.md'"
