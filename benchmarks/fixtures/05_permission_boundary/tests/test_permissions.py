import copy
import unittest

from app.permissions import can_edit_document


DOCUMENT = {"owner_id": "owner-1", "team_id": "team-a"}


class PermissionTests(unittest.TestCase):
    def test_admin_and_owner_can_edit(self) -> None:
        admin = {"id": "admin-1", "team_id": "team-b", "role": "admin"}
        owner = {"id": "owner-1", "team_id": "team-b", "role": "viewer"}
        self.assertTrue(can_edit_document(admin, DOCUMENT))
        self.assertTrue(can_edit_document(owner, DOCUMENT))

    def test_same_team_editor_can_edit(self) -> None:
        editor = {"id": "editor-1", "team_id": "team-a", "role": "editor"}
        self.assertTrue(can_edit_document(editor, DOCUMENT))

    def test_viewer_and_other_team_editor_cannot_edit(self) -> None:
        viewer = {"id": "viewer-1", "team_id": "team-a", "role": "viewer"}
        outsider = {"id": "editor-2", "team_id": "team-b", "role": "editor"}
        self.assertFalse(can_edit_document(viewer, DOCUMENT))
        self.assertFalse(can_edit_document(outsider, DOCUMENT))

    def test_inputs_are_not_mutated(self) -> None:
        user = {"id": "viewer-1", "team_id": "team-a", "role": "viewer"}
        original_user = copy.deepcopy(user)
        original_document = copy.deepcopy(DOCUMENT)
        can_edit_document(user, DOCUMENT)
        self.assertEqual(user, original_user)
        self.assertEqual(DOCUMENT, original_document)


if __name__ == "__main__":
    unittest.main()
