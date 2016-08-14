# lambda-cfn-fneach
An AWS Cloudformation Lambda backed Custom resource to allow you to iterate an array and inject each element into a string pattern


## Example
"MyLoop": {
    "Type": "Custom::FnEach",
    "Properties": {
        "List": [
            "307220314736",
            "867042325574",
            "367495186065",
            "776574684150"
        ],
        "Pattern": {
            "Fn::Join": ["", [
                "arn:aws:s3:::",{"Ref": "BucketName"},"/AWSLogs/{FnEachElement}/*"
            ]]
        },
        "ServiceToken": "arn:aws:lambda:eu-west-1:REDACTED:function:CloudFormationFnEach"
    }
}
