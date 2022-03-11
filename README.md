# devops-challenge

This project was created to solve a challenge where several machines are deployed in multi availability zones in a region of AWS.

The following features will be deployed:

* Must be allowed to read files from an S3 bucket you’ve created. 
* Inside an autoscaling group with scaling policies 
  * scale-in: CPU utilization > 80% 
  * scale-out: CPU utilization < 60% 
  * minimum number of instances = 1 
  * maximum number of instances = 3 
* Inside a private subnet 
* Under a public load balancer 
* Install a webserver (Apache, NGINX, etc) through bootstrapping 
* The webserver should be accessible only through the load balancer 

## Prerequisites

* Install ![tfenv](https://github.com/tfutils/tfenv)
* Install terraform version required:
```sh
  tfenv install 1.1.7
```
## Configuring AWS CLI credentials

Before configuring the AWS CLI you should have the following prerequisites:

- [Access key ID](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds) → must be generated from your IAM user or request help to generate it.
- [Secret access key](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds) → must be generated from your IAM user or request help to generate it.
- [AWS Region](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-region) → depends on the environment
- [Output format](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-format) → **json**

* Edit the file ~/.aws/config and complete with the following information.
```
[profile organization]
region = us-east-1
source_profile = organization
```

As you can see, we are generating a profile named above. 

These profile indicates that their source profile is organization, so now we must configure this source profile in our credentials file ~/.aws/credentials

```
[organization]
aws_access_key_id = your_access_key_id
aws_secret_access_key = your_secret_access_key
output=json
region= your_aws_region
```

Now, since we do not have a default profile configured, **we must indicate to the AWS CLI with which profile we will be connecting to the AWS API.**

We will do this by **declaring the environment variable AWS_PROFILE**
```sh
  export AWS_PROFILE=organization
```

## Creating tfstate bucket

You need to create a s3 bucket to save the tfstate. For that:

* Change the name of the bucket and aws region in `providers.tf` file:
```sh
  backend "s3" {
    bucket = "<your_bucket_here>"
    key    = "terraform.tfstate"
    region = "<your_aws_region_here>"
  }
```
* Create the bucket with this command:
```sh
aws s3api create-bucket --acl private --bucket <your_bucket_here> --region <your_aws_region_here>
```

**If you want to deploy using tfstate in local file comment the lines mentioned above**

## Deploying

* Check the vars in `terraform.tfvars` to customize your deploy. You can check `variables.tf` file to see a description of variables.
* Use the terraform init command to initialize a working directory containing Terraform providers and external code:
```sh
terraform init
```
* Use terraform plan command to create an execution plan.
```sh
terraform plan
```
* Use terraform apply command to apply the changes required to reach the desired state of the infrastructure.
```sh
terraform apply
```
* Use terraform destroy command to destroy the Terraform-managed infrastructure.
```sh
terraform destroy
```
* Use terraform output command to see outputs that you may need to check running services.
```sh
terraform output
```

## Test webserver

* Once finished the deploy with `terraform apply` you will see the output `alb_hostname`. Place this hostname in a browser to access the webserver deployed.

## Security extra feature

* Consider installing a VPN or deploying a bastion host in public subnet to access the ec2 machines
* You can pass a `key_pair_name` created manually by yourself and open SSH port to access the machines.

## Future work

Enable SSM to access machines

# Built With

* [terraform](https://www.terraform.io/) - Terraform is an open-source infrastructure as code software tool that provides a consistent CLI workflow to manage hundreds of cloud services.

# Authors

- Andres Felipe Macías - <felipem1210@gmail.com>