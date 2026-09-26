"""Container healthcheck for the Agua backend.

Kept as a standalone script instead of a `python -c` inline one-liner because
container runtimes rewrite inline healthcheck commands through a shell, and the
parentheses in `urlopen(...)` get parsed as shell syntax, making the check fail
permanently and marking a healthy backend as unhealthy.
"""

import sys
import urllib.request

URL = "http://localhost:8000/health"


def main() -> int:
    try:
        with urllib.request.urlopen(URL, timeout=2) as response:
            if response.status == 200:
                return 0
            print(f"healthcheck: unexpected status {response.status}")
            return 1
    except Exception as error:  # noqa: BLE001 - healthcheck must never crash
        print(f"healthcheck: {error}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
