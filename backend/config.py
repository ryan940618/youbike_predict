import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATASET_DIR = os.path.join(BASE_DIR, "dataset")

if not os.path.exists(DATASET_DIR):
    os.makedirs(DATASET_DIR)