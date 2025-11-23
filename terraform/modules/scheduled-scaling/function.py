import base64
import json
import os
import logging
from google.cloud import container_v1
from kubernetes import client, config
from kubernetes.client.rest import ApiException

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(name)

def get_gke_credentials(project_id, region, cluster_name):
"""Get GKE cluster credentials"""
cluster_manager = container_v1.ClusterManagerClient()
cluster_path = f"projects/{project_id}/locations/{region}/clusters/{cluster_name}"

try:
    cluster = cluster_manager.get_cluster(name=cluster_path)
    
    # Configure Kubernetes client
    configuration = client.Configuration()
    configuration.host = f"https://{cluster.endpoint}"
    configuration.verify_ssl = True
    configuration.api_key = {"authorization": "Bearer " + cluster_manager.transport._credentials.token}
    
    client.Configuration.set_default(configuration)
    return True
except Exception as e:
    logger.error(f"Failed to get GKE credentials: {e}")
    return False
def scale_deployment(event, context):
"""
Cloud Function to scale GKE deployment
Triggered by Pub/Sub message from Cloud Scheduler
"""
# Get configuration from environment
project_id = os.environ.get('PROJECT_ID')
region = os.environ.get('REGION')
cluster_name = os.environ.get('CLUSTER_NAME')

# Decode Pub/Sub message
if 'data' in event:
    message_data = base64.b64decode(event['data']).decode('utf-8')
    config_data = json.loads(message_data)
else:
    logger.error("No data in Pub/Sub message")
    return {'status': 'error', 'message': 'No data in message'}, 400

deployment_name = config_data.get('deployment')
namespace = config_data.get('namespace', 'default')
replicas = config_data.get('replicas')

logger.info(f"Scaling {deployment_name} in namespace {namespace} to {replicas} replicas")

# Get GKE credentials
if not get_gke_credentials(project_id, region, cluster_name):
    return {'status': 'error', 'message': 'Failed to authenticate'}, 500

# Scale the deployment
try:
    apps_v1 = client.AppsV1Api()
    
    # Get current deployment
    deployment = apps_v1.read_namespaced_deployment(
        name=deployment_name,
        namespace=namespace
    )
    
    # Update replica count
    deployment.spec.replicas = replicas
    
    # Patch the deployment
    apps_v1.patch_namespaced_deployment(
        name=deployment_name,
        namespace=namespace,
        body=deployment
    )
    
    logger.info(f"Successfully scaled {deployment_name} to {replicas} replicas")
    
    return {
        'status': 'success',
        'deployment': deployment_name,
        'namespace': namespace,
        'replicas': replicas
    }, 200
    
except ApiException as e:
    logger.error(f"Kubernetes API error: {e}")
    return {
        'status': 'error',
        'message': str(e)
    }, 500
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    return {
        'status': 'error',
        'message': str(e)
    }, 500
