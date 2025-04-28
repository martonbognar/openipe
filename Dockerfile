FROM ubuntu:22.04

# Set to noninteractive mode
ARG DEBIAN_FRONTEND=noninteractive

################################################################################
# Basic dependencies
################################################################################

RUN apt-get update && apt-get install build-essential cmake iverilog tk binutils-msp430 gcc-msp430 msp430-libc msp430mcu expect-dev git python3 python3-pip python3-venv -y
RUN python3 -m pip install pyelftools

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
RUN git clone https://github.com/angr/angr-platforms
RUN python3 -m pip install -r requirements.txt && cd angr-platforms && python3 -m pip install .

################################################################################
# Copy convenience scripts
################################################################################

WORKDIR /openipe
COPY *.sh .
RUN chmod +x *.sh

CMD /bin/bash
