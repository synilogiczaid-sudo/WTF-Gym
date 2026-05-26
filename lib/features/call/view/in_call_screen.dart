import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:shared/shared.dart';

import '../viewmodel/call_viewmodel.dart';
import 'post_call_sheet.dart';

class InCallScreen extends ConsumerWidget {
  const InCallScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rtc = ref.watch(callSessionViewModelProvider);
    final reqAsync = ref.watch(callRequestProvider(requestId));

    // Auto-leave if the member ended the call on their side — polling
    // flips the request to `completed`, we react and yank the trainer
    // back home instead of leaving them in an empty room.
    ref.listen<AsyncValue<CallRequest?>>(callRequestProvider(requestId), (_, next) {
      final r = next.valueOrNull;
      if (r != null && r.status == CallRequestStatus.completed) {
        ref.read(rtcServiceProvider).leave();
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(content: Text('Member left the call.')),
          );
          context.go('/home');
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _TileGrid(
                local: rtc.localPeer,
                remote: rtc.remotePeer,
                demoLocalName: rtc.demoLocalName,
                demoRemoteName: rtc.demoRemoteName,
                isDemo: rtc.demoMode,
              ),
            ),
            if (rtc.demoMode)
              const Positioned(top: 12, left: 0, right: 0, child: _DemoBadge()),
            if (rtc.reconnecting)
              const Positioned(top: 16, left: 0, right: 0, child: _ReconnectBanner()),
            Align(
              alignment: Alignment.bottomCenter,
              child: _Controls(
                state: rtc,
                onMic: () => ref.read(callSessionViewModelProvider.notifier).toggleMic(),
                onCamera: () =>
                    ref.read(callSessionViewModelProvider.notifier).toggleCamera(),
                onFlip: () => ref.read(callSessionViewModelProvider.notifier).flipCamera(),
                onEnd: () async {
                  final req = reqAsync.valueOrNull;
                  if (req == null) {
                    if (context.mounted) context.go('/home');
                    return;
                  }
                  final log = await ref
                      .read(callSessionViewModelProvider.notifier)
                      .endForAll(request: req);
                  if (!context.mounted) return;
                  if (log != null) {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: false,
                      backgroundColor: Colors.white,
                      builder: (_) => TrainerPostCallSheet(sessionId: log.id),
                    );
                  }
                  if (context.mounted) context.go('/home/sessions');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({
    required this.local,
    required this.remote,
    required this.demoLocalName,
    required this.demoRemoteName,
    required this.isDemo,
  });
  final HMSPeer? local;
  final HMSPeer? remote;
  final String? demoLocalName;
  final String? demoRemoteName;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final remoteLabel = isDemo
        ? (demoRemoteName ?? 'Waiting for member…')
        : (remote?.name ?? 'Waiting for member…');
    final localLabel = isDemo
        ? '${demoLocalName ?? 'You'} (You)'
        : '${local?.name ?? 'You'} (You)';
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 100),
      child: Column(
        children: [
          Expanded(child: _Tile(peer: remote, label: remoteLabel)),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: _Tile(peer: local, label: localLabel, isLocal: true)),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.peer, required this.label, this.isLocal = false});
  final HMSPeer? peer;
  final String label;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    final track = peer?.videoTrack;
    final hasVideo = track != null && !track.isMute;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.xl),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F2A3D),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasVideo)
              HMSVideoView(track: track, scaleType: ScaleType.SCALE_ASPECT_FILL)
            else
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.16),
                        Colors.white.withValues(alpha: 0.04),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (peer?.name ?? '?').characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.42),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLocal) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.state,
    required this.onMic,
    required this.onCamera,
    required this.onFlip,
    required this.onEnd,
  });

  final RtcState state;
  final VoidCallback onMic;
  final VoidCallback onCamera;
  final VoidCallback onFlip;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CtrlButton(
              icon: state.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              active: !state.micOn,
              onTap: onMic,
              label: state.micOn ? 'Mute' : 'Unmute',
            ),
            _CtrlButton(
              icon: state.cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              active: !state.cameraOn,
              onTap: onCamera,
              label: state.cameraOn ? 'Camera' : 'Camera off',
            ),
            _CtrlButton(
              icon: Icons.cameraswitch_rounded,
              onTap: onFlip,
              label: 'Flip',
            ),
            _CtrlButton(
              icon: Icons.call_end_rounded,
              destructive: true,
              onTap: onEnd,
              label: 'End',
            ),
          ],
        ),
      ),
    );
  }
}

class _CtrlButton extends StatelessWidget {
  const _CtrlButton({
    required this.icon,
    required this.onTap,
    required this.label,
    this.active = false,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final bool active;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final bg = destructive
        ? AppColors.error
        : active
            ? Colors.white
            : Colors.white.withValues(alpha: 0.12);
    final fg = destructive
        ? Colors.white
        : active
            ? AppColors.ink
            : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkResponse(
            onTap: onTap,
            radius: 34,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: destructive ? 60 : 54,
              height: 54,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                boxShadow: destructive
                    ? [
                        BoxShadow(
                          color: AppColors.error.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: fg, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, color: Colors.white, size: 12),
            SizedBox(width: 6),
            Text(
              'Demo session · 100ms creds not configured',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReconnectBanner extends StatelessWidget {
  const _ReconnectBanner();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text('Reconnecting…',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
