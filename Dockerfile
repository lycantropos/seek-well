FROM python:3

WORKDIR /seek-well
COPY . /seek-well/
RUN python3 -m pip install .

ENTRYPOINT ["python3", "seek-well.py"]
