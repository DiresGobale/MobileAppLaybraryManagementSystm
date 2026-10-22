class Loan {
  final int? id;
  final int userId;
  final int bookId;
  final int issuedBy;
  final DateTime issueDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String status; // active | returned | overdue

  Loan({
    this.id,
    required this.userId,
    required this.bookId,
    required this.issuedBy,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
  });

  bool get isActive => status == 'active';
  bool get isReturned => status == 'returned';
  bool get isOverdue => status == 'overdue';

  bool get isCurrentlyOverdue {
    if (isReturned) return false;
    return DateTime.now().isAfter(dueDate);
  }

  factory Loan.fromMap(Map<String, dynamic> m) => Loan(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        bookId: m['book_id'] as int,
        issuedBy: m['issued_by'] as int,
        issueDate: DateTime.fromMillisecondsSinceEpoch(m['issue_date'] as int),
        dueDate: DateTime.fromMillisecondsSinceEpoch(m['due_date'] as int),
        returnDate: m['return_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['return_date'] as int)
            : null,
        status: m['status'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'book_id': bookId,
        'issued_by': issuedBy,
        'issue_date': issueDate.millisecondsSinceEpoch,
        'due_date': dueDate.millisecondsSinceEpoch,
        'return_date': returnDate?.millisecondsSinceEpoch,
        'status': status,
      };

  Loan copyWith({
    int? id,
    int? userId,
    int? bookId,
    int? issuedBy,
    DateTime? issueDate,
    DateTime? dueDate,
    DateTime? returnDate,
    String? status,
  }) =>
      Loan(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        bookId: bookId ?? this.bookId,
        issuedBy: issuedBy ?? this.issuedBy,
        issueDate: issueDate ?? this.issueDate,
        dueDate: dueDate ?? this.dueDate,
        returnDate: returnDate ?? this.returnDate,
        status: status ?? this.status,
      );
}

class LoanDetail {
  final Loan loan;
  final String bookTitle;
  final String bookIsbn;
  final String bookAuthor;
  final String userName;
  final String? userStudentId;
  final String? librarianName;

  LoanDetail({
    required this.loan,
    required this.bookTitle,
    required this.bookIsbn,
    required this.bookAuthor,
    required this.userName,
    this.userStudentId,
    this.librarianName,
  });

  factory LoanDetail.fromMap(Map<String, dynamic> m) => LoanDetail(
        loan: Loan.fromMap(m),
        bookTitle: m['book_title'] as String? ?? '',
        bookIsbn: m['book_isbn'] as String? ?? '',
        bookAuthor: m['book_author'] as String? ?? '',
        userName: m['user_name'] as String? ?? '',
        userStudentId: m['user_student_id'] as String?,
        librarianName: m['librarian_name'] as String?,
      );
}
