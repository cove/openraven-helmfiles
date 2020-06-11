#! /usr/bin/env python
# coding=utf-8
import json
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class IntrospectionHandler(SimpleHTTPRequestHandler):

    def do_GET(self) -> None:
        if self.path == '/healthz':
            # this is the non-logging version
            self.send_response_only(200)
            self.send_header('content-length', '0')
            self.end_headers()
            return
        try:
            results = {}
            for header, value in self.headers.items():
                # the original introspection endpoint sent back the headers
                # in a List<String> so we (obviously) recreate that shape
                results[header.lower()] = [value]
            resp = json.dumps(results).encode('utf-8')
            c_len = len(resp)
            self.send_response(200)
            self.send_header('content-length', str(c_len))
            self.send_header('content-type', 'application/json;charset=utf-8')
            self.end_headers()
            self.wfile.write(resp)
            self.wfile.flush()
        except Exception as e:
            self.log_error('Bogus: %s', str(e))
            self.send_error(500)
            self.send_header('content-length', '0')


if __name__ == '__main__':
    server_address = ('0.0.0.0', 80)
    s = ThreadingHTTPServer(server_address, IntrospectionHandler)
    # noinspection PyBroadException
    try:
        s.serve_forever()
    except Exception:
        s.shutdown()
