class ClassRoomState {
  const ClassRoomState({
    required this.classCode,
    required this.members,
    required this.admins,
    this.isLoading = false,
    this.errorMessage,
  });

  final String classCode;
  final Set<String> members;
  final Set<String> admins;
  final bool isLoading;
  final String? errorMessage;

  ClassRoomState copyWith({
    Set<String>? members,
    Set<String>? admins,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClassRoomState(
      classCode: classCode,
      members: members ?? this.members,
      admins: admins ?? this.admins,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

