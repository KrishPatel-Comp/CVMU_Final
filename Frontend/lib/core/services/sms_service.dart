import 'package:flutter/foundation.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';
import 'user_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

enum TransactionType { debit, credit, unknown }

class SmsTransaction {
  final String id;
  final String rawBody;
  final String sender;
  final double amount;
  final TransactionType type;
  final String? merchant;
  final String? account;
  final String? upiRef;
  final String? balanceAfter;
  final DateTime date;
  final String category;
  final String? note;

  SmsTransaction({
    required this.id,
    required this.rawBody,
    required this.sender,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    this.note,
    this.merchant,
    this.account,
    this.upiRef,
    this.balanceAfter,
  });

  factory SmsTransaction.fromJson(Map<String, dynamic> json) {
    return SmsTransaction(
      id: json['id'].toString(),
      rawBody: json['raw_sms'] ?? '',
      sender: 'Bank',
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.debit, // Defaulting to debit for simple manual entries
      date: DateTime.parse(json['transaction_date']),
      category: json['category'] ?? 'Other',
      note: json['note'],
      merchant: json['merchant_name'],
    );
  }

  SmsTransaction copyWith({
    String? category,
    String? note,
    double? amount,
    String? merchant,
  }) {
    return SmsTransaction(
      id: id,
      rawBody: rawBody,
      sender: sender,
      amount: amount ?? this.amount,
      type: type,
      date: date,
      category: category ?? this.category,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      account: account,
      upiRef: upiRef,
      balanceAfter: balanceAfter,
    );
  }

  String get typeLabel =>
      type == TransactionType.debit ? 'Debit' : 'Credit';

  String get amountFormatted =>
      '₹${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
}

// ─────────────────────────────────────────────────────────────────────────────
// SMS Service (Singleton)
// ─────────────────────────────────────────────────────────────────────────────

class SmsService extends ChangeNotifier {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final SmsQuery _query = SmsQuery();

  List<SmsTransaction> _transactions = [];
  bool _permissionGranted = false;
  bool _isLoading = false;
  String? _error;

  List<SmsTransaction> get transactions => List.unmodifiable(_transactions);
  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void addManualTransaction(SmsTransaction tx) {
    _transactions.insert(0, tx);
    notifyListeners();
  }

  void setTransactions(List<SmsTransaction> txs) {
    _transactions = txs;
    notifyListeners();
  }

