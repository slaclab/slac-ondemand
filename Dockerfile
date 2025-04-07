FROM rockylinux:9

# setup slurm
# shoudl probably user a docker builder AS or something rather than doing again here... perhaps from the slurm image?
ARG MUNGEUSER=16952
ARG SLURMUSER=16924
ARG SLURMGROUP=1034

RUN groupadd -g $MUNGEUSER munge \
    && useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge \
    && groupadd -g $SLURMGROUP slurm \
    && useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm

RUN set -xe \
    && dnf install -y 'dnf-command(config-manager)' wget epel-release \ 
    && dnf config-manager --set-enabled crb \
    && dnf module enable -y ruby:3.1 nodejs:18 \
    && wget https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.repo -O /etc/yum.repos.d/TurboVNC.repo \
    && yum -y update \
    && yum install -y \
        file \
        lsof \
        supervisor \
        sssd nss-pam-ldapd \
        sudo \
        openssh-server openssh-clients \
        bash tcsh zsh \
        munge \
        lua-posix \
        rsync \
        turbovnc \
        vim openldap-clients \
    && yum clean all \
    && rm -rf /var/cache/yum 

# setup sssd
COPY etc/nsswitch.conf /etc/
COPY etc/ldap.conf /etc/openldap/ldap.conf
COPY etc/krb5.conf /etc/krb5.conf
COPY etc/sssd.conf /etc/sssd/sssd.conf
RUN chmod 600 /etc/sssd/sssd.conf

# setup tini
RUN curl -L https://github.com/krallin/tini/releases/download/v0.18.0/tini -o /usr/sbin/tini \
  && chmod +x /usr/sbin/tini

# envs
#ENV MUNGE_ARGS=''
ENV PATH=/opt/TurboVNC/bin/:${PATH}

# oidc
RUN yum install -y https://yum.osc.edu/ondemand/3.1/ondemand-release-web-3.1-1.el9.noarch.rpm \
    && yum install --nogpgcheck -y ondemand \
    && mkdir -p /etc/ood/config/portal \
       /etc/ood/config/clusters.d \
       /etc/ood/config/htpasswd/ \
       /etc/ood/config/apps/shell \
       /etc/ood/config/apps/bc_desktop 

# copy over exe's
COPY docker-entrypoint.sh supervisord-eventlistener.sh ondemand.sh supervisord.conf purgecache.sh /

# slurm paths
RUN mkdir /var/spool/slurmd /var/run/slurmd /var/lib/slurmd /var/log/slurm \
    && chown slurm:root /var/spool/slurmd /var/run/slurmd /var/lib/slurmd /var/log/slurm 
ENV PATH=/opt/slurm/bin:${PATH}

# copy apps
ENV SLAC_SDF_DOCS_VERSION=main
ENV SLAC_SDF_DOCS_PATH=/var/www/ood/public/doc/
RUN git clone https://github.com/slaclab/sdf-docs.git $SLAC_SDF_DOCS_PATH \
  && cd $SLAC_SDF_DOCS_PATH \
  && git checkout $SLAC_SDF_DOCS_VERSION && ls $SLAC_SDF_DOCS_PATH

ENV SLAC_OOD_JUPYTER_VERSION=main
ENV SLAC_OOD_JUPYTER_PATH=/var/www/ood/apps/sys/slac-ood-jupyter
RUN git clone https://github.com/slaclab/slac-ood-jupyter.git $SLAC_OOD_JUPYTER_PATH \
 && cd $SLAC_OOD_JUPYTER_PATH \
  && git checkout $SLAC_OOD_JUPYTER_VERSION

ENV SLAC_OOD_DESKTOP_VERSION=main
ENV SLAC_OOD_DESKTOP_PATH=/var/www/ood/apps/sys/bc_desktop
RUN rm -rf $SLAC_OOD_DESKTOP_PATH && git clone https://github.com/slaclab/slac-ood-desktop.git $SLAC_OOD_DESKTOP_PATH \
  && cd $SLAC_OOD_DESKTOP_PATH \
  && git checkout $SLAC_OOD_DESKTOP_VERSION

#ENV SLAC_OOD_MATLAB_VERSION=master
#ENV SLAC_OOD_MATLAB_PATH=/var/www/ood/apps/sys/slac-ood-matlab
#RUN git clone https://github.com/slaclab/slac-ood-matlab.git $SLAC_OOD_MATLAB_PATH \
#  && cd $SLAC_OOD_MATLAB_PATH \
#  && git checkout $SLAC_OOD_MATLAB_VERSION
#
ENV SLAC_OOD_CRYOSPARC_VERSION=main
ENV SLAC_OOD_CRYOSPARC_PATH=/var/www/ood/apps/sys/slac-ood-cryosparc
RUN git clone https://github.com/slaclab/slac-ood-cryosparc.git $SLAC_OOD_CRYOSPARC_PATH \
  && cd $SLAC_OOD_CRYOSPARC_PATH \
  && git checkout $SLAC_OOD_CRYOSPARC_VERSION

# start
ENTRYPOINT ["/usr/sbin/tini", "--", "/docker-entrypoint.sh"]
