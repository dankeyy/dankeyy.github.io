#!/usr/bin/env python3
import http.server
import socketserver
import os
import signal
import sys


class SPAHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        self.send_header('Pragma', 'no-cache')
        self.send_header('Expires', '0')
        super().end_headers()

    def do_GET(self):
        if self.path.startswith('/posts/'):
            return super().do_GET()

        path = self.translate_path(self.path)
        if os.path.exists(path) and not os.path.isdir(path):
            return super().do_GET()

        self.path = '/index.html'
        return super().do_GET()


def run_server():
    PORT = 8000
    socketserver.TCPServer.allow_reuse_address = True

    with socketserver.TCPServer(("127.0.0.1", PORT), SPAHandler) as httpd:
        print(f"→ Blog running at http://localhost:{PORT}")
        print("   (Posts should now update immediately after you edit + save .txt files)")
        print("   (Ctrl+C to stop)")

        def shutdown(sig, frame):
            print("\nShutting down server...")
            httpd.server_close()
            sys.exit(0)

        signal.signal(signal.SIGINT, shutdown)
        signal.signal(signal.SIGTERM, shutdown)

        httpd.serve_forever()


if __name__ == "__main__":
    run_server()
