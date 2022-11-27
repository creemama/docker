FROM creemama/node-no-yarn:18.12.1-alpine3.16

# ncurses has tput in Alpine Linux.

RUN apk add --no-cache git~=2.36 gnupg~=2.2 openssh~=9.0 \
    && apk add --no-cache git-gitk~=2.36 terminus-font~=4.49 \
    && apk add --no-cache shellcheck~=0.8 \
    && apk add --no-cache shfmt~=3.5 \
    && apk add --no-cache ncurses~=6.3 \
    && npm install --global prettier@2.8.0
