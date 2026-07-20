FROM python:3.14-alpine AS builder
WORKDIR /app
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir flask

FROM python:3.14-alpine
RUN apk update && apk upgrade --no-cache
RUN apk add --no-cache curl
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /venv /venv
ENV PATH="/venv/bin:$PATH"
WORKDIR /app
COPY main.py .
USER app
EXPOSE 8080
CMD ["python", "main.py"]
