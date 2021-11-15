FROM rocker/r-ver:4.1.2

RUN apt-get update &&  apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        libssl-dev \
        libv8-dev \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Without this, we are unable to pick up more recent packages
COPY docker/Rprofile.site /usr/local/lib/R/etc/Rprofile.site

# More cache-friendly installation of some dependencies:
RUN install2.r --error \
        --repos=https://mrc-ide.github.io/drat \
        --repos=https://packagemanager.rstudio.com/all/__linux__/focal/latest \
        jsonlite \
        odin \
        pkgbuild \
        porcelain

COPY DESCRIPTION /tmp/DESCRIPTION

# Then get the full list via remotes
RUN install2.r --error remotes &&  \
        Rscript -e 'remotes::install_deps("/tmp")'

EXPOSE 8001

COPY . /src
RUN R CMD INSTALL --install-tests /src && \
        cp /src/docker/odin_api /usr/local/bin && \
        rm -rf /src

ENTRYPOINT ["/usr/local/bin/odin_api"]
