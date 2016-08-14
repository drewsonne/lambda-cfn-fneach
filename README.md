# lambda-cfn-fneach
An AWS Cloudformation Lambda backed Custom resource to allow you to iterate an array and inject each element into a string pattern

## Installation

### Building
You can build the package to be uploaded to AWS Lambda, by running:

    $ make build


## Fn::Each
Allows a pattern to be applied on an array of strings

### Example

    "MyLoop": {
        "Type": "Custom::FnEach",
        "Properties": {
            "List": [
                "369805285720
                "438622327569",
                "215568239958",
                "310009957296"
            ],
            "Pattern": {
                "Fn::Join": ["", [
                    "arn:aws:s3:::",{"Ref": "BucketName"},"/AWSLogs/{FnEachElement}/*"
                ]]
            },
            "ServiceToken": "arn:aws:lambda:eu-west-1:AccountId:function:CloudFormationFnEach"
        }
    }
