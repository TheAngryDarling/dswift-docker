ARG SWIFT_TAG
FROM swift:$SWIFT_TAG
LABEL Description="Docker Container for Dynamic Swift programming language"
ARG SWIFT_TAG

# Tells the dswift-update script and subsequently the dswift source code NOT to include dswift specific parameters parsing
ENV NO_DSWIFT_PARAMS true
# Tells the dswift-update script and subsequently the dswift source code to look for user name and display name from env variables
ENV ENABLE_ENV_USER_DETAILS true
# Tells the dswift-update script to subsequently the dswift source code to enable auto install dependand system packages regardless of what the config file says
ENV AUTO_INSTALL_PACKAGES true

RUN echo "$SWIFT_TAG"

RUN if [[ "$SWIFT_TAG" == *"centos7" ]] || [[ "$SWIFT_TAG" == "centos7" ]]; then \
        echo "Updating Git" \
        && yum remove -y git \
        && yum remove -y git-* \
        && yum -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm \
        && yum install -y git; \
    fi
    
    
# copy updater
COPY ./dswift-update /usr/bin/
# make updated executable
RUN chmod +x /usr/bin/dswift-update

#copy dswift sha.  Used for comparison when checking for updates
COPY ./dswift.sha /usr/bin/

#copy source code
COPY ./dswift-latest /tmp/source/Executables/dswift
COPY ./Packages /tmp/source/Packages

WORKDIR /tmp/source/Executables/dswift
RUN echo "Compiling source code for swift:$SWIFT_TAG ..." \
    && swift build -c release  -Xswiftc -DNO_DSWIFT_PARAMS -Xswiftc -DAUTO_INSTALL_PACKAGES -Xswiftc -DENABLE_ENV_USER_DETAILS \
    && echo "Installing dswift ..." \
    && cp $(swift build  -c release  -Xswiftc -DNO_DSWIFT_PARAMS -Xswiftc -DAUTO_INSTALL_PACKAGES -Xswiftc -DENABLE_ENV_USER_DETAILS --show-bin-path)/dswift /usr/bin/dswift \
    && chmod -R o+r /usr/bin/dswift \
    && cd / \
    && echo "Removing source code ..." \
    && rm -r -f /tmp/source \
    && echo "Installing auto-complete scripts ..." \
    && echo "Installing BASH auto-complete scripts ..." \
    && dswift package install-completion-script bash > /dev/null \
    && echo "Installing ZSH auto-complete scripts ..." \
    && dswift package install-completion-script zsh > /dev/null

WORKDIR /