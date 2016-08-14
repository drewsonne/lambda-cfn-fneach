# lambda-cfn-fneach 1.0.1
An AWS Cloudformation Lambda backed Custom resource to allow you to iterate an array and inject each element into a string pattern

## Quickstart

 - Build the Lambda deployment package - `make build`
 - Install the Lambda function - `cfn_each.zip`
 - Use the Lambda function in a cloudformation template

```json
"MyEachArray": {
    "Type": "Custom::FnEach",
    "Properties": {
        "List": ["first", "second", "third"],
        "Pattern": "Here is my element string: {FnEachElement}",
        "ServiceToken": "arn:aws:lambda:eu-west-1:012345678901:function:CloudFormationFnEach"
    }
}
```

 - Reference the custom resource

```json
{"Fn::GetAtt": ["MyEachArray", "Elements"]}
## is equiavalent to
[
    "Here is my element string: first",
    "Here is my element string: second",
    "Here is my element string: third"
]
```

## Installation

### Building
You can build the package to be uploaded to AWS Lambda, by running:

    $ make build

The `cfn_each.zip` file can then be uploaded to AWS Lambda as a
[Deployment Package](http://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html).

### Deploying

You can deploy the lambda function using the provided template in 
`custom_cfneach.json`. The `CfnEachRole` has no policies attached as the
resources performs only string operations and requires no permissions.
It is recommended to use the template as a base, rather than deploying
it as it.

If you want to quickly deploy the function to try it out, you can run:

    $ PROFILE=default REGION=eu-west-1 \
        BUCKET=my-lambda-function-bucket \
        make install

using your profile as set in `~/.aws/credentials` in `$PROFILE`, and the
bucket you wish to host your lambda code in `$BUCKET`.

### Demo
If you wish to see the custom resource in a demo, simliar to the above, you can run:

    $ PROFILE=default REGION=eu-west-1 \
        BUCKET=my-lambda-function-bucket \
        make demo
__NOTE:__ You must have run the above `make install` before running the demo.


## Usage

### Properties

#### `List`
This is a list of strings to be injected into the pattern in the 
`{FnEachElement}` placeholder.

#### `Pattern`
A string containing exactly at least one occurence of `{FnEachElement}`.

### Attributes

#### Elements
An expanded list of strings, based on `Pattern` and `List` provided in
the properties

## Example

For example, let's say you wanted to create a bucket policy to allow
multiple accounts to write their CloudTrail logs to a single bucket.
If you don't know the number of accounts you have, you can use the 
`Custom:FnEach` resource, to generate a list of strings, based on those
account ids, and an string pattern for an S3 ARN.

```json
    {
        "Parameters": {
            "AccountIds": {
                "Type": "CommaDelimitedList",
                "Description": "A list of accounts who are allowed to write to this bucket.",
                "Default": ["012345678901", "123456789012", "234567890123"]
            },
            "CloudTrailBucketName": {
                "Type": "String",
                "Description": "Name of the S3 bucket to put cloud trail logs into",
                "Default": "cloudtrail"
            }
        },
        "Resources": {
            "S3AccountArns": {
                "Type": "Custom::FnEach",
                "Properties": {
                    "List": { "Ref": "AccountIds" },
                    "Pattern": {
                        "Fn::Join": ["", [
                            "arn:aws:s3:::", { "Ref": "CloudTrailBucketName" }, "/AWSLogs/{FnEachElement}/*"
                        ]]
                    },
                    "ServiceToken": "arn:aws:lambda:eu-west-1:012345678901:function:CloudFormationFnEach"
                }
            },
            "BucketPolicy": {
                "Type": "AWS::S3::BucketPolicy",
                "Properties": {
                    "PolicyDocument": {
                        "Version": "2012-10-17",
                        "Statement": [{
                            "Effect": "Allow",
                            "Action": "s3:PutObject",
                            "Resource": {
                                "Fn::GetAtt": [ "S3AccountArns", "Elements" ]
                            },
                            "Principal": {
                                "Service": "cloudtrail.amazonaws.com"
                            },
                            "Condition": {
                                "StringEquals": {
                                    "s3:x-amz-acl": "bucket-owner-full-control"
                                }
                            }
                        },
                        ...
                        ]
                    },
                    "Bucket": {"Ref": "Bucket"}
                }
            },
            "Bucket": {
                "Type": "AWS::S3::Bucket",
                "Properties": {
                    "BucketName": { "Ref": "CloudTrailBucketName" }
                }
            }
        }
    }
```

This means that without hard coding the ARN's, or providing a list of ARNs
the above bucket policy is equivalent to:

```json
    "PolicyDocument": {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": [
                "arn:aws:s3:::cloudtrail/AWSLogs/012345678901/*",
                "arn:aws:s3:::cloudtrail/AWSLogs/123456789012/*",
                "arn:aws:s3:::cloudtrail/AWSLogs/234567890123/*"
            ],
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    }
```
