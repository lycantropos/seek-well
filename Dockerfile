ARG PYTHON3_VERSION

FROM python:${PYTHON3_VERSION}

RUN apt-get update && \
    apt-get install -y graphviz

WORKDIR /seek-well

COPY seek-well.py .
COPY README.rst .
COPY setup.py .

RUN python3 -m pip install -e .

ENTRYPOINT ["python3", "seek-well.py"]
