# StartTech Operations Runbook

## Incident Response
1. **High CPU on Backend**: Check the **Auto Scaling Group** in the AWS Console. If instances are at 100%, verify the `cloudwatch-dashboard.json` metrics.
2. **API 5xx Errors**: Review logs in **CloudWatch Log Insights** using the queries in `monitoring/log-insights-queries.txt`.

## Deployment
* **Infrastructure**: Run `terraform plan` inside the `terraform/` directory before applying.
* **Application**: Pushing to the `main` branch triggers the **Backend CI/CD** pipeline.