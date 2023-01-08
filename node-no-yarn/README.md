[![dockeri.co](https://dockeri.co/image/creemama/node-no-yarn)](https://hub.docker.com/r/creemama/node-no-yarn)

# Supported tags and respective `Dockerfile` links

- [`18.13.0-alpine3.17`,`lts-alpine`](https://github.com/creemama/docker/blob/node-no-yarn-18.13.0-alpine3.17/node-no-yarn/18/alpine3.17/Dockerfile)

# A Node.js Docker image without Yarn

All of the
[Docker official images of Node.js](https://hub.docker.com/_/node/?tab=description)
contain pre-installed versions of [`node`](http://nodejs.org),
[`npm`](https://www.npmjs.com/), and [`yarn`](https://yarnpkg.com/).

Simply put, the images here do not contain pre-installed versions of Yarn.

The `Dockerfile`s used to build the images are the exact same as the offical
`Dockerfile`s except, as you guessed, we deleted the Yarn part.

| Image                                    |  Size |
| ---------------------------------------- | ----: |
| creemama/node-no-yarn:18.13.0-alpine3.17 | 163MB |
| node:18.13.0-alpine3.17                  | 171MB |

# Example

```sh
docker run --rm creemama/node-no-yarn:lts-alpine -e "console.log(process.version)"
```
