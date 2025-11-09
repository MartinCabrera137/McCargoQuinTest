import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/dashboard_page.dart';
import '../features/transactions/presentation/transactions_page.dart';
import '../features/budgets/presentation/budgets_page.dart';
import '../features/history/presentation/history_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (_, __) => const DashboardPage(),
      ),
      GoRoute(
        path: '/transactions',
        name: 'transactions',
        builder: (_, __) => const TransactionsPage(),
      ),
      GoRoute(
        path: '/budgets',
        name: 'budgets',
        builder: (_, __) => const BudgetsPage(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (_, __) => const HistoryPage(),
      ),
    ],
  );
});
