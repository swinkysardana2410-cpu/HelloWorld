# HelloWorld
It's a simple hello world c++ application residing inside docker container. Creating CI/CD pipeline for this application
To setup a CI/CD pipeline for a C++ application using Docker, you’ll need three main pieces working together:
- Dockerfile – to containerize your C++ app.
- CI/CD pipeline configuration – depends on your platform (GitHub Actions, GitLab CI, Jenkins, Azure DevOps, etc.).
- Build and run steps – to compile and execute inside the container.

Create a C++ application in Visual Studio Code and create its executable.
HelloWorldApp/src/main.cpp
	     /Dockerfile

Instructions given in Dockerfile:
- Sets the base image for your container, that's official GNU compiler collection image that comes with C++ compiler pre-installed.
latest means it will pull the most recent version available.
- Define the working directory inside container. Any subsequent commands (CMD, RUN, COPY) will be executed relative to /app
- Copy all files from local project directory into the container's working directory (/app). The first dot refers to local directory and the second . refers to the container's working directory. This ensures your local main.cpp file is available inside the container.
- Compile your source code into an executable.
- Defines the default command that runs when the container starts.

FROM gcc:latest
WORKDIR /app
COPY . .
RUN g++ src/main.cpp -o myapp
CMD ["./myapp"]


Now we have created a C++ application, lets push it to github
- Open your project directory and type the following commands 
   git init
   git status
   git add .
- Enter your email id configured on github
   git config --global user.email "swinkysardana2410@gmail.com"
   git commit -m "Initial commit of C++ application with Dockerfile"
- Create a new repository on GitHub from link : https://github.com/swinkysardana2410-cpu?tab=repositories
   New -> Enter Repo name(HelloWorld), description -> Create Repository
- Link your local repo to github (copy newly created repo linke https://github.com/swinkysardana2410-cpu/HelloWorld.git)
   git remote add origin https://github.com/swinkysardana2410-cpu/HelloWorld.git
   git branch -M main
- Before pushing your changes, pull first
   git pull <remote> <branch> - git pull https://github.com/swinkysardana2410-cpu/HelloWorld.git main
- Pull the remote changes into local branch and push your latest changes
   git pull origin main --rebase
   git push -u origin main
   
All your changes have been committed on github

- Now create a CI pipeline using github actions
Inside your project, create a folder HelloWorldApp/.github/workflows/ and add a file hello-world.yaml and enter the following commands :
 

name: Build and Run C++ App in Docker

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Build Docker image
      run: docker build -t cpp-app .

    - name: Run container
      run: docker run --rm cpp-app

That means whenever any push or pull command is executed on main branch, the following jobs should get triggered.
Jobs - Download ubuntu latest as a base image
       Checkout my code
       Build a docker image using dockerfile exists in HelloWorldApp/
       Run your app inside container

Now make some changes in main.cpp and push the latest code on github, the pipeline will be triggered automatically on github

To go for CD(Continuous Deployment) : To extend your CI/CD pipeline to deployment, you need to decide where your dockerized app should run.The most common options are Docker Hub / GitHub Container Registry (to store images) and a server or cloud platform (to run them)
01 Choose a Deployment Target
Decide where your Dockerized app should run after CI builds.
Options: Docker Hub, GitHub Container Registry, AWS ECS, Azure Container Apps, Google Cloud Run, or your own server
For learning/demo: Docker Hub + local server is simplest
NOTE : Pushing image to docker hub is also a part of Continuous Integration

Pushing to docker hub means you are uploading your docker image to a registry(Docker Hub). It acts as a storage and distribution center for your container images. Your image is publicly/privately available so any machine with docker can pull it.

02 Set Up Container Registry
You need a registry to store and distribute your Docker images.
Create a Docker Hub account (or use GitHub Container Registry)
Generate an access token or password for authentication
Add these credentials as GitHub Secrets (e.g., DOCKER_USERNAME, DOCKER_PASSWORD)
Create a repo on Docker Hub
Generate an access token
	docker login -u swinky2410
	dckr_***

03 Update GitHub Actions Workflow
Modify your pipeline to push images to the registry. Edit hello-world.yaml
name: Build and Run C++ App in Docker

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Log in to Docker Hub
      run: echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin

    - name: Build Docker image
      run: docker build -t ${{ secrets.DOCKER_USERNAME }}/helloworld:latest .

    - name: Push Docker image
      run: docker push ${{ secrets.DOCKER_USERNAME }}/helloworld:latest

    - name: Run container
      run: docker run --rm ${{ secrets.DOCKER_USERNAME }}/helloworld:latest

Now proceed with the continous deployment step, running your image on a server means you are actually starting a server from that image on a machine(server,VM or cloud instance). This is where your app executes and serve users. The app will be live consuming resources and potentially exposed via ports.

How They Work Together in CD
CI step: Build the image and push it to Docker Hub.
CD step: Server pulls the latest image from Docker Hub and runs it.
This ensures the server always runs the newest version of your app after each commit.

In short:
Push to Docker Hub = publish the image (make it available).
Run on server = deploy the image (make it execute and serve users).

Continuous Deployment ::
Step 1: Choose a Server
You need a machine where your Dockerized app will run. Common options:
Cloud VM: AWS EC2, Azure VM, Google Compute Engine.
VPS providers: DigitalOcean, Linode, Hetzner.
On-premise server: Your own Linux box.
For simplicity, let’s assume you’re using Ubuntu Linux on a cloud VM.

Step 2: Create a Server Account
- Provision the server (e.g., create an EC2 instance or DigitalOcean droplet).
- Connect via SSH:
ssh user@your-server-ip

- Create a dedicated deployment user (recommended for security):
sudo adduser deploy
sudo usermod -aG docker deploy
This creates a deploy user and gives it permission to run Docker.

Step 3: Set Up SSH Keys
- On your local machine (or CI/CD runner), generate a key:
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
- Copy the public key to the server:
ssh-copy-id deploy@your-server-ip

 Step 4: Install Docker on the Server
sudo apt update
sudo apt install docker.io -y
sudo systemctl enable docker

Step 5: Add Secrets to GitHub

In your GitHub repo:

SERVER_HOST → your server IP.

SERVER_USER → deploy.

SERVER_SSH_KEY → contents of your private SSH key.

DOCKER_USERNAME → your Docker Hub username.

DOCKER_PASSWORD → your Docker Hub access token.

🔹 Step 6: Extend GitHub Actions Workflow
name: Build, Push, and Deploy C++ App

on:
  push:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Log in to Docker Hub
      run: echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin  

    - name: Build Docker image
      run: docker build -t ${{ secrets.DOCKER_USERNAME }}/helloworld:latest .

    - name: Push Docker image
      run: docker push ${{ secrets.DOCKER_USERNAME }}/helloworld:latest

  deploy:
    runs-on: ubuntu-latest
    needs: build
    steps:
    - name: Deploy to server via SSH
      uses: appleboy/ssh-action@v0.1.10
      with:
        host: ${{ secrets.SERVER_HOST }}
        username: ${{ secrets.SERVER_USER }}
        key: ${{ secrets.SERVER_SSH_KEY }}
        script: |
          docker pull ${{ secrets.DOCKER_USERNAME }}/helloworld:latest
          docker stop helloworld || true
          docker rm helloworld || true
          docker run -d --name helloworld -p 8080:8080 ${{ secrets.DOCKER_USERNAME }}/helloworld:latest

Step 7: Test Deployment
Push code to main.
GitHub Actions builds → pushes image → SSHs into server → pulls and runs container.

Your app is now live on http://your-server-ip:8080.
