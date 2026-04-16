FROM gcc:latest
WORKDIR /app
COPY . .
RUN g++ src/main.cpp -o myapp
CMD ["./myapp"]