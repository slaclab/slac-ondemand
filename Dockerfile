FROM centos:centos7

# shoudl probably user a docker builder AS or something rather than doing again here... perhaps from the slurm image?
ARG SLURM_TAG=slurm-19-05-5-1

ARG MUNGEUSER=891
ARG SLURMUSER=16924
ARG SLURMGROUP=1034

RUN groupadd -g $MUNGEUSER munge \
    && useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge \
    && groupadd -g $SLURMGROUP slurm \
    && useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm 

RUN yum makecache fast \
    && yum -y update \
    && yum -y install epel-release centos-release-scl wget \
    && wget https://turbovnc.org/pmwiki/uploads/Downloads/TurboVNC.repo -O /etc/yum.repos.d/TurboVNC.repo \
    && yum -y update \
    && yum install -y \
      munge \
      net-tools openssh-server openssh-clients singularity \
      lsof sudo httpd24-mod_ssl httpd24-mod_ldap \
      python-setuptools sssd nss-pam-ldapd \
        autoconf \
        bzip2 \
        bzip2-devel \
        file \
        gcc \
        gcc-c++ \
        gdbm-devel \
        git \
        glibc-devel \
        gmp-devel \
        make \
        mariadb-devel \
        munge-devel \
        ncurses-devel \
        openssl-devel \
        openssl-libs \
        pkconfig \
        psmisc \
        readline-devel \
        sqlite-devel \
        tcl-devel \
        tix-devel \
        tk \
        tk-devel \
        zlib-devel \
        pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad rpm-build mysql-devel rpm-build gcc  libssh2-devel  gtk2-devel  libibmad libibumad perl-Switch perl-ExtUtils-MakeMaker \
        yum -y install turbovnc \
    && yum clean all \
    && rm -rf /var/cache/yum \
    && easy_install supervisor

RUN set -ex \
    && git clone https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && git checkout tags/$SLURM_TAG \
    && ./configure --enable-debug --prefix=/usr \
       --sysconfdir=/etc/slurm --with-mysql_config=/usr/bin \
       --libdir=/usr/lib64 \
    && make install \
    && install -D -m644 etc/cgroup.conf.example /etc/slurm/cgroup.conf.example \
    && install -D -m644 etc/slurm.conf.example /etc/slurm/slurm.conf.example \
    && install -D -m644 etc/slurmdbd.conf.example /etc/slurm/slurmdbd.conf.example \
    && install -D -m644 contribs/slurm_completion_help/slurm_completion.sh /etc/profile.d/slurm_completion.sh \
    && popd \
    && rm -rf slurm \
    && mkdir /etc/sysconfig/slurm \
        /var/spool/slurmd \
        /var/run/slurmd \
        /var/lib/slurmd \
        /var/log/slurm \
    && chown slurm:root /var/spool/slurmd \
        /var/run/slurmd \
        /var/lib/slurmd \
        /var/log/slurm \
    && /sbin/create-munge-key

# setup sssd
COPY sssd/nsswitch.conf sssd/nslcd.conf /etc/
COPY sssd/sssd.conf /etc/sssd/sssd.conf
RUN chmod 600 /etc/sssd/sssd.conf

#RUN yum search ondemand
RUN yum install -y https://yum.osc.edu/ondemand/1.6/ondemand-release-web-1.6-4.noarch.rpm && \
    yum install --nogpgcheck -y ondemand && \
    mkdir -p /etc/ood/config/clusters.d && \
    mkdir -p /etc/ood/config/apps/shell

# envs
ENV MUNGE_ARGS=''

# copy over exe's
COPY docker-entrypoint.sh supervisord-eventlistener.sh ondemand.sh supervisord.conf /

# setup tini
ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini /usr/sbin/tini
RUN chmod +x /usr/sbin/tini

# copy local confs
COPY config/ood_portal.yml /etc/ood/config/ood_portal.yml
COPY config/apps/bc_desktop/slac_cluster.yml /etc/ood/config/apps/bc_desktop/slac_cluster.yml
COPY etc/clusters.d/slac_cluster.yml /etc/ood/config/clusters.d/

ENV PATH=/opt/TurboVNC/bin/:${PATH}

# start
ENTRYPOINT ["/usr/sbin/tini", "--", "/docker-entrypoint.sh"]
