// lib/core/network/realtime_client.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  return RealtimeClient(Supabase.instance.client);
});

class RealtimeClient {
  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeClient(this._supabase);

  RealtimeChannel subscribeToTable({
    required String schema,
    required String table,
    String? filter,
    required void Function(Map<String, dynamic> payload) onChanged,
  }) {
    final channelId = '$schema:$table:${filter ?? 'all'}';
    if (_channels.containsKey(channelId)) {
      return _channels[channelId]!;
    }

    var channel = _supabase.channel(channelId);
    final parsedFilter = _parseFilter(filter);

    if (parsedFilter != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: schema,
        table: table,
        filter: parsedFilter,
        callback: (payload) {
          onChanged(_mapPayload(payload));
        },
      );
    } else {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: schema,
        table: table,
        callback: (payload) {
          onChanged(_mapPayload(payload));
        },
      );
    }

    channel.subscribe();
    _channels[channelId] = channel;
    return channel;
  }

  RealtimeChannel subscribeToUserNotifications({
    required String userId,
    required void Function(Map<String, dynamic> payload) onNewNotification,
  }) {
    return subscribeToTable(
      schema: 'public',
      table: 'notifications',
      filter: 'user_id=eq.$userId',
      onChanged: onNewNotification,
    );
  }

  RealtimeChannel subscribeToLoans({
    String? lenderId,
    required void Function(Map<String, dynamic> payload) onChanged,
  }) {
    final filter = lenderId != null ? 'lender_id=eq.$lenderId' : null;
    return subscribeToTable(
      schema: 'public',
      table: 'loans',
      filter: filter,
      onChanged: onChanged,
    );
  }

  RealtimeChannel subscribeToPayments({
    String? lenderId,
    required void Function(Map<String, dynamic> payload) onChanged,
  }) {
    final filter = lenderId != null ? 'lender_id=eq.$lenderId' : null;
    return subscribeToTable(
      schema: 'public',
      table: 'payments',
      filter: filter,
      onChanged: onChanged,
    );
  }

  RealtimeChannel subscribeToRiderTasks({
    required String riderId,
    required void Function(Map<String, dynamic> payload) onChanged,
  }) {
    return subscribeToTable(
      schema: 'public',
      table: 'disbursements',
      filter: 'assigned_rider_id=eq.$riderId',
      onChanged: onChanged,
    );
  }

  void unsubscribe(String channelId) {
    final channel = _channels.remove(channelId);
    channel?.unsubscribe();
  }

  void unsubscribeAll() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }

  void dispose() {
    unsubscribeAll();
  }

  Map<String, dynamic> _mapPayload(PostgresChangePayload payload) {
    return {
      'eventType': payload.eventType.name,
      'table': payload.table,
      'schema': payload.schema,
      'oldRecord': payload.oldRecord,
      'newRecord': payload.newRecord,
    };
  }

  PostgresChangeFilter? _parseFilter(String? filter) {
    if (filter == null || filter.isEmpty) return null;

    final match = RegExp(r'^(\w+)\s*=\s*(eq|neq|lt|lte|gt|gte|in)\.(.+)$')
        .firstMatch(filter);
    if (match == null) return null;

    final column = match.group(1)!;
    final op = match.group(2)!;
    final rawValue = match.group(3)!;

    final filterType = switch (op) {
      'eq' => PostgresChangeFilterType.eq,
      'neq' => PostgresChangeFilterType.neq,
      'lt' => PostgresChangeFilterType.lt,
      'lte' => PostgresChangeFilterType.lte,
      'gt' => PostgresChangeFilterType.gt,
      'gte' => PostgresChangeFilterType.gte,
      'in' => PostgresChangeFilterType.inFilter,
      _ => PostgresChangeFilterType.eq,
    };

    Object value = rawValue;
    if (filterType == PostgresChangeFilterType.inFilter) {
      value = rawValue
          .split(',')
          .map((s) => s.trim().replaceAll(RegExp(r'^\(|\)$'), ''))
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return PostgresChangeFilter(
      type: filterType,
      column: column,
      value: value,
    );
  }
}
