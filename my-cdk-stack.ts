import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as iam from 'aws-cdk-lib/aws-iam';

const app = new cdk.App();

// Create a VPC
const vpc = new ec2.Vpc(app, 'MyVPC', {
  cidr: '10.30.0.0/16',
  maxAzs: 2, 
  natGateways: 1, 
});

// Create an IAM Role for EC2
const ec2Role = new iam.Role(app, 'EC2Role', {
  assumedBy: new iam.ServicePrincipal('ec2.amazonaws.com'),
});

// Attach an EC2 S3 full-access policy to the role
ec2Role.addManagedPolicy(
  iam.ManagedPolicy.fromAwsManagedPolicyName('AmazonS3FullAccess')
);

// Create an EC2 instance in a public subnet
const ec2Instance = new ec2.Instance(app, 'EC2Instance', {
  instanceType: ec2.InstanceType.of(ec2.InstanceClass.T2, ec2.InstanceSize.MICRO),
  machineImage: ec2.MachineImage.latestAmazonLinux(),
  vpc,
  role: ec2Role,
  vpcSubnets: { subnetType: ec2.SubnetType.PUBLIC },
});

// Create an SQS Queue
const sqsQueue = new sqs.Queue(app, 'MyQueue', {
  visibilityTimeout: cdk.Duration.seconds(300),
});

// Create an SNS Topic
const snsTopic = new sns.Topic(app, 'MyTopic');

// Create AWS Secrets Manager Secret
const secret = new secretsmanager.Secret(app, 'MySecret', {
  secretName: 'metrodb-secrets',
  generateSecretString: {
    secretStringTemplate: JSON.stringify({ Username: 'your-username' }),
    generateStringKey: 'Password',
  },
});

app.synth();
