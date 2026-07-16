import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/display_name.dart';
import '../../l10n/l10n.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primitives.dart';
import '../../widgets/readable_column.dart';
import '../auth/auth_repository.dart';
import 'party_repository.dart';

/// `/party/join` — resolve a short code to a party and enter it. Joining is by
/// code (the `join_party` RPC); the invite QR encodes the same code.
class PartyJoinScreen extends ConsumerStatefulWidget {
  const PartyJoinScreen({super.key});

  @override
  ConsumerState<PartyJoinScreen> createState() => _PartyJoinScreenState();
}

class _PartyJoinScreenState extends ConsumerState<PartyJoinScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Joining needs neither premium nor a real account — just *some* session for the
      // authenticated join_party RPC. Mint a transparent guest session if signed out, carrying the
      // chosen display name so the roster shows it (not "Builder").
      await ref
          .read(authRepositoryProvider)
          .ensureGuestSession(displayName: ref.read(displayNameProvider));
      final party = await ref.read(partyRepositoryProvider).joinParty(code);
      if (mounted) context.pushReplacement('/party/${party.id}');
    } catch (e) {
      if (mounted) setState(() => _error = _messageFor(context, e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Only a genuine "no such code" may blame the code — the `join_party` RPC raises SQLSTATE
  /// P0001 for that. Guest sign-in, connectivity and decode failures reach here too; telling
  /// someone to check a code that was right sends them in circles, so each gets the message that
  /// names the thing they can actually act on (oracle PartyJoinView.swift:80-86).
  String _messageFor(BuildContext context, Object e) {
    if (e is PostgrestException && e.code == 'P0001') return context.l10n.partyJoinError;
    if (_isOffline(e)) return context.l10n.partyJoinOffline;
    return context.l10n.partyJoinFailed;
  }

  bool _isOffline(Object e) {
    if (e is SocketException) return true;
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection closed') ||
        s.contains('clientexception');
  }

  @override
  Widget build(BuildContext context) {
    final c = BrickColors.of(context);
    return ColoredBox(
      color: c.canvas,
      child: SafeArea(
        child: ReadableColumn(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScreenHeader(context.l10n.partyJoinTitle, onBack: () => Navigator.of(context).maybePop()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.l10n.partyJoinSubtitle,
                        style: AppText.body.copyWith(color: c.inkSoft)),
                    const SizedBox(height: AppSpacing.s20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: c.line),
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.go,
                        onSubmitted: (_) => _join(),
                        style: AppText.h1.copyWith(letterSpacing: 4),
                        cursorColor: c.primary,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'A1B2C3D4',
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(_error!, style: AppText.caption.copyWith(color: c.danger)),
                    ],
                    const SizedBox(height: AppSpacing.s20),
                    AppButton(
                      context.l10n.partyJoinCta,
                      icon: Icons.login,
                      expand: true,
                      loading: _loading,
                      onPressed: _loading ? null : _join,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
