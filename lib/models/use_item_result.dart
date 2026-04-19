class UseItemResult {
  final bool success;
  final String? errorMessage;

  const UseItemResult.success() : success = true, errorMessage = null;
  const UseItemResult.failure(this.errorMessage) : success = false;
}
