FROM ubuntu:22.04

# Set to noninteractive mode
ARG DEBIAN_FRONTEND=noninteractive

################################################################################
# Basic dependencies
################################################################################

RUN apt-get update && apt-get install build-essential cmake iverilog tk binutils-msp430 gcc-msp430 msp430-libc msp430mcu expect-dev git python3 python3-pip python3-venv wget -y
RUN python3 -m pip install pyelftools

RUN wget https://dr-download.ti.com/software-development/ide-configuration-compiler-or-debugger/MD-LlCjWuAbzH/9.3.1.2/msp430-gcc-9.3.1.11_linux64.tar.bz2
RUN tar xjf msp430-gcc-9.3.1.11_linux64.tar.bz2
RUN cp msp430-gcc-9.3.1.11_linux64/bin/msp430-elf-objcopy /usr/bin/

################################################################################
# Install dependencies for the software mitigation framework
################################################################################

COPY core/sim/rtl_sim/src-c/framework/requirements.txt .
RUN python3 -m pip install -r requirements.txt && rm requirements.txt

################################################################################
# Install the Pandora tool
################################################################################

WORKDIR /pandora
RUN git clone https://github.com/pandora-tee/pandora .
RUN git checkout 921d514
RUN git clone https://github.com/angr/angr-platforms
RUN cd angr-platforms && git checkout d9231f2 && cd ..
RUN python3 -m pip install -r requirements.txt && cd angr-platforms && python3 -m pip install .

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
