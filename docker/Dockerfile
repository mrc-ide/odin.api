FROM rocker/r-ver:4.4.3

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
        --repos=https://packagemanager.rstudio.com/all/__linux__/noble/latest \
        docopt \
        jsonlite \
        logr \
        later \
        fastmap \
        otel \
        ps \
        Rcpp \
        curl \
        crayon \
        httpuv \
        lifecycle \
        magrittr \
        mime \
        promises \
        rlang \
        sodium


RUN install2.r --error \
        --repos=https://mrc-ide.github.io/drat \
        --repos=https://packagemanager.rstudio.com/all/__linux__/noble/latest \
        stringi \
        swagger \
        webutils \
        common \
        withr \
        R6 \
        cinterpolate \
        deSolve \
        digest \
        glue \
        ring \
        callr \
        cli \
        desc \
        processx

RUN install2.r --error \
        --repos=https://mrc-ide.github.io/drat \
        --repos=https://packagemanager.rstudio.com/all/__linux__/noble/latest \
        odin \
        pkgbuild

RUN install2.r --error \
        --repos=https://mrc-ide.github.io/drat \
        --repos=https://packagemanager.rstudio.com/all/__linux__/noble/latest \
        porcelain

RUN install2.r --error \
        remotes

RUN installGithub.r mrc-ide/odin2@9b03ddb

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
