import json
import os
import boto3
import requests
from botocore.exceptions import ClientError


def get_jira_credentials(secret_name: str, region: str) -> dict:
    client = boto3.client("secretsmanager", region_name=region)
    try:
        response = client.get_secret_value(SecretId=secret_name)
        return json.loads(response["SecretString"])
    except ClientError as e:
        raise RuntimeError(f"Failed to retrieve Jira credentials from Secrets Manager: {e}") from e


def build_adf_description(text: str) -> dict:
    """Atlassian Document Format (ADF) wrapper for plain text."""
    return {
        "type": "doc",
        "version": 1,
        "content": [
            {
                "type": "paragraph",
                "content": [{"type": "text", "text": text}],
            }
        ],
    }


def create_jira_ticket(
    credentials: dict,
    project_key: str,
    summary: str,
    description: str,
    issue_type: str,
) -> dict:
    url = f"{credentials['jira_url'].rstrip('/')}/rest/api/3/issue"
    response = requests.post(
        url,
        json={
            "fields": {
                "project": {"key": project_key},
                "summary": summary,
                "description": build_adf_description(description),
                "issuetype": {"name": issue_type},
            }
        },
        auth=(credentials["jira_email"], credentials["jira_api_token"]),
        headers={"Accept": "application/json", "Content-Type": "application/json"},
        timeout=15,
    )
    response.raise_for_status()
    return response.json()


def extract_event_details(event: dict) -> tuple[str, str]:
    source = event.get("source", "aws.events")
    detail_type = event.get("detail-type", "Scheduled Event")
    detail = event.get("detail", {})

    summary = f"[AWS] {detail_type} — {source}"
    description = (
        f"Event Type : {detail_type}\n"
        f"Source     : {source}\n"
        f"Account    : {event.get('account', 'N/A')}\n"
        f"Region     : {event.get('region', 'N/A')}\n"
        f"Time       : {event.get('time', 'N/A')}\n"
        f"Rule       : {event.get('resources', ['N/A'])[0]}\n\n"
        f"Detail:\n{json.dumps(detail, indent=2)}"
    )
    return summary, description


def handler(event: dict, context) -> dict:
    secret_name = os.environ["JIRA_SECRET_NAME"]
    project_key = os.environ["JIRA_PROJECT_KEY"]
    issue_type = os.environ.get("JIRA_ISSUE_TYPE", "Bug")
    region = os.environ.get("AWS_REGION", "us-east-1")

    print(f"Received event: {json.dumps(event)}")

    credentials = get_jira_credentials(secret_name, region)
    summary, description = extract_event_details(event)
    ticket = create_jira_ticket(credentials, project_key, summary, description, issue_type)

    ticket_key = ticket.get("key")
    ticket_url = f"{credentials['jira_url'].rstrip('/')}/browse/{ticket_key}"
    print(f"Created Jira ticket: {ticket_key} — {ticket_url}")

    return {"statusCode": 200, "ticketKey": ticket_key, "ticketUrl": ticket_url}
