from unittest import TestCase

from cfn_each import _format_string


class Test_format_string(TestCase):
    def test__format_string_plain(self):
        result = _format_string(['a', 'b'], "Letter is {FnEachElement}")
        self.assertEquals(result, ["Letter is a", "Letter is b"])
