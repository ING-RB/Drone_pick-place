from setuptools import find_packages
from setuptools import setup

setup(
    name='lidarslam_msgs',
    version='0.0.0',
    packages=find_packages(
        include=('lidarslam_msgs', 'lidarslam_msgs.*')),
)
