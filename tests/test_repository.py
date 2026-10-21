from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class RepositoryTests(unittest.TestCase):
    def test_required_scripts_exist(self):
        for path in [
            'sql/00_preflight.sql', 'sql/01_infrastructure.sql',
            'sql/02_roles_and_grants.sql', 'sql/03_row_access.sql',
            'sql/04_abac_tag_masking.sql', 'sql/05_test_cases.sql',
            'sql/07_validation_enterprise.sql',
            'sql/standard/01_secure_views.sql',
            'sql/standard/02_secure_view_grants.sql',
            'sql/standard/03_secure_view_tests.sql',
        ]:
            with self.subTest(path=path):
                self.assertTrue((ROOT / path).is_file())

    def test_example_data_count(self):
        text = (ROOT / 'sql/01_infrastructure.sql').read_text()
        import re
        ids = re.findall(r"\(100[1-8],", text)
        self.assertEqual(len(ids), 8)

    def test_least_privilege_standard_views(self):
        grants = (ROOT / 'sql/standard/02_secure_view_grants.sql').read_text().upper()
        self.assertNotIn('GRANT SELECT ON TABLE', grants)
        self.assertEqual(grants.count('GRANT SELECT ON VIEW'), 4)

if __name__ == '__main__':
    unittest.main()
