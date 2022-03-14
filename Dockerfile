FROM enthought/edm-centos-7

WORKDIR /app
ENV EDM_ROOT_DIRECTORY=/app/edm

COPY . .
RUN edm env import -f vpsearch_py3.8_rh7-x86_64.json vpsearch-env && \
    edm cache purge --all -y

RUN yum -y install gcc gcc-c++ && \
    edm run -e vpsearch-env -- pip install --no-deps . -v && \
    yum -y remove gcc gcc-c++ && \
    yum clean all

ENTRYPOINT ["edm", "run", "-e", "vpsearch-env", "--"]
