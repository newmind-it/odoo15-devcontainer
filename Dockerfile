FROM odoo:15.0
USER root
# Copy library scripts to execute
COPY .devcontainer/library-scripts/*.sh .devcontainer/library-scripts/*.env /tmp/library-scripts/
# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="true"
# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "false" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*    
ENV PIPX_HOME=/usr/local/py-utils \
    PIPX_BIN_DIR=/usr/local/py-utils/bin
ENV PATH=${PATH}:${PIPX_BIN_DIR}
RUN bash /tmp/library-scripts/python-debian.sh "os-provided" "/usr/local" "${PIPX_HOME}" "${USERNAME}" \ 
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

COPY ./.devcontainer/.git-token .git-token
RUN pip3 install --upgrade pip
RUN pip3 install xmlsig pyopenSSL suds-jurko num2words \
    cachetools xades grpcio cryptography==3.3.2 six==1.16.0 \
    pylint flake8 autopep8 black yapf mypy pydocstyle pycodestyle bandit
COPY ./.devcontainer/odoo.conf /etc/odoo/
RUN chown -R odoo /etc/odoo/
ARG GIT_RELEASE=fbcdb644f24ecd10049a3730099c4a426a1f607f
RUN curl -L https://github.com/odoo/odoo/archive/${GIT_RELEASE}.tar.gz -o community.tar.gz \
    && tar -xzvf community.tar.gz \
    && rm community.tar.gz \
    && mv -n -u odoo-${GIT_RELEASE}/addons/* /usr/lib/python3/dist-packages/odoo/addons
ARG ENTERPRISE_RELEASE=cd56eeb5ccf367ac14f156099f55b4e74c6fc7aa
RUN curl -L -u $(cat .git-token) https://github.com/odoo/enterprise/archive/${ENTERPRISE_RELEASE}.tar.gz -o enterprise.tar.gz \
    && tar -xzvf enterprise.tar.gz \
    && mv -n -u enterprise-${ENTERPRISE_RELEASE} /usr/lib/python3/dist-packages/odoo/enterprise \
    && rm .git-token enterprise.tar.gz
RUN mkdir /workspace \
    && chown -R odoo /workspace \
    && chown -R odoo /usr/lib/python3/dist-packages/odoo/addons \
    && chown -R odoo /usr/lib/python3/dist-packages/odoo/enterprise \
    && ln -s /usr/lib/python3/dist-packages/odoo /workspace/odoo \
    && mkdir /workspace/.vscode \
    && chmod 777 -R /var/lib/odoo && chown -R vscode:vscode /workspace
COPY ./.devcontainer/launch.json /workspace/.vscode/
COPY ./.devcontainer/settings.json /workspace/.vscode/
WORKDIR /workspace
# Remove library scripts for final image
RUN rm -rf /tmp/library-scripts
USER $USERNAME