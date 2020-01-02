#!/usr/bin/python3
import boto3
import yaml
import os

session = boto3.Session()
regions = session.get_available_regions('rds')

instancesList = []

for region in regions:
    rdsClient = session.client('rds',region_name=region)
    databases=rdsClient.describe_db_instances()
    if len(databases['DBInstances'])>0:
        for database in databases['DBInstances']:
            if os.environ['USE_FILTER'] == 'true':
                allTags = rdsClient.list_tags_for_resource(
                    ResourceName=database['DBInstanceArn']
                )
                for tag in allTags['TagList']:
                    if tag['Key'] == 'UseExporter' and tag['Value'] == 'true':
                        instancesList.append({'instance': database['DBInstanceIdentifier'], 'region': region})
                        break
            else:
                instancesList.append({'instance': database['DBInstanceIdentifier'], 'region': region})

finalDoc = {'instances': instancesList}
stream = open('/etc/rds_exporter/config.yml', 'w')
yaml.dump(finalDoc, stream, default_flow_style=False, explicit_start=True)
stream.close()
