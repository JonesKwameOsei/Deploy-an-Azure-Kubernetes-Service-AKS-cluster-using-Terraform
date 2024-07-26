# Deploy-an-Azure-Kubernetes-Service-AKS-cluster-using-Terraform

Create, deploy and manage clusters in Azure Kubernetes Services with Terraform. 

In this project, I will utilise **Azure Kubernetes Service (AKS)**, which is a managed kubernetes services to deploy and managed cluster. I will:

* Deploy an AKS cluster using Terraform. 
* Run a sample multi-container application with a group of microservices and web front ends simulating a retail scenario. 

Amongst the resources to be created are: 

- A random value for the Azure resource group name using `random_pet`.
- An Azure resource group using `azurerm_resource_group`.
- Access the configuration of the AzureRM provider to get the Azure Object ID using `azurerm_client_config`.
- A Kubernetes cluster using `azurerm_kubernetes_cluster`.
- An `AzAPI` resource `azapi_resource`.
- An AzAPI resource to generate an `SSH key pair` using `azapi_resource_action`

Here’s the edited text in GitHub-flavored Markdown:


## Authenticate using the Azure CLI

Terraform must authenticate to Azure to create the infrastructure resources I need.

I will use the `Azure CLI` tool to set up my account permissions locally.

```bash
$ az login
```

Or, I can use this command if I have already logged into my account:

```bash
$ az account show
```

This opens my browser and prompts me to enter my Azure login credentials. After successful authentication, the terminal will display my subscription information.

![az login](images/az-login.png)

```You have logged in. Now let us find all the subscriptions to which you have access...```

```json
[
  {
    "cloudName": "AzureCloud",
    "homeTenantId": "0envbwi39-home-Tenant-Id",
    "id": "35akss-subscription-id",
    "isDefault": true,
    "managedByTenants": [],
    "name": "Subscription-Name",
    "state": "Enabled",
    "tenantId": "0envbwi39-TenantId",
    "user": {
      "name": "your-username@domain.com",
      "type": "user"
    }
  }
]
```

The `id` column displays the subscription account I want to use.

Once I have chosen the account subscription ID, I will set the account with the Azure CLI.

```bash
$ az account set --subscription "35akss-subscription-id"
```

## Create a Service Principal

Next, I will create a `Service Principal`. A Service Principal is an application within Azure Active Directory with the authentication tokens Terraform needs to perform actions on my behalf.

```bash
$ az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<SUBSCRIPTION_ID>"
```

```Creating 'Contributor' role assignment under scope '/subscriptions/35akss-subscription-id'. The output includes credentials that you must protect. Be sure that you do not include these credentials in your code or check the credentials into your source control. For more information, see [Azure AD Service Principal CLI](https://aka.ms/azadsp-cli).```

```json
{
  "appId": "xxxxxx-xxx-xxxx-xxxx-xxxxxxxxxx",
  "displayName": "azure-cli-2022-xxxx",
  "password": "xxxxxx~xxxxxx~xxxxx",
  "tenant": "xxxxx-xxxx-xxxxx-xxxx-xxxxx"
}
```

## Setting Environment Variables

Going by HashiCorp's recommendations, I will set these values as environment variables rather than saving them in the Terraform configuration.

### Windows with PowerShell

In your PowerShell terminal, set the following environment variables. Be sure to update the variable values with the values Azure returned in the previous command.

```powershell
$Env:ARM_CLIENT_ID = "<APPID_VALUE>"
$Env:ARM_CLIENT_SECRET = "<PASSWORD_VALUE>"
$Env:ARM_SUBSCRIPTION_ID = "<SUBSCRIPTION_ID>"
$Env:ARM_TENANT_ID = "<TENANT_VALUE>"
```

### macOS/Linux Terminal

```bash
export ARM_CLIENT_ID="<APPID_VALUE>"
export ARM_CLIENT_SECRET="<PASSWORD_VALUE>"
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
export ARM_TENANT_ID="<TENANT_VALUE>"
```
## Write Configuration

