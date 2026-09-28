"""Run production Swift client against delayed/unavailable versions of the actual gateway server."""
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import time

from mobile_gateway.server import TelemetryServer
from mobile_gateway.state import TelemetryState

TOKEN = "helios-local-fixture-token-32-chars-only"


class FreshState(TelemetryState):
    def snapshot(self):
        self.odometry(frame_id="odom", child_frame_id="base_link", x=1., y=2.,
                      qx=0., qy=0., qz=0., qw=1., linear_x=.1, linear_y=0., angular_z=0.)
        self.scan(frame_id="laser", ranges=[1.2], range_min=.02, range_max=10.)
        return super().snapshot()


class DelayedState(FreshState):
    def snapshot(self):
        sample = super().snapshot()
        time.sleep(3)
        return sample


def main():
    root = Path(__file__).resolve().parent.parent
    delayed = TelemetryServer(("127.0.0.1", 0), DelayedState(source="fixture"), TOKEN)
    reserved = socket.socket()
    reserved.bind(("127.0.0.1", 0))
    retry_port = reserved.getsockname()[1]
    recovered = []

    def start_recovered():
        reserved.close()
        server = TelemetryServer(("127.0.0.1", retry_port), FreshState(source="fixture"), TOKEN)
        recovered.append(server)
        threading.Thread(target=server.serve_forever, daemon=True).start()

    threading.Thread(target=delayed.serve_forever, daemon=True).start()
    timer = None
    try:
        with tempfile.TemporaryDirectory(prefix="helios-fault-check-") as temporary:
            binary = Path(temporary) / "fault-check"
            sources = sorted((root / "Helios/Development").glob("*.swift")) + sorted((root / "Helios/Networking").glob("*.swift")) + sorted((root / "Helios/Operations").glob("*.swift"))
            subprocess.run(["swiftc", "-D", "DEBUG", "-swift-version", "6", *map(str, sources),
                            str(root / "Tests/GatewayFaultCheck.swift"), "-o", str(binary)], check=True)
            timer = threading.Timer(8, start_recovered)
            timer.start()
            environment = dict(os.environ, HELIOS_GATEWAY_TOKEN=TOKEN,
                               HELIOS_DELAYED_ENDPOINT=f"http://localhost:{delayed.server_port}",
                               HELIOS_RETRY_ENDPOINT=f"http://localhost:{retry_port}")
            subprocess.run([str(binary)], env=environment, check=True, timeout=45)
    finally:
        if timer:
            timer.cancel()
            timer.join()
        reserved.close()
        delayed.shutdown()
        delayed.server_close()
        for server in recovered:
            server.shutdown()
            server.server_close()


if __name__ == "__main__":
    main()
