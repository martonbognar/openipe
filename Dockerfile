FROM ubuntu:26.04

# Set to noninteractive mode
ARG DEBIAN_FRONTEND=noninteractive

################################################################################
# Basic dependencies
################################################################################

RUN apt-get update && apt-get install build-essential cmake iverilog tk expect-dev git python3 python3-pip python3-venv wget unzip -y
RUN apt install python3-pyelftools

# Install toolchain
ENV MSPGCC_VERSION_MAJOR=9.3.1
ENV MSPGCC_VERSION_MINOR=${MSPGCC_VERSION_MAJOR}.11
ENV MSPGCC_SUPPORT_VERSION=1.212
ENV MSPGCC_URL=https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-LlCjWuAbzH/9.3.1.2

RUN wget ${MSPGCC_URL}/msp430-gcc-${MSPGCC_VERSION_MINOR}_linux64.tar.bz2
RUN tar xjf msp430-gcc-${MSPGCC_VERSION_MINOR}_linux64.tar.bz2
RUN mv msp430-gcc-${MSPGCC_VERSION_MINOR}_linux64 msp430-gcc

# Install headers
RUN wget ${MSPGCC_URL}/msp430-gcc-support-files-${MSPGCC_SUPPORT_VERSION}.zip
RUN unzip msp430-gcc-support-files-${MSPGCC_SUPPORT_VERSION}.zip
RUN cp -a msp430-gcc-support-files/include/*.h msp430-gcc/msp430-elf/include
RUN cp -a msp430-gcc-support-files/include/*.ld msp430-gcc/msp430-elf/lib

RUN rm -fr msp430-gcc-support-files msp430-gcc-${MSPGCC_VERSION_MINOR}_linux64.tar.bz2 msp430-gcc-support-files-${MSPGCC_SUPPORT_VERSION}.zip

ENV PATH="$PATH:/msp430-gcc/bin"
ENV PATH="$PATH:/msp430-gcc/libexec/gcc/msp430-elf/${MSPGCC_VERSION_MINOR}"

# create ipe-renamed compiler libraries
COPY install_ipe_stubs.sh .
RUN ./install_ipe_stubs.sh && rm install_ipe_stubs.sh

# Install 
################################################################################
# Install dependencies for the software mitigation framework
################################################################################

RUN python3 -m venv openipe_venv
COPY core/sim/rtl_sim/src-c/framework/requirements.txt .
RUN  ./openipe_venv/bin/pip install -r requirements.txt && rm requirements.txt
ENV PATH="/openipe_venv/bin:$PATH"

################################################################################
# Install the Pandora tool
################################################################################

WORKDIR /pandora
RUN git clone https://github.com/pandora-tee/pandora .
RUN git clone https://github.com/angr/angr-platforms
RUN python3 -m venv venv
RUN ./venv/bin/pip install -r requirements.txt
RUN cd angr-platforms && ../venv/bin/pip install .

################################################################################
# Copy convenience scripts
################################################################################

WORKDIR /openipe
COPY scripts/* ./scripts/
RUN chmod +x scripts/*.sh

################################################################################
# Display a welcome message for interactive sessions
################################################################################

RUN echo '[ ! -z "$TERM" -a -r /etc/motd ] && cat /etc/motd' \
	>> /etc/bash.bashrc ; echo "\
                                                    @@   @@@@@@@    @@@@@@@@@@ \n\
                                                    @@   @      @@  @          \n\
       @@@@@       @@@@@       @@@@@    @  @@@@     @@   @       @  @          \n\
     @@   @ @@   @@     @@   @@     @@  @@     @@   @@   @      @@  @@@@@@@    \n\
    @@@@ @    @ @@       @@  @       @  @       @@  @@   @@@@@@@    @          \n\
    @@   @ @@ @ @@       @@  @          @       @@  @@   @          @          \n\
  @@  @ @@  @@  @@@     @@   @@         @       @@  @@   @          @          \n\
   @@@   @@@    @@  @@@@       @@@@@    @       @@  @@   @          @@@@@@@@@@ \n\
@   @           @@                                                             \n\
  @             @@                                                             \n\
\n\
\n\
`lsb_release -d`\n\n\
To get started, see <https://github.com/martonbognar/openipe>,\n\
or have a look at the example programs under <core/sim/rtl_sim/src-c/ipe-hello/>.\n\
\n"\
> /etc/motd

CMD ["/bin/bash"]
