# lambda-cfn-fneach
An AWS Cloudformation Lambda backed Custom resource to allow you to iterate an array and inject each element into a string pattern

## Installation

### Building
You can build the package to be uploaded to AWS Lambda, by running:

    $ make build


## Fn::Each
Allows a pattern to be applied on an array of strings

### Example

For example, let's say you wanted to create a bucket policy to allow
multiple accounts to write their CloudTrail logs to a single bucket.
If you don't know the number of accounts you have, you can use the 
`Custom:FnEach` resource, to generate a list of strings, based on those
account ids, and an string pattern for an S3 ARN.

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
                    "List": {
                        "Ref": "AccountIds"
                    },
                    "Pattern": {
                        "Fn::Join": ["", [
                            "arn:aws:s3:::", { "Ref": "CloudTrailBucketName" }, "/AWSLogs/{FnEachElement}/*"
                        ]]
                    },
                    "ServiceToken": "arn:aws:lambda:eu-west-1:AccountId:function:CloudFormationFnEach"
                }
            },
            "Bucket": {
                "Type": "AWS::S3::Bucket",
                "Properties": {
                    "BucketName": { "Ref": "CloudTrailBucketName" }
                }
            },
            "BucketPolicy": {
                "Type": "AWS::S3::BucketPolicy",
                "Properties": {
                    "PolicyDocument": {
                        "Version": "2012-10-17",
                        "Statement": [{
                            "Sid": "AWSCloudTrailWrite20150319"
                            "Effect": "Allow"
                            "Principal": {
                                "Service": "cloudtrail.amazonaws.com"
                            },
                            "Resource": {
                                "Fn::GetAtt": [ "S3AccountArns", "Elements" ]
                            },
                            "Action": "s3:PutObject"
                            "Condition": {
                                "StringEquals": {
                                    "s3:x-amz-acl": "bucket-owner-full-control"
                                }
                            }
                        },
                        ...]
                    }
                }
            }
        }
    }

This means that without hard coding the ARN's, or providing a list of ARNs
the above bucket policy is equivalent to:

    "PolicyDocument": {
        "Version": "2012-10-17",
        "Statement": [{
            "Sid": "AWSCloudTrailWrite20150319"
            "Effect": "Allow"
            "Principal": {
                "Service": "cloudtrail.amazonaws.com"
            },
            "Resource": [
                "arn:aws:s3:::cloudtrail/AWSLogs/012345678901/*",
                "arn:aws:s3:::cloudtrail/AWSLogs/123456789012/*",
                "arn:aws:s3:::cloudtrail/AWSLogs/234567890123/*"
            ],
            "Action": "s3:PutObject"
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    }
