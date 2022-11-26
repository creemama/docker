FROM creemama/node-no-yarn:16.13.0-alpine3.14

RUN apk add --no-cache git~=2.32 gnupg~=2.2 openssh~=8.6 \
    && apk add --no-cache git-gitk~=2.32 terminus-font~=4.49 \
    && apk add --no-cache shellcheck~=0.7 \
    && apk add --no-cache shfmt~=3.3 \
    && npm install --global prettier@2.8.0
