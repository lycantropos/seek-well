FROM python:3

RUN apt-get update && \
    apt-get install -y graphviz

WORKDIR /seek-well
COPY . /seek-well/
RUN python3 -m pip install .

ENTRYPOINT ["python3", "seek-well.py"]
