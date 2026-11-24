FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PORT=8080
WORKDIR /srv/app
RUN pip install --no-cache-dir 'psycopg[binary]>=3.2,<4' \
    && useradd --create-home --uid 10001 --shell /usr/sbin/nologin labuser
COPY app/ ./app/
USER 10001:10001
EXPOSE 8080
CMD ["python", "-m", "app.server"]
