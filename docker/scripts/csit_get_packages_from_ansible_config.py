#! /usr/bin/env python3

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
        cays = CsitAnsibleYamlStruct(**csit_ansible_yaml)
        packages = [pkg for pkg in cays.packages_base if type(pkg) is str]
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
        elif arg.lower() == '--centos':
            distro = 'centos'
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

