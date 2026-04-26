"""

"""

import os
import yaml
from pydantic import BaseModel
from typing import List, Optional

class TestConfig(BaseModel):
    name: str
    target: str
    args: List[str] | None = []

class testloader:
    tests = []
    def load_suite(self, file_path):
        with open(file_path, 'r') as f:
            data = yaml.safe_load(f) or {}

        # Handle recursive includes
        base_dir = os.path.dirname(file_path)
        for include in data.get('includes', []):
            include_path = os.path.join(base_dir, include)
            self.load_suite(include_path)

        # Process local tests
        if 'regressions' in data:
            for test_data in data['regressions']:
                test=TestConfig(**test_data) # Validating information
            self.tests.extend(data['regressions'])

        return self.tests

    def get_tests(self, test_name):
        tests_match = []
        for test in self.tests:
            if test["name"] == test_name:
                tests_match.append(test)

        return tests_match

    def print_tests(self):
        print(self.tests)

