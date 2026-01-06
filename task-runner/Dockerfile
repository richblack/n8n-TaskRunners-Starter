FROM n8nio/runners:2.2.3

USER root

RUN pip install --no-cache-dir \
    --target=/opt/runners/task-runner-python/.venv/lib/python3.13/site-packages \
    pandas numpy

COPY n8n-task-runners.json /etc/n8n-task-runners.json
