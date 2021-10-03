# Build dependencies for cpsm. Ref: https://github.com/nixprime/cpsm#requirements
FROM ubuntu:20.04 AS cpsm
WORKDIR /tmp
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get install -y git libboost-all-dev cmake python-dev libicu-dev build-essential
RUN git clone https://github.com/nixprime/cpsm.git
RUN PY3=ON cpsm/install.sh

FROM node:16-slim AS prettier
WORKDIR /tmp
RUN apt-get update && apt-get install -y git
RUN git clone https://github.com/prettier/vim-prettier.git
RUN cd vim-prettier && yarn install

FROM ubuntu:20.04
RUN apt-get update
# To install the latest Git. Ref: https://git-scm.com/download/linux
RUN apt-get -y install software-properties-common && add-apt-repository -y ppa:git-core/ppa && apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata
RUN apt-get -y install sudo make vim git curl locales
RUN locale-gen en_US.UTF-8 && dpkg-reconfigure --frontend noninteractive locales

RUN useradd lowply -m -d /home/lowply -g users
RUN echo "lowply ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/lowply
RUN chmod 440 /etc/sudoers.d/lowply

WORKDIR /home/lowply
COPY . dotfiles
COPY --from=cpsm /tmp/cpsm /home/lowply/.vim/plugged/cpsm
COPY --from=prettier /tmp/vim-prettier /home/lowply/.vim/plugged/vim-prettier
RUN chown -R lowply:users dotfiles .vim
USER lowply
RUN ./dotfiles/install.sh
ENTRYPOINT bash
