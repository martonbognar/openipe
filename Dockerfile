FROM ubuntu:26.04

# Set to noninteractive mode
ARG DEBIAN_FRONTEND=noninteractive

################################################################################
# Basic dependencies
################################################################################

RUN apt-get update && apt-get install build-essential cmake iverilog tk expect-dev git python3 python3-pip python3-venv wget unzip -y
RUN apt install python3-pyelftools

# Install toolchain
ENV MSPGCC_URL=https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-LlCjWuAbzH/9.3.1.2

# create ipe-renamed compiler libraries
COPY install-ti-gcc.sh .
RUN ./install-ti-gcc.sh && rm install-ti-gcc.sh

ENV MSPGCC_VERSION_MAJOR=9.3.1
ENV MSPGCC_VERSION_MINOR=${MSPGCC_VERSION_MAJOR}.11
ENV MSPGCC_SUPPORT_VERSION=1.212
ENV PATH="$PATH:/msp430-gcc/bin"

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
