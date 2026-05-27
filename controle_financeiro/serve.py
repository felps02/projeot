"""Static file server for build/web with cross-origin isolation headers.

Necessary for sqflite_common_ffi_web (uses SharedArrayBuffer).
"""

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import os

WEB_DIR = os.path.join(os.path.dirname(__file__), "build", "web")


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "cross-origin")
        super().end_headers()


if __name__ == "__main__":
    port = 8080
    print(f"Serving {WEB_DIR} on http://localhost:{port}")
    ThreadingHTTPServer(("localhost", port), Handler).serve_forever()
