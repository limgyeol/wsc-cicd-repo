FROM python:3.14-alpine
WORKDIR /app
RUN pip install --no-cache-dir flask
COPY main.py .
EXPOSE 8080
CMD ["python", "main.py"]
