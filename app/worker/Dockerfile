FROM python:3.12-alpine
WORKDIR /app
RUN pip install boto3
COPY worker.py .
CMD ["python","worker.py"]
