# RDS Exporter


An [AWS RDS](https://aws.amazon.com/ru/rds/) exporter for [Prometheus](https://github.com/prometheus/prometheus).
It gets metrics from both [basic CloudWatch Metrics](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MonitoringOverview.html)
and [RDS Enhanced Monitoring via CloudWatch Logs](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.html).

Based on [Technofy/cloudwatch_exporter](https://github.com/Technofy/cloudwatch_exporter),
but very little of the original code remained.

Forked from [Percona RDS exporter](https://github.com/percona/rds_exporter). **Enhancements:**
* Dockerfile was rewritten to multistage build
* Added script `generate_rds_list.py` that creates list of RDS instances.  
Script supports filtering: if `USE_FILTER` environment variable was set with `true` value, only metrics for instances with tag `UseExporter=true` will be listed. 
* Supervisord feature for Docker. RDS_exporter itself does not support configuration file rereading - in Docker it is launched via supervisord.  
Every 20 minutes configuration file is regenerated and rds_exporter is restarted (via cron job).
## Quick start

Create configration file `config.yml` (either manually or via `generate_rds_list.py` script):

```yaml
---
instances:
  - region: us-east-1
    instance: rds-aurora1

  - region: us-east-1
    instance: rds-mysql57
    aws_access_key: AKIAIOSFODNN7EXAMPLE
    aws_secret_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    labels:
      foo: bar
      baz: qux
```

If `aws_access_key` and `aws_secret_key` are present, they are used for that instance.
Otherwise, [default credential provider chain](https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials)
is used, which includes `AWS_ACCESS_KEY_ID`/`AWS_ACCESS_KEY` and `AWS_SECRET_ACCESS_KEY`/`AWS_SECRET_KEY` environment variables, `~/.aws/credentials` file,
and IAM role for EC2.

Returned metrics contain `instance` and `region` labels set. They also contain extra labels specified in the configuration file.

Start exporter by running:
```
rds_exporter
```

To see all flags run:
```
rds_exporter --help
```

Configure Prometheus:

```yaml
---
scrape_configs:
  - job_name: rds-basic
    scrape_interval: 60s
    scrape_timeout: 55s
    metrics_path: /basic
    honor_labels: true
    static_configs:
      - targets:
        - 127.0.0.1:9042

  - job_name: rds-enhanced
    scrape_interval: 10s
    scrape_timeout: 9s
    metrics_path: /enhanced
    honor_labels: true
    static_configs:
      - targets:
        - 127.0.0.1:9042
```

`honor_labels: true` is important because exporter returns metrics with `instance` label set.

### Docker
#### Building
Clone repo and build it as usual docker image:
```
dokcer build . -t rds_exporter 
```

#### Launching
* Pass credentials either via `AWS_ACCESS_KEY_ID`/ `AWS_SECRET_ACCESS_KEY` environment variables or via `~/.aws/credentials` file
* Expose port for exporter
* Pass `USE_FILTER` environment variable if you want to filter instances by tag  

```
docker run -p 9042:9042 -e USE_FILTER=true -e AWS_ACCESS_KEY_ID=<xxxxx> -e AWS_SECRET_ACCESS_KEY=<yyyyy> rds-exporter
```


## Metrics

Exporter synthesizes [node_exporter](https://github.com/prometheus/node_exporter) -like metrics where possible.

You can see a list of basic monitoring metrics [there](https://github.com/percona/rds_exporter/blob/master/basic/testdata/all.txt)
and a list of enhanced monitoring metrics in text files [there](https://github.com/percona/rds_exporter/tree/master/enhanced/testdata).