enum UserRole {
  beneficiary('대상자', '본인의 상담과 돌봄 정보를 확인해요'),
  family('가족', '연결을 허용받은 가족을 함께 돌봐요'),
  staff('담당자', '담당 대상자의 상담과 기록을 관리해요');

  const UserRole(this.label, this.description);
  final String label;
  final String description;
}
