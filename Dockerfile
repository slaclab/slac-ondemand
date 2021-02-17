FROM docker.io/centos:7
#FROM centos:centos7

# setup slurm
# shoudl probably user a docker builder AS or something rather than doing again here... perhaps from the slurm image?
ARG MUNGEUSER=891
ARG SLURMUSER=16924
ARG SLURMGROUP=1034

RUN groupadd -g $MUNGEUSER munge \
    && useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge \
    && groupadd -g $SLURMGROUP slurm \
    && useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm

# httpd24-mod_ssl httpd24-mod_ldap \
RUN set -xe \
    && yum makecache fast \
    && yum -y update \
    && yum -y install epel-release centos-release-scl wget \
    && wget https://turbovnc.org/pmwiki/uploads/Downloads/TurboVNC.repo -O /etc/yum.repos.d/TurboVNC.repo \
    && wget http://download.opensuse.org/repositories/security://shibboleth/CentOS_7/security:shibboleth.repo -O /etc/yum.repos.d/shibboleth.repo \
    && yum -y update \
    && yum install -y \
        shibboleth \
        munge \
        openssh-server openssh-clients \
        sudo \
        python-setuptools sssd nss-pam-ldapd \
        tcsh \
    && yum -y install turbovnc \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && easy_install supervisor \
    && chmod ugo+x /etc/shibboleth/shibd-redhat && mkdir -p /var/run/shibboleth /var/run/shibboleth && chown shibd:shibd /var/run/shibboleth /var/run/shibboleth

# setup sssd
#COPY sssd/nsswitch.conf sssd/nslcd.conf /etc/
COPY sssd/nsswitch.conf /etc/
COPY sssd/sssd.conf /etc/sssd/sssd.conf
RUN chmod 600 /etc/sssd/sssd.conf

# shib logging
COPY etc/shibboleth/shibd.logger /etc/shibboleth
COPY etc/shibboleth/native.logger /etc/shibboleth

# setup tini
ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini /usr/sbin/tini
RUN chmod +x /usr/sbin/tini

# envs
#ENV MUNGE_ARGS=''
ENV PATH=/opt/TurboVNC/bin/:${PATH}

# oidc
RUN yum install -y https://yum.osc.edu/ondemand/latest/ondemand-release-web-1.8-1.noarch.rpm \
    && yum install --nogpgcheck -y ondemand httpd24-mod_auth_openidc \
    && ln -sf /etc/ood/config/portal/ood_portal.yml /etc/ood/config/ood_portal.yml \
    && mkdir -p /etc/ood/config/portal \
       /etc/ood/config/clusters.d \
       /etc/ood/config/htpasswd/ \
       /etc/ood/config/apps/shell \
       /etc/ood/config/apps/bc_desktop \
    && cp /etc/httpd/conf.d/shib.conf /opt/rh/httpd24/root/etc/httpd/conf.d/10-auth_shib.conf 

# copy over exe's
COPY docker-entrypoint.sh supervisord-eventlistener.sh ondemand.sh supervisord.conf /

# slrm paths
RUN mkdir /var/spool/slurmd /var/run/slurmd /var/lib/slurmd /var/log/slurm \
    && chown slurm:root /var/spool/slurmd /var/run/slurmd /var/lib/slurmd /var/log/slurm 
ENV PATH=/opt/slurm/bin:${PATH}

# copy apps
ENV SLAC_SDF_DOCS_VERSION=master
ENV SLAC_SDF_DOCS_PATH=/var/www/ood/public/doc/
RUN git clone https://github.com/slaclab/sdf-docs.git $SLAC_SDF_DOCS_PATH \
  && cd $SLAC_SDF_DOCS_PATH \
  && git checkout $SLAC_SDF_DOCS_VERSION && ls $SLAC_SDF_DOCS_PATH

ENV SLAC_OOD_JUPYTER_VERSION=master
ENV SLAC_OOD_JUPYTER_PATH=/var/www/ood/apps/sys/slac-ood-jupyter
RUN git clone https://github.com/slaclab/slac-ood-jupyter.git $SLAC_OOD_JUPYTER_PATH \
  && cd $SLAC_OOD_JUPYTER_PATH \
  && git checkout $SLAC_OOD_JUPYTER_VERSION

ENV SLAC_OOD_DESKTOP_VERSION=master
ENV SLAC_OOD_DESKTOP_PATH=/var/www/ood/apps/sys/bc_desktop
RUN rm -rf $SLAC_OOD_DESKTOP_PATH && git clone https://github.com/slaclab/slac-ood-desktop.git $SLAC_OOD_DESKTOP_PATH \
  && cd $SLAC_OOD_DESKTOP_PATH \
  && git checkout $SLAC_OOD_DESKTOP_VERSION

#ENV SLAC_OOD_MATLAB_VERSION=master
#ENV SLAC_OOD_MATLAB_PATH=/var/www/ood/apps/sys/slac-ood-matlab
#RUN git clone https://github.com/slaclab/slac-ood-matlab.git $SLAC_OOD_MATLAB_PATH \
#  && cd $SLAC_OOD_MATLAB_PATH \
#  && git checkout $SLAC_OOD_MATLAB_VERSION

ENV SLAC_OOD_CRYOSPARC_VERSION=master
ENV SLAC_OOD_CRYOSPARC_PATH=/var/www/ood/apps/sys/slac-ood-cryosparc
RUN git clone https://github.com/slaclab/slac-ood-cryosparc.git $SLAC_OOD_CRYOSPARC_PATH \
  && cd $SLAC_OOD_CRYOSPARC_PATH \
  && git checkout $SLAC_OOD_CRYOSPARC_VERSION

# start
ENTRYPOINT ["/usr/sbin/tini", "--", "/docker-entrypoint.sh"]
