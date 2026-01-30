import '../repositories/auth_repository.dart';

class SendEmailVerificationUseCase {
  final AuthRepository repository;

  SendEmailVerificationUseCase(this.repository);

  Future<void> call() async {
    return await repository.sendEmailVerification();
  }
}
