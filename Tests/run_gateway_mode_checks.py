"""Standalone macOS integration checks for shared GatewayClient transport mode isolation.

Uses only the Python standard library and Apple's Swift toolchain. No gateway repo,
production capability override, or mocked URLSession is involved. Compiles the
shared transport with DEBUG enabled so fixture clients are permitted.
"""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import json
import socket
import subprocess
import tempfile
import threading


class FixtureServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, scenario):
        super().__init__(("127.0.0.1", 0), Handler)
        self.scenario = scenario
        self.posts = 0
        self.preflights = 0
        self.lock = threading.Lock()
        self.started = threading.Event()
        self.release = threading.Event()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def reply(self, payload):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        try:
            self.wfile.write(payload)
        except (BrokenPipeError, ConnectionResetError):
            pass  # Expected when cancellation closes the delayed connection.

    def do_GET(self):
        if self.path == "/started":
            self.reply(b"yes" if self.server.started.is_set() else b"no")
            return
        if self.path == "/release":
            self.server.release.set()
            self.reply(b"ok")
            return
        if self.path != "/v1/operations":
            self.send_error(404)
            return
        assert self.headers.get("Authorization") == "Bearer " + "a" * 32
        with self.server.lock:
            self.server.preflights += 1
        self.server.started.set()
        if self.server.scenario == "delayed":
            assert self.server.release.wait(10), "Cancellation handshake never released preflight"
        self.reply(json.dumps({
            "api_version": 1,
            "source": "ros2" if self.server.scenario == "mismatch" else "fixture",
            "commands_enabled": True,
            "lease": {"client_id": None, "remaining_seconds": 0},
            "operations": [], "jobs": [],
        }).encode())

    def do_POST(self):
        with self.server.lock:
            self.server.posts += 1
        self.rfile.read(int(self.headers.get("Content-Length", 0)))
        # Accept the mutation but drop its response, leaving outcome uncertain.
        self.close_connection = True
        self.connection.shutdown(socket.SHUT_RDWR)
        self.connection.close()


def main():
    root = Path(__file__).resolve().parent.parent
    servers = [FixtureServer(scenario) for scenario in ("mismatch", "delayed", "drop")]
    try:
        for server in servers:
            threading.Thread(target=server.serve_forever, daemon=True).start()
        with tempfile.TemporaryDirectory(prefix="helios-mode-check-") as temporary:
            binary = Path(temporary) / "mode-check"
            sources = [path for path in (root / "Helios/Networking").glob("*.swift")
                       if path.name != "LiveConnection.swift"]
            sources += [path for path in (root / "Helios/Operations").glob("*.swift")
                        if path.name != "OperationsSession.swift"]
            subprocess.run(["swiftc", "-D", "DEBUG", "-swift-version", "6", *map(str, sorted(sources)),
                            str(root / "Tests/GatewayModeCheck.swift"), "-o", str(binary)], check=True)
            subprocess.run([str(binary), *[f"http://127.0.0.1:{server.server_port}"
                                          for server in servers]], check=True, timeout=30)
        for server, expected_posts in zip(servers, (0, 0, 1)):
            assert server.preflights == 1, (server.scenario, "preflights", server.preflights)
            assert server.posts == expected_posts, (server.scenario, "posts", server.posts)
            print(f"PASS: {server.scenario}: {server.preflights} preflight, {server.posts} POST(s)")
    finally:
        for server in servers:
            server.release.set()
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    main()