1. I will create a directory called Terraform where all configurations will be written to. 

2. I will configure the following:

- **providers.tf**: The provider block is used to configure the specified provider, in this instance azurerm. A provider is a plugin utilized by Terraform for creating and managing resources.

- **main.tf**: Resource blocks consist of parameters to customize the resources. It defines components of the infrastructure. 

- **variables.tf**: This is use to define input variables for the configurations in a centralised manner. This promotes reusability, simplifies configuration management, and makes the code more dynamic and flexible by being able to customise values without modifying the main configuration files.

- **outputs.tf**: Using `outputs` in Terraform configurations allows the definition of output values that provide useful information after resource creation, such as `resource IDs` or `IP addresses`. This helps in sharing data between different modules or for reference in subsequent operations, enhancing visibility and usability of the infrastructure.

- **ssh.tf**: This configurations allows me to configure `SSH` access to resources remotely by defining SSH keys and security settings. This streamlines the process of securely connecting to `VMs` or `Instances`, ensuring proper authentication and access control while automating infrastructure deployment.

### Initialise Terraform Configuration

Execute the terraform init command to initialize the Terraform deployment. This will download the Azure provider needed to manage your Azure resources.

```bash
terraform init -upgrade
```

**Output**:
```
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see      
any changes that are required for your infrastructure. All Terraform commands      
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other    
commands will detect it and remind you to do so if necessary.
```

>Important notes:
>By using the `-upgrade` parameter, we can upgrade the required provider plugins to the latest version that meets the configuration's version constraints.


To ensure that the configuration files are consistently formatted for readability. Here, I will run the `terraform fmt` command to automatically update configurations in the current directory. After formatting, Terraform will confirm if any files were modified. If the configuration file was already correctly formatted, Terraform will not return any file names.

```bash
terraform fmt
```

**Output**: These conguration files were formatted.
```
main.tf
outputs.tf
providers.tf
ssh.tf
variables.tf
```

Also, to ensure that the configuration is both syntactically valid and internally consistent, I will run the `terraform validate` command. This Validates the configuration to confirm its validity, as the example configuration given above is correct and will result in a success message from Terraform.

```bash
terraform validate
Success! The configuration is valid.
```

### Create a Terraform Execution Plan

To create an execution plan, run the following command:

```bash
terraform plan -out main.tfplan
```

**Output**:

```
Plan: 8 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + client_certificate      = (sensitive value)
  + client_key              = (sensitive value)
  + cluster_ca_certificate  = (sensitive value)
  + cluster_password        = (sensitive value)
  + cluster_username        = (sensitive value)
  + host                    = (sensitive value)
  + key_data                = (known after apply)
  + kube_config             = (sensitive value)
  + kubernetes_cluster_name = (known after apply)
  + resource_group_name     = (known after apply)

────────────────────────────────────────────────────────────────────────────────── 

Saved the plan to: main.tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "main.tfplan"
```

#### Key Points

- The `terraform plan` command generates a plan for execution without actually carrying it out. It analyzes the actions required to implement the configuration described in your files, enabling you to confirm that the plan aligns with your intentions before applying any changes to real resources.

- I use the optional `-out` parameter to designate an output file for the plan. By using the `-out` parameter, I can verify that the plan reviewed is the same as the one that is executed.

### Apply a Terraform Execution Plan

To apply the execution plan to the cloud infrastructure, I will run the following command:

```bash
terraform apply main.tfplan
```

>Key Points

- The example `terraform apply` command assumes you previously ran `terraform plan -out main.tfplan`.
- If I had specified a different filename for the `-out` parameter, I would have to use that same filename in the call to `terraform apply`.
- If I also didn't use the `-out` parameter, I would call `terraform apply` without any parameters.

### Verify the Results

To get the Azure resource group name, I will use the following command:

```bash
resource_group_name=$(terraform output -raw resource_group_name)
```

Display the name of your new Kubernetes cluster using the `az aks list` command:

