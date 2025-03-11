# plugins/lookup/instance_iterator.py
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = """
    lookup: instance_iterator
    author: aguti045
    version_added: "1.0"
    short_description: Iterates and formats instance data
    description:
        - This lookup takes a list of instance dictionaries and processes them sequentially
    options:
        _terms:
            description: List of instance dictionaries
            required: True
"""

from ansible.plugins.lookup import LookupBase
from ansible.errors import AnsibleError

class LookupModule(LookupBase):
    def run(self, terms, variables=None, **kwargs):
        instances = terms[0]
        if not isinstance(instances, list):
            # If single dictionary is passed, convert it to a list
            instances = [instances]

        formatted_instances = []
        for instance in instances:
            # Format each instance with required fields
            formatted_instance = {
                'region': instance.get('aws_region'),
                'vpc_id': instance.get('vpc_id'),
                'type': instance.get('instance_type'),
                'account': instance.get('aws_account_id'),
                'name': instance.get('name'),
                'key': instance.get('key_name'),
                'command': instance.get('command_to_run'),
                'ami_id': instance.get('ami_id', 'ami-0182f373e66f89c85'),  # Added with default
                'enis': []
            }

            # Process ENIs
            for eni in instance.get('enis', []):
                formatted_eni = {
                    'subnet': eni.get('subnet_id'),
                    'eip': eni.get('associate_eip'),
                    'inbound': eni.get('inbound_rules', []),
                    'outbound': eni.get('outbound_rules', [])
                }
                formatted_instance['enis'].append(formatted_eni)

            formatted_instances.append(formatted_instance)

        # Always return as a list to make loop happy
        return formatted_instances