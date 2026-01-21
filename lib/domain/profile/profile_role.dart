enum ProfileRole { layman, clergy, temple, admin }

extension ProfileRoleUi on ProfileRole {
  String get label => switch (this) {
    ProfileRole.layman => 'Мирянин',
    ProfileRole.clergy => 'Священнослужитель',
    ProfileRole.temple => 'Храм',
    ProfileRole.admin => 'Администратор',
  };
}

