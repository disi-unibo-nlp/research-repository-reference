# Research Repository Reference





# Create Docker Image

From the project main path (e.g. /home/molfetta/research-repository-reference)
```bash
IMAGE_NAME="my_project_image"
docker build -f build/Dockerfile -t $IMAGE_NAME .
```




# Environment Variable
Create a .env file into your project directory.




```bash
python3 -m venv test_env
source test_env/bin/activateha 

mkdir -p /scratch.hpc/lorenzo.molfetta2/.pip_cache /scratch.hpc/lorenzo.molfetta2/tmp

PIP_CACHE_DIR="/scratch.hpc/lorenzo.molfetta2/.pip_cache" TMPDIR=/scratch.hpc/lorenzo.molfetta2/tmp pip3 install --no-cache-dir -r build/requirements.txt
```