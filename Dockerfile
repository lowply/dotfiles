FROM amazonlinux:latest
MAINTAINER Sho Mizutani <lowply@gmail.com>
RUN yum install -y sudo util-linux shadow-utils tar gzip python3 python3-devel gcc gcc-c++ cmake make golang git
RUN rpm -i https://packagecloud.io/github/git-lfs/packages/el/8/git-lfs-2.9.0-1.el8.x86_64.rpm/download
RUN curl -sL https://rpm.nodesource.com/setup_12.x | bash - && yum install -y nodejs
RUN curl -sL https://github.com/neovim/neovim/releases/download/v0.3.8/nvim-linux64.tar.gz -o - | tar vxz -C /usr/local
RUN ln -s /usr/local/nvim-linux64/bin/nvim /usr/local/bin/
RUN ln -s /usr/share/git-core/contrib/diff-highlight /usr/local/bin/
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
RUN useradd lowply -g wheel -d /home/lowply
WORKDIR /home/lowply
COPY . dotfiles
RUN chown -R lowply:wheel dotfiles
USER lowply
RUN pip3 install --user pynvim
RUN ./dotfiles/install do

# Note that cpsm fails to build during PlugInstall.
# It requires Boost (see https://github.com/nixprime/cpsm), but Boost in the AL yum repository is too old (1.53) and lacks CXX14 algorithm package.
# CXX14 is available in Boost 1.70, but building it from the tarball takes really long time and that's not what this Docker image should do.
