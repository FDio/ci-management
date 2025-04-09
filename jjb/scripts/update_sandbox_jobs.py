#!/usr/bin/env python3

# Copyright (c) 2025 Cisco and/or its affiliates.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


"""
This script edits jjb/vpp/vpp.yaml for job verification in a Jenkins sandbox
environment.
- It updates job names to use a unique prefix based on your login ID.
- It changes node specs from '-prod' to '-sandbox' to run in a Jenkins sandbox
  environment.
- It adds the appropriate Gerrit refspec to the 'branch-refspec'
  field for specific streams. Specify the correct Gerrit refspec in the
  GERRIT_REFSPECS dict. Use the get_gerrit_refspec() bash function in
  .../ci-management/extras/bash/sandbox_test_functions.sh to query gerrit
  for the refspec of HEAD in a branch.

This script outputs a file named jjb/vpp/vpp_sandbox.yaml with the changes
applied. Replace the original vpp.yaml with this file for sandbox testing.

Usage: python3 update_sandbox_jobs.py [input_file]
"""

import sys
import os
import getpass
from ruamel.yaml import YAML


OLD_PREFIX = "vpp-"
NEW_PREFIX = f"{getpass.getuser()}-docker-vpp-"
OLD_NODE_SUFFIX = "-prod"
NEW_NODE_SUFFIX = "-sandbox"

# Map each stream to its GERRIT_REFSPEC
GERRIT_REFSPECS = {
    "master": "refs/changes/80/42580/7",
    "2410":  "refs/changes/62/42562/1",
    "2502":  "refs/changes/61/42561/1",
}

yaml = YAML()
yaml.preserve_quotes = True
yaml.indent(mapping=2, sequence=4, offset=2)

def extract_header_and_yaml(file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()

    header_lines = []
    yaml_start = 0
    for i, line in enumerate(lines):
        if line.strip() == "---":
            header_lines = lines[:i]
            yaml_start = i
            break

    header = ''.join(header_lines)
    yaml_content = ''.join(lines[yaml_start:])
    return header, yaml_content

def update_yaml_items(data):
    for item in data:
        if isinstance(item, dict):
            # --- Project blocks ---
            if "project" in item:
                project = item["project"]

                # 1. Update job names for sandbox
                if "jobs" in project and isinstance(project["jobs"], list):
                    for idx, job in enumerate(project["jobs"]):
                        if isinstance(job, str) and job.startswith(OLD_PREFIX):
                            new_job = job.replace(OLD_PREFIX, NEW_PREFIX, 1)
                            project["jobs"][idx] = new_job

                # 2. Update branch-refspec per stream using mapping
                if "stream" in project:
                    for stream_entry in project["stream"]:
                        if isinstance(stream_entry, dict):
                            for stream_name, stream_data in stream_entry.items():
                                if stream_name in GERRIT_REFSPECS and isinstance(stream_data, dict):
                                    current = stream_data.get("branch-refspec", "")
                                    desired = GERRIT_REFSPECS[stream_name]
                                    if current != desired:
                                        stream_data["branch-refspec"] = desired

            # --- Job-template blocks ---
            if "job-template" in item:
                jt = item["job-template"]

                # 1. Rename job-template name
                if "name" in jt and isinstance(jt["name"], str) and jt["name"].startswith(OLD_PREFIX):
                    old_name = jt["name"]
                    jt["name"] = old_name.replace(OLD_PREFIX, NEW_PREFIX, 1)

                # 2. Update node label
                if "node" in jt and isinstance(jt["node"], str) and OLD_NODE_SUFFIX in jt["node"]:
                    old_node = jt["node"]
                    jt["node"] = old_node.replace(OLD_NODE_SUFFIX, NEW_NODE_SUFFIX)


def main():
    if len(sys.argv) == 2:
        input_file = sys.argv[1]
    else:
        input_file = os.path.join("..", "vpp", "vpp.yaml")

    if not os.path.isfile(input_file):
        print(f"File not found: {input_file}")
        sys.exit(1)

    header, yaml_text = extract_header_and_yaml(input_file)
    data = yaml.load(yaml_text)
    update_yaml_items(data)

    output_file = input_file.replace(".yaml", "_sandbox.yaml")
    with open(output_file, "w") as f:
        if header:
            f.write(header)
        yaml.dump(data, f)

    print(f"\nFile updated and written to {output_file}")

if __name__ == "__main__":
    main()
