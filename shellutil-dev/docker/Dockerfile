FROM node:24.21.0-alpine3.24

# ncurses has tput in Alpine Linux.

RUN apk add --no-cache git~=2.54 gnupg~=2.4 openssh~=10.3 \
    && apk add --no-cache git-gitk~=2.54 font-terminus~=4.49 \
    && apk add --no-cache shellcheck~=0.11 \
    && apk add --no-cache shfmt~=3.13 \
    && apk add --no-cache ncurses~=6.6 \
    && npm install --global prettier@3.9.8
