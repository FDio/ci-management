#! /usr/bin/env python3

# Copyright (c) 2021 Cisco and/or its affiliates.
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

import os
import pprint
import sys
from typing import List
import yaml
import logging

logging.basicConfig(format='%(message)s')
log = logging.getLogger(__name__)

def print_yaml_struct(yaml_struct, depth=0):
    indent = " " * depth
    for k,v in sorted(yaml_struct.items(), key=lambda x: x[0]):
        if isinstance(v, dict):
            log.warning(f"{indent}{k}")
            print_yaml_struct(v, depth+1)
        else:
            log.warning(f"{indent}{k} {v}")

class CsitAnsibleYamlStruct:
    def __init__(self, **entries):
        self.__dict__.update(entries)

def packages_in_csit_ansible_yaml_file(yamlfile: str, distro, arch) -> list:
    with open(yamlfile) as yf:
        csit_ansible_yaml = yaml.safe_load(yf)
        if csit_ansible_yaml is None:
            return ""
        cays = CsitAnsibleYamlStruct(**csit_ansible_yaml)
        try:
            packages = [pkg for pkg in cays.packages_base if type(pkg) is str]
        except AttributeError:
            return ""
        if arch in [*cays.packages_by_arch]:
            packages += [pkg for pkg in cays.packages_by_arch[arch]
                         if type(pkg) is str]
        if distro in [*cays.packages_by_distro]:
            packages += [pkg for pkg in cays.packages_by_distro[distro]
                         if type(pkg) is str]
        return packages

def is_csit_ansible_yaml_file(filename: str):
     (root,ext) = os.path.splitext(filename)
     if ext == '.yaml' \
        and filename.find('csit/') >= 0 \
        and filename.find('/ansible/') > 0 \
        and os.path.isfile(filename):
         return True
     else:
         return False

def main(args: List[str]) -> None:
    if len(args) < 1:
        log.warning('Must have at least 1 file name')
        return
    pkg_list = []
    distro = 'ubuntu'
    arch = 'x86_64'

    for arg in args:
        if arg.lower() == '--ubuntu':
            distro = 'ubuntu'
        elif arg.lower() == '--x86_64':
            arch = 'x86_64'
        elif arg.lower() == '--aarch64':
            arch = 'aarch64'
        elif is_csit_ansible_yaml_file(arg):
           pkg_list += packages_in_csit_ansible_yaml_file(arg, distro, arch)
        else:
            log.warning(f'Invalid CSIT Ansible YAML file: {arg}')
    pkg_list = list(set(pkg_list))
    pkg_list.sort()
    print(" ".join(pkg_list))

if __name__ == "__main__":
    main(sys.argv[1:])
