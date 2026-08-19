FROM python:3.12-alpine
WORKDIR /app
COPY apps/web /app/apps/web
COPY data /app/data
COPY services/api /app/services/api
CMD ["python","/app/services/api/server.py"]
