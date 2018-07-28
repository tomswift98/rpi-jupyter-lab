# This file creates a container that runs a jupyter notebook server on Raspberry Pi
#
# Author: Dmitrii Gerasimenko
# Date 28/07/2018
#
# Originally from: https://github.com/mkjiang/rpi-jupyter/blob/master/Dockerfile
#

FROM resin/rpi-raspbian:jessie
MAINTAINER Dmitry Gerasimenko <kiddima@gmail.com>

# Set the variables
ENV DEBIAN_FRONTEND noninteractive
ENV PYTHON_VERSION 3.6.6

WORKDIR /root

# Install packages necessary for compiling python
RUN apt-get update && apt-get upgrade && apt-get install -y \
        build-essential \
        libncursesw5-dev \
        libgdbm-dev \
        libc6-dev \
        zlib1g-dev \
        libsqlite3-dev \
        tk-dev \
        libssl-dev \
        openssl \
        libbz2-dev

# Download and compile python
RUN apt-get install -y ca-certificates
ADD "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz" /root/Python-${PYTHON_VERSION}.tgz
RUN tar zxvf "Python-${PYTHON_VERSION}.tgz" \
        && cd Python-${PYTHON_VERSION} \
        && ./configure \
        && make \
        && make install \
        && cd .. \
        && rm -rf "./Python-${PYTHON_VERSION}" \
        && rm "./Python-${PYTHON_VERSION}.tgz"

# Update pip and install jupyter
RUN apt-get install -y libncurses5-dev
RUN pip3 install --upgrade pip
RUN pip3 install readline jupyter


# Configure jupyter
RUN jupyter notebook --generate-config
RUN mkdir notebooks
RUN sed -i "/c.NotebookApp.open_browser/c c.NotebookApp.open_browser = False" /root/.jupyter/jupyter_notebook_config.py \
        && sed -i "/c.NotebookApp.ip/c c.NotebookApp.ip = '*'" /root/.jupyter/jupyter_notebook_config.py \
        && sed -i "/c.NotebookApp.notebook_dir/c c.NotebookApp.notebook_dir = '/root/notebooks'" /root/.jupyter/jupyter_notebook_config.py

VOLUME /root/notebooks

# Add Tini. Tini operates as a process subreaper for jupyter. This prevents kernel crashes.
ENV TINI_VERSION 0.18.0
ENV CFLAGS="-DPR_SET_CHILD_SUBREAPER=36 -DPR_GET_CHILD_SUBREAPER=37"

ADD https://github.com/krallin/tini/archive/v${TINI_VERSION}.tar.gz /root/v${TINI_VERSION}.tar.gz
RUN apt-get install -y cmake
RUN tar zxvf v${TINI_VERSION}.tar.gz \
        && cd tini-${TINI_VERSION} \
        && cmake . \
        && make \
        && cp tini /usr/bin/. \
        && cd .. \
        && rm -rf "./tini-${TINI_VERSION}" \
        && rm "./v${TINI_VERSION}.tar.gz"


# Install usefull python packages for data scientists
RUN apt-get install -y \
        libhdf5-dev \
        liblapack-dev \
        gfortran
RUN pip3 install requests numpy scipy scikit-learn nltk pandas seaborn tables matplotlib ipywidgets


ENTRYPOINT ["/usr/bin/tini", "--"]

EXPOSE 8888

CMD ["jupyter", "lab"]