  void updateLocalTransaction(SmsTransaction tx) {
    final index = _transactions.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      _transactions[index] = tx;
      notifyListeners();
    }
  }

  void removeTransaction(String id) {
    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  double get totalDebit => _transactions
      .where((t) => t.type == TransactionType.debit)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalCredit => _transactions
      .where((t) => t.type == TransactionType.credit)
      .fold(0.0, (sum, t) => sum + t.amount);

  void clear() {
    _transactions = [];
    _error = null;
    notifyListeners();
  }

  Future<void> loadBackendTransactions(int userId) async {
    try {
      final backendTxs = await ApiService().getTransactions(userId);
      for (var txJson in backendTxs) {
        final tx = SmsTransaction.fromJson(txJson);
        // Only add if not already present (based on ID or amount/date proxy)
        if (!_transactions.any((t) => t.id == tx.id)) {
          _transactions.add(tx);
        }
      }
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading backend transactions: $e');
    }
  }

  // ── Public: Request Permission & Load ─────────────────────────────────────

  Future<bool> requestPermissionAndLoad() async {
    if (kIsWeb) {
      _permissionGranted = true;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Ask Android OS for READ_SMS at runtime
    final status = await Permission.sms.request();
    _permissionGranted = status == PermissionStatus.granted;

    if (!_permissionGranted) {
      _isLoading = false;
      _error = 'SMS permission denied by user.';
      notifyListeners();
      return false;
    }

    await _readInbox();

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ── Private: Read Inbox ───────────────────────────────────────────────────

  Future<void> _readInbox() async {
    try {
      // Fetch up to 1000 SMS to ensure we don't miss anything (it takes < 1s to parse)
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 1000,
      );

      debugPrint('[SmsService] Total SMS fetched: ${messages.length}');

      final parsed = <SmsTransaction>[];
      for (final msg in messages) {
        final tx = _parseMessage(msg);
        if (tx != null) {
          // Check if already in _transactions (either from backend or already parsed)
          if (!_transactions.any((t) => (t.amount == tx.amount && 
              t.date.year == tx.date.year && 
              t.date.month == tx.date.month && 
              t.date.day == tx.date.day && 
              t.merchant == tx.merchant))) {
            parsed.add(tx);
            // Optionally upload to backend if user is logged in
            if (UserService.userId != null) {
              _uploadToBackend(tx);
            }
          }
        }
      }

      _transactions.addAll(parsed);
      _transactions.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('[SmsService] Added ${parsed.length} new transactions from SMS.');
    } catch (e) {
      _error = 'Failed to read SMS inbox: $e';
      debugPrint('[SmsService] Error: $e');
    }
  }

  Future<void> _uploadToBackend(SmsTransaction tx) async {
    try {
      await ApiService().createTransaction(
        userId: UserService.userId!,
        amount: tx.amount,
        merchantName: tx.merchant ?? 'Unknown',
        category: tx.category,
        note: tx.note,
        rawSms: tx.rawBody,
      );
    } catch (e) {
      debugPrint('Error uploading SMS transaction to backend: $e');
    }
  }

  // ── Parser ────────────────────────────────────────────────────────────────

  SmsTransaction? _parseMessage(SmsMessage msg) {
    final body = msg.body ?? '';
    final sender = msg.sender ?? '';
    final date = msg.date ?? DateTime.now();
    final id = '${msg.id ?? date.millisecondsSinceEpoch}';

    // Only process bank / financial SMS
    if (!_isFinancialSms(body, sender)) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    final merchant = _extractMerchant(body);
    final type = _extractType(body, hasMerchant: merchant != null && merchant.isNotEmpty);
    final account = _extractAccount(body);
    final upiRef = _extractUpiRef(body);
    final balance = _extractBalance(body);
    final category = _categorize(body, merchant);

    return SmsTransaction(
      id: id,
      rawBody: body,
      sender: sender,
      amount: amount,
      type: type,
      date: date,
      category: category,
      merchant: merchant,
      account: account,
      upiRef: upiRef,
      balanceAfter: balance,
    );
  }

  // ── Filters & Regexes ─────────────────────────────────────────────────────

  static const _financialSenders = [
    'bank', 'sbi', 'hdfc', 'icici', 'axis', 'kotak', 'pnb', 'boi',
    'canara', 'indus', 'yes', 'iob', 'ubi', 'cbi', 'federal',
    'paytm', 'gpay', 'phonepe', 'upi', 'amazon', 'bajaj',
    'rbl', 'idfc', 'au ', 'dcb',
  ];
  bool _isFinancialSms(String body, String sender) {
    if (body.isEmpty) return false;
    final sLower = sender.toLowerCase();
    final bLower = body.toLowerCase();

    // Look for basic "money" signs. Currency isn't always followed by a space or dot.
    final hasCurrency = bLower.contains('rs') || bLower.contains('inr') || bLower.contains('₹') || bLower.contains('amt');

    // Action verbs that indicate a physical transaction happened
    final hasAction = [
      'debited', 'credited', 'paid', 'sent to', 'received from', 'spent',
      'transferred', 'withdrawn', 'payment', 'txn', 'upi ref', 'a/c', 'charged'
    ].any((kw) => bLower.contains(kw));

    // Known bank/fintech shortcodes like "AD-SBIINB" or "JX-KOTAKB"
    final senderKeywords = _financialSenders.any((s) => sLower.contains(s));
    final isShortCode = RegExp(r'^[A-Z0-9]{2}-[A-Z0-9]{5,8}$', caseSensitive: false).hasMatch(sender);

    // If it has BOTH currency and a transaction action, it's almost certainly financial.
    // If it's from a bank shortcode and has an action keyword, we scan it.
    return (hasCurrency && hasAction) || (senderKeywords && hasAction) || (isShortCode && hasCurrency);
  }

  double? _extractAmount(String body) {
    final patterns = [
      // ₹1,234.56 or Rs.1234 or INR 1234
      RegExp(r'(?:rs\.?|inr|₹|rs)\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      // Catch "debited for 500" or "paid 500"
      RegExp(r'(?:debited\s+for|paid|spent|sent|received)\s+([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false),
      RegExp(r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:rs\.?|inr|₹)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        final raw = m.group(1)!.replaceAll(',', '');
        final val = double.tryParse(raw);
        if (val != null && val > 0 && val < 5000000) return val;
      }
    }
    return null;
  }

  /// Debit = money out (sent, paid). Credit = money in (received).
  /// Rule: (1) Debit keywords → debit. (2) Merchant name present → debit (you paid someone).
  /// (3) Credit keywords → credit. (4) No merchant, no debit keyword → credit.
  TransactionType _extractType(String body, {bool hasMerchant = false}) {
    final lower = body.toLowerCase();

    // 1) Debit keywords: sent, debit, paid, etc. — focus on these for outbound
    const debitKeywords = [
      'debited', 'debit', 'paid', 'payment sent', 'withdrawn', 'purchase',
      'sent to', 'sent ', 'transferred to', 'spent', 'has been sent', 'was sent',
      'amount sent', 'you sent', 'sent rs', 'sent inr', 'sent.', 'sent:',
      'payment of', 'charged', 'deducted', 'withdrawal', 'paid to', 'paid at',
      'received by', // "payment received by X" = you sent
    ];
    for (final kw in debitKeywords) {
      if (lower.contains(kw)) return TransactionType.debit;
    }

    // 2) Merchant/payee name present → you paid someone → debit
    if (hasMerchant) return TransactionType.debit;

    // 3) Credit keywords: money into your account
    const creditKeywords = [
      'credited to your', 'credited in your', 'credited with', 'credited in a/c',
      'received from', 'received in your', 'added', 'deposited',
      'transferred from', 'refund', 'cashback', 'payment received',
    ];
    for (final kw in creditKeywords) {
      if (lower.contains(kw)) return TransactionType.credit;
    }
    if (lower.contains('credited') || RegExp(r'\breceived\b').hasMatch(lower)) {
      return TransactionType.credit;
    }

    // 4) No merchant, no clear debit keyword → treat as credit (inbound)
    return TransactionType.credit;
  }

  String? _extractMerchant(String body) {
    // Look for common merchant extraction patterns in Indian banking SMS
    final patterns = [
      // "to XYZ" or "at XYZ" or "sent to XYZ"
      RegExp(r'(?:to|at|sent\s+to|paid\s+to|spent\s+at)\s+([A-Za-z0-9\s&\.\-@]{3,30?})(?:\s+(?:via|on|using|upi|ref|a\/c|from)|[.,!\n]|$)', caseSensitive: false),
      // VPA / UPI ID
      RegExp(r'(?:vpa|upi)[:\s]+([a-z0-9.\-_]+@[a-z]+)', caseSensitive: false),
      // Merchant info at the end
      RegExp(r'at\s+([A-Za-z0-9\s]{3,20})\s*$', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(body);
      if (m != null) {
        final name = m.group(1)?.trim();
        if (name != null && name.length > 2) {
          // Clean up common noise
          return name.replaceAll(RegExp(r'\s+on$|\s+at$|\s+using$|\s+via$'), '').trim();
        }
      }
    }
    return null;
  }

  String? _extractAccount(String body) {
    final m = RegExp(
      r'(?:a\/c|ac|acct|account|card)[:\s#]*(?:xx+|x+|\*+)?([0-9]{4})',
      caseSensitive: false,
    ).firstMatch(body);
    return m != null ? 'XX${m.group(1)}' : null;
  }

  String? _extractUpiRef(String body) {
    final m = RegExp(
      r'(?:ref|utr|txn|transaction\s*id)[:\s#.]*([0-9]{6,20})',
      caseSensitive: false,
    ).firstMatch(body);
    return m?.group(1);
  }

  String? _extractBalance(String body) {
    final m = RegExp(
      r'(?:avl|avail(?:able)?|bal(?:ance)?)[:\s]*(?:rs\.?|inr|₹)?\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ).firstMatch(body);
    return m != null ? '₹${m.group(1)}' : null;
  }

  String _categorize(String body, String? merchant) {
    final t = '${body.toLowerCase()} ${merchant?.toLowerCase() ?? ''}';
    
    // SHOPPING
    if (_has(t, ['amazon', 'flipkart', 'myntra', 'meesho', 'ajio', 'nykaa', 'shop', 'store', 'mall', 'shopee', 'fashion', 'clothing', 'retail', 'bigbasket', 'blinkit', 'zepto', 'grofers', 'grocery'])) return 'Shopping';
    
    // FOOD & DINING
    if (_has(t, ['swiggy', 'zomato', 'eats', 'uber eats', 'dineout', 'restaurant', 'cafe', 'food', 'biryani', 'pizza', 'dining', 'bakery', 'kfc', 'mcdonald', 'burger', 'starbucks', 'chai', 'tea', 'hotel', 'dhaba'])) return 'Food & Dining';
    
    // TRANSPORT
    if (_has(t, ['uber', 'ola', 'rapido', 'metro', 'irctc', 'railway', 'bus', 'petrol', 'fuel', 'transport', 'cab', 'shell', 'hpcl', 'bpcl', 'iocl', 'ride', 'travel', 'indigo', 'goair', 'airindia', 'flight'])) return 'Transport';
    
    // BILLS
    if (_has(t, ['electricity', 'airtel', 'jio', 'vi ', 'bsnl', 'broadband', 'bill', 'recharge', 'utility', 'water', 'gas', 'indane', 'hpgas', 'tatasky', 'dish', 'dth', 'postpaid', 'insurance', 'lic', 'premium', 'policy'])) return 'Bills & Utilities';
    
    // HEALTH
    if (_has(t, ['hospital', 'clinic', 'pharmacy', 'medicine', 'doctor', 'health', 'apollo', 'medplus', 'pharmeasy', '1mg', 'diagnostic', 'lab', 'dental', 'vision'])) return 'Health';
    
    // INCOME
    if (_has(t, ['salary', 'payroll', 'stipend', 'credited by', 'dividend', 'interest', 'bonus'])) return 'Income';
    
    // MISC
    if (_has(t, ['cash withdrawn', 'atmx', 'atm withdrawal', 'cash dispense'])) return 'Cash Withdrawal';
    if (_has(t, ['emi', 'loan', 'repayment', 'bajaj', 'home credit', 'fullerton', 'muthoot', 'finance'])) return 'EMI / Finance';

    return 'Other';
  }

  bool _has(String text, List<String> keywords) {
    for (var k in keywords) {
      if (text.contains(k)) return true;
    }
    return false;
  }
}
