FROM rocker/r-ver:4.0.4

RUN apt-get update &&  apt-get install -y --no-install-recommends \
        gnupg2 \
        libcurl4-openssl-dev \
        libsodium-dev \
        libssl-dev \
        libv8-dev \
        libxml2-dev \
        valgrind \
        wget \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Without this, we are unable to pick up more recent packages
COPY docker/Rprofile.site /usr/local/lib/R/etc/Rprofile.site

RUN install2.r --error \
        --repos https://mrc-ide.github.io/drat/ \
        --repos https://cloud.r-project.org \
        odin \
        odin.js \
        porcelain

COPY . /src
RUN R CMD INSTALL --install-tests /src && rm -rf /src

RUN Rscript -e 'odin.api:::write_script("/usr/local/bin")'

ENTRYPOINT ["/usr/local/bin/odin.api"]
