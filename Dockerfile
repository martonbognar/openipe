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
RUN cd /msp430-gcc/lib/gcc/msp430-elf/${MSPGCC_VERSION_MAJOR}/430 && \
    for lib in libgcc libmul_none; do \
        # unique temp dir per lib ($$=PID avoids collisions)
        dir=/tmp/ar-$$-${lib} && \
        # create IPE-prefixed variant with renamed symbols and sections
        msp430-elf-objcopy --prefix-symbols=__ipe --prefix-alloc-sections=.ipe_func \
            ${lib}.a ${lib}-ipe.a && \
        # extract into separate dirs (ar cannot directly merge archives)
        mkdir -p ${dir}/orig ${dir}/ipe && \
        msp430-elf-ar x ${lib}.a    --output ${dir}/orig && \
        msp430-elf-ar x ${lib}-ipe.a --output ${dir}/ipe && \
        # repack both sets of objects into a single merged archive
        rm ${lib}.a && \
        msp430-elf-ar rcs ${lib}.a ${dir}/orig/*.o ${dir}/ipe/*.o && \
        rm -rf ${dir}; \
    done

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