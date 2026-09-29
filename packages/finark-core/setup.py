# ============================================================================
# FINARK CORE PLATFORM CHASSIS SDK - MANIFEST CONFIGURATION
# Target File: packages/finark-core/setup.py | BRS: BR-14
# ============================================================================

from setuptools import setup, find_packages

setup(
    name="finark-core",
    version="0.1.0",
    package_dir={"": "."},
    packages=find_packages(where="."),
    install_requires=[
        "valkey>=6.1.1",
        "PyJWT>=2.15.0"
    ],
)
