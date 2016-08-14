import hashlib
from cfn_resource import logger, Resource as CfnResource

handler = CfnResource()

@handler.create
def create_each(event, context):
    """
    Return the list of strings injected into the pattern

    :param event:
    :param context:
    :return:
    """
    properties = event['ResourceProperties']

    property_list = properties.get('List')
    logger.info("Received property 'List': "+ str(property_list))
    pattern = properties.get('Pattern')
    logger.info("Received property 'Pattern': "+ str(pattern))

    # Run the
    resource_id, result = _expand(property_list, pattern)
    return {
        'Status': 'SUCCESS',
        'Reason': 'Formatted List into string',
        'PhysicalResourceId': resource_id,
        'Data': {
            'StringList': result
        }
    }


@handler.delete
def delete_each(event, context):
    """
    We don't actually create anything, so there's nothing to delete.

    :param event:
    :param context:
    :return:
    """
    return {
        'Status': 'SUCCESS',
        'PhysicalResourceId': event['PhysicalResourceId'],
        'Data': {},
    }
@handler.update
def update_each(event, context):
    """
    Run create again, just make sure we use the same LogicalResourceId

    :param event:
    :param context:
    :return:
    """
    properties = event['ResourceProperties']

    property_list = properties.get('List')
    pattern = properties.get('Pattern')

    # Run the
    resource_id, result = _expand(property_list, pattern)
    return {
        'Status': 'SUCCESS',
        'PhysicalResourceId': resource_id,
        'Data': {
            'StringList': result
        }
    }


def _expand(strings, pattern):
    """
    Strings to pass into the
    :param strings:
    :param pattern:
    :return:
    """

    result = _format_string(strings, pattern)
    resource_id = _build_resource_id(result)

    return resource_id, result

def _format_string(strings, pattern):
    """
    The meat of the function. This is kept seperate for the purposes of testing.

    :param List[str] strings: Elements to inject into the pattern
    :param str pattern: A string with a substring '{FnEachElement}', where items from the strings list will be injected.
    :return: List[str]
    """
    return map(lambda string: pattern.format(FnEachElement=string), strings)


def _build_resource_id(result):
    """

    :param result:
    :return:
    """
    result_string = str(result)
    return hashlib.md5(result_string.encode()).hexdigest()
