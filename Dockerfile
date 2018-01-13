ARG PYTHON3_VERSION

FROM python:${PYTHON3_VERSION}

RUN apt-get update && \
    apt-get install -y graphviz

WORKDIR /opt/seek-well

COPY scripts/ scripts/
COPY README.rst .
COPY setup.py .

RUN python3 -m pip install -e .

ENTRYPOINT ["seek-well"]
