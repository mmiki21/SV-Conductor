FROM continuumio/miniconda3 as condaenv

# conda create python27
RUN conda create -n python2 python=2.7
ENV CONDA_DEFAULT_ENV python2
RUN echo "conda activate python2" >> ~/.bashrc
ENV PATH /opt/conda/envs/python2/bin:$PATH
RUN pip install --upgrade pip

SHELL ["conda", "run", "-n", "python2", "/bin/sh", "-c"]
RUN conda config --add channels conda-forge
RUN conda config --add channels defaults
RUN conda config --add channels r
RUN conda config --add channels bioconda
RUN conda install -c bioconda manta

RUN conda install -c bioconda pysam
RUN conda install -c anaconda numpy
RUN conda install -c bioconda samtools

# conda create python39
RUN conda create -n py39 python=3.9
ENV CONDA_DEFAULT_ENV py39
RUN echo "conda activate py39" >> ~/.bashrc
ENV PATH /opt/conda/envs/py39/bin:$PATH
RUN pip install --upgrade pip

# install conda package
SHELL ["conda", "run", "-n", "py39", "/bin/sh", "-c"]
RUN conda config --add channels conda-forge
RUN conda config --add channels defaults
RUN conda config --add channels r
RUN conda config --add channels bioconda
RUN conda install pindel
RUN conda install imsindel
RUN conda install svaba
RUN conda install tiddit
RUN conda install svdb
RUN conda install bcftools
RUN conda install mobster
RUN conda install git
RUN git clone --recursive https://github.com/ylab-hi/ScanITD

RUN conda install -c bioconda pysam
RUN conda install -c anaconda pandas
RUN conda install -c bioconda pyvcf
RUN conda install -c anaconda typing
RUN conda install -c anaconda scikit-learn
RUN conda install -c anaconda scipy
RUN conda install -c anaconda urllib3
RUN conda install -c conda-forge gzip
RUN conda install -c conda-forge biopython
RUN conda install -c anaconda more-itertools
RUN conda install -c conda-forge intervaltree
RUN conda install -c conda-forge pkgutil-resolve-name
RUN conda install -c anaconda click
RUN conda install -c anaconda scikit-bio
RUN conda install -c anaconda numpy
RUN conda install -c bioconda samtools

RUN pip install pyfaidx

# use the ubuntu base image
FROM ubuntu:20.04

RUN timezone

# install required packages
RUN apt update && apt install -y \
    automake \
    autoconf \
    build-essential \
    binutils \
    cmake \
    g++ \
    gfortran \
    git \
    libcurl4-gnutls-dev \
    hdf5-tools \
    libboost-date-time-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
    libopenblas-base \
    libopenblas-dev \
    libncurses5-dev \
    libbz2-dev \
    libdeflate-dev \
    libhdf5-dev \
    libnss-sss \
    libncurses-dev \
    liblzma-dev \
    tzdata \
    wget \
    zlib1g-dev \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# install delly
RUN cd /opt \
    && git clone --recursive https://github.com/dellytools/delly.git \
    && cd /opt/delly/ \
    && make STATIC=1 PARALLEL=1 all \
    && make install

# Multi-stage build
COPY --from=condaenv /opt/conda /opt/conda
COPY --from=condaenv /opt/conda/envs/python2 /opt/conda/envs/python2
COPY --from=condaenv /ScanITD /opt/ScanITD
COPY CollectInsertSizeMetrics.jar /opt/CollectInsertSizeMetrics.jar
COPY Viola-SV /opt/Viola-SV

# Add Delly to PATH
ENV PATH="/opt/delly/bin:${PATH}"
ENV PATH="/opt/conda/envs/python2/bin:${PATH}"
ENV PATH="/opt/conda/envs/py39/bin:${PATH}"
ENV PATH="/opt/ScanITD:${PATH}"
ENV PATH="/opt/Viola-SV/src/viola:${PATH}"

# Set OpenMP threads
ENV OMP_NUM_THREADS 20

# by default /bin/sh is executed
CMD ["/bin/sh"]
