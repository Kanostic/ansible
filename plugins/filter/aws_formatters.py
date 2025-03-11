from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

class FilterModule(object):
    def filters(self):
        return {
            'format_aws_resources': self.format_aws_resources
        }

    def format_aws_resources(self, resources):
        # Process VPCs
        vpcs = []
        for vpc in resources.get('vpcs', []):
            vpc_id = vpc.get('vpc_id')
            vpc_info = {
                'id': vpc_id,
                'name': vpc.get('tags', {}).get('Name', ''),
                'cidr': vpc.get('cidr_block', ''),
                'state': vpc.get('state', ''),
                'subnets': [],
                'route_tables': [],
                'security_groups': []
            }
            vpcs.append(vpc_info)

        # Process Subnets
        for result in resources.get('subnets_info', {}).get('results', []):
            vpc_id = result['item']['vpc_id']
            vpc = next((v for v in vpcs if v['id'] == vpc_id), None)
            if vpc:
                for subnet in result.get('subnets', []):
                    subnet_info = {
                        'id': subnet.get('subnet_id', ''),
                        'name': subnet.get('tags', {}).get('Name', ''),
                        'cidr': subnet.get('cidr_block', ''),
                        'az': subnet.get('availability_zone', '')
                    }
                    vpc['subnets'].append(subnet_info)

        # Process Route Tables
        for result in resources.get('route_tables_info', {}).get('results', []):
            vpc_id = result['item']['vpc_id']
            vpc = next((v for v in vpcs if v['id'] == vpc_id), None)
            if vpc:
                for rt in result.get('route_tables', []):
                    rt_info = {
                        'id': rt.get('route_table_id', ''),
                        'name': rt.get('tags', {}).get('Name', ''),
                        'routes': [{
                            'dest': route.get('destination_cidr_block', ''),
                            'target': route.get('gateway_id', '') or route.get('nat_gateway_id', '') or 'blackhole'
                        } for route in rt.get('routes', [])]
                    }
                    vpc['route_tables'].append(rt_info)

        # Process Security Groups
        for result in resources.get('security_groups_info', {}).get('results', []):
            vpc_id = result['item']['vpc_id']
            vpc = next((v for v in vpcs if v['id'] == vpc_id), None)
            if vpc:
                for sg in result.get('security_groups', []):
                    sg_info = {
                        'id': sg.get('group_id', ''),
                        'name': sg.get('group_name', ''),
                        'description': sg.get('description', '')
                    }
                    vpc['security_groups'].append(sg_info)

        return {'vpcs': vpcs}