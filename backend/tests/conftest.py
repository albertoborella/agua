import tempfile
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel, create_engine

from app.main import app


@pytest.fixture(scope="session")
def test_db_dir():
    with tempfile.TemporaryDirectory() as tmpdir:
        yield tmpdir


@pytest.fixture(scope="session")
def test_engine(test_db_dir):
    import app.config as config

    config.settings.DATABASE_DIR = test_db_dir
    url = f"sqlite:///{test_db_dir}/test.db"
    engine = create_engine(url)
    SQLModel.metadata.create_all(engine)
    yield engine


@pytest.fixture
def session(test_engine):
    with Session(test_engine) as session:
        yield session


@pytest.fixture
def client():
    return TestClient(app)
