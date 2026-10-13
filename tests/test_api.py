import pytest
from fastapi.testclient import TestClient

from main import app


@pytest.mark.parametrize(
    ("path", "expected_body"),
    [
        ("/", {"message": "Cloud Engineering API is running"}),
        ("/api", {"message": "Cloud Engineering API is running"}),
        ("/health", {"status": "healthy"}),
    ],
)
def test_public_endpoints_return_expected_json(path, expected_body):
    with TestClient(app) as client:
        response = client.get(path)

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/json")
    assert response.json() == expected_body


def test_browser_receives_landing_page():
    with TestClient(app) as client:
        response = client.get("/", headers={"Accept": "text/html"})
        stylesheet = client.get("/static/styles.css")

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("text/html")
    assert "A small API." in response.text
    assert 'href="/docs"' in response.text
    assert stylesheet.status_code == 200
    assert stylesheet.headers["content-type"].startswith("text/css")


def test_unknown_route_returns_not_found():
    with TestClient(app) as client:
        response = client.get("/missing")

    assert response.status_code == 404
