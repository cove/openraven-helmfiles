#!/usr/bin/env python3

import re
import json
import os
from datetime import datetime
import yaml

with open('k8s.yml') as f:
    all_docs = list(yaml.safe_load_all(f))

charts = []
for d in all_docs:
    if d is None:
        continue
    if 'labels' in d['metadata']:
        for label in ['chart', 'helm.sh/chart']:
            chart_label = d['metadata']['labels'].get(label)
            if chart_label:
                charts.append(chart_label)

charts = sorted(list(set(charts)))

r = re.compile(r'^(?P<name>\S+)-(?P<version>\S+\.\S+\.\S+)$')
manifest = {"charts": []}
for c in charts:
    for m in r.finditer(c):
        chart = dict(m.groupdict())
        if os.path.isdir(os.path.join(os.getcwd(), 'charts', chart['name'])):
            chart['external'] = False
        else:
            chart['external'] = True

        manifest['charts'].append(chart)

manifest['helmfile_git_ref'] = os.environ['CI_COMMIT_SHA']
manifest['timestamp'] = datetime.now(tz=None).isoformat()
manifest['build_id'] = os.environ['CI_PIPELINE_ID']
with open('manifest.json', 'w') as outfile:
    json.dump(manifest, outfile)
