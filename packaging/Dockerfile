ARG BASE_VERSION="17.0-20250807"
FROM odoo:$BASE_VERSION

USER root

RUN ln -s $(which python3) /usr/bin/python

ADD tmpdir /opt/odoo/extraaddons
ADD docker-build.sh /
RUN /docker-build.sh
RUN rm /docker-build.sh

ADD entrypoint.sh /

USER odoo

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "odoo" ]