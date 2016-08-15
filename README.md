# lambda-cfn-fneach 1.0.1
An AWS Cloudformation Lambda backed Custom resource to allow you to iterate an array and inject each element into a string pattern

## Quickstart

 - Build the Lambda deployment package - `make build`
 - Install the Lambda function - `build/cfn_each.zip`
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
# is equiavalent to
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

The `build/cfn_each.zip` file can then be uploaded to AWS Lambda as a
[Deployment Package](http://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html).

### Deploying

You can deploy the lambda function using the provided template in 
`custom_cfneach.json`. The `CfnEachRole` has no policies attached as cfn_each
only performs string operations, therefore it requires no permissions.
It is recommended to use the template as a example for your own work,
rather than deploying the unmodified template in this repository.

If you want to quickly deploy cfn_each to try it out, you can upload the 
lambda deployment package to s3 and then create a cloudformation stack
which will install the lambda function in your account:

    $ PROFILE=default REGION=eu-west-1 \
        BUCKET=my-lambda-function-bucket \
        make install

You'll need to provide:
 - your profile as set in `~/.aws/credentials` in 
`$PROFILE`
 - the bucket you wish to host your lambda code in `$BUCKET`, and
 - the region you wish to deploy the cloudformation stack into.

### Demo
__NOTE:__ You must have run the above `make install` before running the demo.
If you wish to see how to use cfn_each in a template, you can deploy
another cloudformation stack showing the resource in use:

    $ PROFILE=default REGION=eu-west-1 \
        BUCKET=my-lambda-function-bucket \
        make demo

As above, you'll need to provide:
 - your profile as set in `~/.aws/credentials` in 
`$PROFILE`
 - the bucket you wish to host your lambda code in `$BUCKET`, and
 - the region you wish to deploy the cloudformation stack into.

## Usage

### Properties

#### `List`
This is a list of strings to be injected into the pattern in the 
`{FnEachElement}` placeholder.

__Example__

```json
"MyEachArray": {
    "Type": "Custom::FnEach",
    "Properties": {
        "List": ["first", "second", "third"],
        ...
    }
}
```


#### `Pattern`
A string containing exactly at least one occurence of `{FnEachElement}`.

__Example__

```json
"MyEachArray": {
    "Type": "Custom::FnEach",
    "Properties": {
        "Pattern": "Here is my element string: {FnEachElement}",
        ...
    }
}
```

### Attributes

#### Elements
An expanded list of strings, based on `Pattern` and `List` provided in
the properties

__Example__
```json
"BucketPolicy": {
    "Type": "AWS::S3::BucketPolicy",
    "Properties": {
        "PolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [{
                "Resource": {
                    "Fn::GetAtt": [ "S3AccountArns", "Elements" ]
                },
                ...
            },
            ...
            ]
        }
    }
}
```

## Example

Let's say you wanted to deploy CloudTrail into multiple accounts, where
you have a single S3 bucket aggregating all the logs. As per the
instructions in [Setting Bucket Policy for Multiple Accounts](http://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-set-bucket-policy-for-multiple-accounts.html),
you would need to specify a seperate resource ARN for each key in the 
aws bucket for the `s3:PutObject` action.

If you wanted to create your template to be re-usable (and therefore not
hardcode the ARNs into the template) or did not wish to ingest the ARNs
as a parameter (which is prone to user error, and has potential for
security vulnerabilities), you can use cfn_each to generate the ARNs
based on the composition of a list of AWS Account IDs (`012345678901`,
etc.) and a string pattern (`"arn:aws:s3:::my-bucket/AWSLogs/{FnEachElement}/*"`)
describing the structure of the ARN.

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

If you were to hardcode the ARNs, the equivalent of the above
DocumentPolicy would be:

```json
{
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
        }]
    }
}
```
