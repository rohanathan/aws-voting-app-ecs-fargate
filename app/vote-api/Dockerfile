FROM python:3.12-alpine
WORKDIR /app
RUN pip install flask boto3
COPY app.py .
EXPOSE 8080
CMD ["python","app.py"]
