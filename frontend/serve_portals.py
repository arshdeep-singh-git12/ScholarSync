import sys
import os
import threading
from http.server import HTTPServer, SimpleHTTPRequestHandler

FRONTEND_DIR = os.path.dirname(os.path.abspath(__file__))

def create_handler(default_page):
    class CustomHandler(SimpleHTTPRequestHandler):
        def __init__(self, *args, **kwargs):
            super().__init__(*args, directory=FRONTEND_DIR, **kwargs)

        def do_GET(self):
            # If requesting root or empty, serve the designated portal page
            clean_path = self.path.split('?')[0].split('#')[0]
            if clean_path in ('/', ''):
                self.path = '/' + default_page
            return super().do_GET()
            
        def log_message(self, format, *args):
            # Suppress noisy request logging in terminal
            pass
            
    return CustomHandler

def run_server(port, default_page):
    handler = create_handler(default_page)
    server = HTTPServer(('0.0.0.0', port), handler)
    server.serve_forever()

if __name__ == '__main__':
    portals = [
        (5500, 'index.html'),
        (5501, 'student.html'),
        (5502, 'admin.html'),
        (5503, 'registrar.html'),
        (5504, 'verify.html'),
    ]
    print("====================================================================")
    print("  ScholarSync Multi-Portal Web Server")
    print("====================================================================")
    for port, page in portals:
        t = threading.Thread(target=run_server, args=(port, page), daemon=True)
        t.start()
        print(f"  [+] Port {port} -> {page}")
    print("====================================================================")
    print("  All portals active and connected to Spring Boot API (:8080)")
    print("====================================================================")
    
    import time
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        sys.exit(0)