```azurecli
Open Cloud Shell
az aks list \
  --resource-group $resource_group_name \
  --query "[].{\"K8s cluster name\":name}" \
  --output table
```

Get the Kubernetes configuration from the Terraform state and store it in a file that `kubectl` can read using the following command:

```bash
echo "$(terraform output kube_config)" > ./azurek8s
```

Verify the previous command didn't add an ASCII EOT character using the following command:

```console
cat ./azurek8s
```

**Key Points**:

- Seeing `<< EOT` at the beginning and `EOT` at the end, I need to remove these characters from the file. Otherwise, I may receive the following error message: 
  ```
  error: error loading config file "./azurek8s": yaml: line 2: mapping values are not allowed in this context
  ```

Set an environment variable so `kubectl` can pick up the correct config using the following command:

```console
export KUBECONFIG=./azurek8s
```

Verify the health of the cluster using the `kubectl get nodes` command:

```console
kubectl get nodes
```

**Output**:
```
NAME                                STATUS   ROLES    AGE   VERSION
aks-agentpool-36235375-vmss000000   Ready    <none>   71m   v1.29.6
aks-agentpool-36235375-vmss000001   Ready    <none>   71m   v1.29.6
aks-agentpool-36235375-vmss000002   Ready    <none>   70m   v1.29.6
```

**Key Points**:

- When the AKS cluster is created, monitoring was enabled to capture health metrics for both the cluster nodes and pods. These health metrics are available in the Azure portal. For more information on container health monitoring, see [Monitor Azure Kubernetes Service health](https://docs.microsoft.com/en-us/azure/aks/monitor-aks).
- Several key values classified as output when I applied the Terraform execution plan. For example, the host address, AKS cluster username, and AKS cluster password are output.

### View Results in Azure Portal

To view the results in the Azure portal, I will navigate to the Azure portal and select the resource group that was created by Terraform.

**The resource group**<p>
![alt text](images/azure-rg.png)<p>
![alt text](images/azure-rg2.png)<p>
![alt text](images/azure-rg3.png)<p>

**SSH Public Key**<p>
![sshPublicKey](sshkey.png)<p>

**Azure Kubernetes Service Cluster**:<p>
![AKS-k8s](images/AKS-K8s.png)

**Azure Kubernetes Monitorin**:<p>

![aks-k8s montoring](images/AKS-Monitoring.png)<p>
![CPU-onitoring](images/AKS-MonitoringCPU.png)<p>

## Deploy the application

To deploy the application, I will use a manifest file to create all required objects to run the Online Store Application. The Kubernetes manifest file specifies the intended configuration of a cluster, including the container images to be deployed. It encompasses Kubernetes deployments and services including:

* **Store front**: Web application for customers to view products and place orders.
* **Product service**: Web application for customers to view products information.
* **Order service**: Web application for customers to place orders.
* **Rabbit**: Web application for Message queue for an order queue.

> **Note**:
> It is not recommended running stateful containers, such as Rabbit MQ, without persistent storage for production. I am using these for simplicity sake, but in production, it is I will replicate same using managed services, such as `Azure CosmosDB` or `Azure Service Bus`.

### Deployment Strategy

1. In a file named myStoreFrontWebApp.yml, I will create the kubernetes manifest.

2. Cerate a file called configMap.yml with the necessary configuration. This configuration will be referenced in the mainfest file for the rabbitmq deployment. 

3. I will create a file called secret.yml to create secrets for the microservices deployments. This file contains the credentials for logins. 

## Applying the Manifests

I need to ensure that the ConfigMap and secret manifests are applied before applying the myStoreFrontWebApp manifest so that the deployment can reference the existing ConfigMap and secrets.

To apply the manifest, I will run the following command:
 1. Apply the ConfigMap: <p>

```sh
kubectl apply -f configmap.yaml
```
2. Apply the secrets

```sh
kubectl apply -f secret.yaml
``` 

3. Apply the myStoreFrontWebApp.yml

```sh
kubectl apply -f myStoreFrontWebApp.yml
```






