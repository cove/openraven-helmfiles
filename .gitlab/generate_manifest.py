#!/usr/bin/env python3

import sys
import re
import json
import os
from datetime import datetime

r = re.compile(r'^(?P<name>\S+)-(?P<version>\S+\.\S+\.\S+)$')
manifest = {"charts": []}
for line in sys.stdin:
    for m in r.finditer(line):
        chart = dict(m.groupdict())
        if os.path.isdir(os.path.join(os.getcwd(), 'charts', chart['name'])):
            chart['external'] = False
        else:
            chart['external'] = True

        manifest['charts'].append(chart)

manifest['helmfile_git_ref'] = os.environ['CI_COMMIT_SHA']
manifest['timestamp'] = datetime.now(tz=None).isoformat()
print(json.dumps(manifest))
