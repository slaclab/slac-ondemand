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

RUN set -xe \
    && yum makecache fast \
    && yum -y update \
    && yum -y install epel-release centos-release-scl wget \
    && wget https://turbovnc.org/pmwiki/uploads/Downloads/TurboVNC.repo -O /etc/yum.repos.d/TurboVNC.repo \
    && yum -y update \
    && buildDeps="\
        gdbm-devel glibc-devel gmp-devel \
        mariadb-devel \
        munge-devel \
        ncurses-devel readline-devel \
        openssl-devel \
        sqlite-devel \
        tcl-devel tix-devel tk-devel \
        zlib-devel bzip2-devel \
        pam-devel numactl-devel hwloc-devel lua-devel \
        readline-devel rrdtool-devel ncurses-devel mysql-devel libssh2-devel gtk2-devel" \
    && yum install -y \
        $buildDeps \
        munge \
        net-tools openssh-server openssh-clients \
        lsof sudo httpd24-mod_ssl httpd24-mod_ldap \
        python-setuptools sssd nss-pam-ldapd \
        bzip2 \
        file \
        autoconf make gcc gcc-c++ \
        git \
        openssl-libs \
        pkconfig \
        psmisc \
        tk \
        numactl hwloc lua man2html libibmad libibumad rpm-build rpm-build gcc libibmad libibumad perl-Switch perl-ExtUtils-MakeMaker \
    && yum -y install turbovnc \
    && git clone https://github.com/SchedMD/slurm.git \
    && pushd slurm \
    && git checkout tags/$SLURM_TAG \
    && ./configure --enable-debug --prefix=/usr \
         --sysconfdir=/etc/slurm --with-mysql_config=/usr/bin \
         --libdir=/usr/lib64 \
    && make install \
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
    && /sbin/create-munge-key \
    && yum remove -y $buildDeps \
    && yum clean all \
    && easy_install supervisor
#    && rm -rf /var/cache/yum

# setup sssd
COPY sssd/nsswitch.conf sssd/nslcd.conf /etc/
COPY sssd/sssd.conf /etc/sssd/sssd.conf
RUN chmod 600 /etc/sssd/sssd.conf

# oidc
# create a symlink for the ood config so that we may use kubernetes for it
RUN yum install -y https://yum.osc.edu/ondemand/latest/ondemand-release-web-latest-1-6.noarch.rpm \
    && yum install --nogpgcheck -y ondemand httpd24-mod_auth_openidc \
    && mkdir -p /etc/ood/config/clusters.d \
    && mkdir -p /etc/ood/config/portal && ln -sf /etc/ood/config/portal/ood_portal.yml /etc/ood/config/ood_portal.yml \
    && mkdir -p /etc/ood/config/htpasswd/ \
    && mkdir -p /etc/ood/config/apps/shell

# envs
ENV MUNGE_ARGS=''

# copy over exe's
COPY docker-entrypoint.sh supervisord-eventlistener.sh ondemand.sh supervisord.conf /

# setup tini
ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini /usr/sbin/tini
RUN chmod +x /usr/sbin/tini

# copy local confs
#COPY config/ood_portal.yml /etc/ood/config/ood_portal.yml
#COPY config/apps/bc_desktop/slac_cluster.yml /etc/ood/config/apps/bc_desktop/slac_cluster.yml
#COPY etc/clusters.d/slac_cluster.yml /etc/ood/config/clusters.d/
#COPY config/auth_openidc.conf /opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf

ENV PATH=/opt/TurboVNC/bin/:${PATH}

# start
ENTRYPOINT ["/usr/sbin/tini", "--", "/docker-entrypoint.sh"]
