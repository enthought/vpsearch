FROM enthought/edm-centos-7

WORKDIR /src
COPY vpsearch_py3.6_rh6-x86_64.json ./
RUN edm env import -f vpsearch_py3.6_rh6-x86_64.json vpsearch-env && \
    edm cache purge --all -y

COPY . .

RUN yum -y install gcc gcc-c++ && \
    edm run -e vpsearch-env -- pip install --no-deps . -v && \
    yum -y remove gcc gcc-c++ && \
    yum clean all

ENTRYPOINT ["edm", "run", "-e", "vpsearch-env", "--"]
