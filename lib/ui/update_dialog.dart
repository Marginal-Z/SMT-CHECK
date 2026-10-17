import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/update_service.dart';
import '../services/update_installer.dart';
import 'design.dart';
import 'localized_text.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateService Function()? serviceFactory;
  final Future<String> Function()? versionLoader;
  final UpdateInstaller? installer;
  final Future<void> Function()? onQuit;
  final bool Function()? canInstall;
  final String? platform, architecture;
  const UpdateDialog({
    super.key,
    this.serviceFactory,
    this.versionLoader,
    this.installer,
    this.onQuit,
    this.canInstall,
    this.platform,
    this.architecture,
  });
  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  UpdateService? service;
  AppRelease? release;
  DownloadedUpdate? download;
  late final nativeInstaller =
      widget.installer ?? UpdateInstaller(platform: platform);
  String currentVersion = '', error = '';
  bool checking = true,
      downloading = false,
      verifying = false,
      installing = false,
      installed = false;
  int received = 0, total = 0;
  String get platform => widget.platform ?? Platform.operatingSystem;
  @override
  void initState() {
    super.initState();
    unawaited(check());
  }

  Future<void> check() async {
    setState(() {
      checking = true;
      error = '';
      release = null;
    });
    final request = widget.serviceFactory?.call() ?? UpdateService();
    service = request;
    try {
      final version =
          await (widget.versionLoader?.call() ??
                  PackageInfo.fromPlatform().then((info) => info.version))
              .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() => currentVersion = version);
      final result = await request.check(
        currentVersion: version,
        platform: platform,
        architecture: widget.architecture ?? currentArchitecture,
      );
      if (mounted) setState(() => release = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is UpdateException ? e.message : '检查更新失败，请稍后重试。',
        );
      }
    } finally {
      request.close();
      if (identical(service, request)) service = null;
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> fetch() async {
    if (downloading || release == null) return;
    setState(() {
      downloading = true;
      verifying = false;
      error = '';
      received = 0;
      total = release!.installerSize;
    });
    final request = widget.serviceFactory?.call() ?? UpdateService();
    service = request;
    try {
      final result = await request.download(
        release!,
        onProgress: (done, size) {
          if (mounted) {
            setState(() {
              received = done;
              total = size;
            });
          }
        },
        onVerify: () {
          if (mounted) setState(() => verifying = true);
        },
      );
      if (mounted) {
        setState(() => download = result);
      } else {
        await result.delete();
      }
    } on UpdateCancelled {
      if (mounted) setState(() => error = '下载已取消，可重新下载。');
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is UpdateException ? e.message : '安装包下载失败，请检查网络后重试。',
        );
      }
    } finally {
      request.close();
      if (identical(service, request)) service = null;
      if (mounted) {
        setState(() {
          downloading = false;
          verifying = false;
        });
      }
    }
  }

  Future<void> install() async {
    if (download == null || installing) return;
    if (widget.canInstall?.call() == false) {
      setState(() => error = '请等待当前核对、分析或导出任务完成后再安装更新。');
      return;
    }
    setState(() {
      installing = true;
      error = '';
    });
    try {
      final handoff = await nativeInstaller.install(download!);
      if (!mounted) return;
      if (handoff) {
        // Setup owns the verified file until it exits. Never delete it on dispose.
        download = null;
        await widget.onQuit?.call();
      } else {
        setState(() => installed = true);
      }
    } catch (e) {
      if (e is UpdateVerificationException) {
        final invalid = download;
        download = null;
        if (invalid != null) {
          unawaited(invalid.delete().catchError((Object _) {}));
        }
      }
      if (mounted) {
        setState(
          () => error = e is UpdateException
              ? e.message
              : '安装未完成或已取消，请重试并允许系统安装授权。',
        );
      }
    } finally {
      if (mounted) setState(() => installing = false);
    }
  }

  Future<void> restart() async {
    setState(() {
      installing = true;
      error = '';
    });
    try {
      await nativeInstaller.restart();
      await widget.onQuit?.call();
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is UpdateException
              ? e.message
              : '无法重新启动应用，请从系统菜单打开 SMT Fusion。',
        );
      }
    } finally {
      if (mounted) setState(() => installing = false);
    }
  }

  @override
  void dispose() {
    service?.cancel();
    final artifact = installing ? null : download;
    if (artifact != null) {
      unawaited(artifact.delete().catchError((Object _) {}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context), result = release;
    final active = checking || downloading || installing;
    final status = checking
        ? '正在检查更新…'
        : installing
        ? '正在安装更新，请完成系统授权…'
        : verifying
        ? '正在校验安装包…'
        : '正在下载安装包…';
    return PopScope(
      canPop: !installing,
      child: Dialog(
        backgroundColor: p.panel,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: p.line),
        ),
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/app_icon.png',
                      width: 36,
                      height: 36,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'SMT Fusion',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: localText(context, '关闭'),
                      onPressed: installing
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LText(
                          '检查更新',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (currentVersion.isNotEmpty)
                          caption(context, '当前版本：$currentVersion'),
                        caption(
                          context,
                          '${platform == 'macos'
                              ? 'macOS'
                              : platform == 'windows'
                              ? 'Windows'
                              : 'Linux'} · ${widget.architecture ?? currentArchitecture}',
                        ),
                        if (result != null) ...[
                          const SizedBox(height: 16),
                          LText(
                            result.hasUpdate
                                ? '发现新版本 ${result.latest}'
                                : '当前已是最新版本',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const LText(
                            '更新说明',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 150),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                result.notes.isEmpty
                                    ? localText(context, '此版本未提供更新说明。')
                                    : result.notes,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ),
                          if (result.hasUpdate) ...[
                            const SizedBox(height: 12),
                            caption(
                              context,
                              result.canInstall
                                  ? '在软件内下载并校验安装包，无需打开发布页面。'
                                  : '此安装包缺少有效校验信息或不支持应用内安装，请稍后重试。',
                            ),
                          ],
                        ],
                        if (active) ...[
                          const SizedBox(height: 18),
                          LText(
                            status,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (downloading && !verifying) ...[
                            LinearProgressIndicator(
                              key: const Key('update-download-progress'),
                              value: total > 0 ? received / total : 0,
                              minHeight: 4,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(received / 1048576).toStringAsFixed(1)} / ${(total / 1048576).toStringAsFixed(1)} MB · ${total > 0 ? (received * 100 / total).floor() : 0}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ] else if (MediaQuery.disableAnimationsOf(context))
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(Icons.hourglass_top, size: 18),
                            )
                          else
                            const LinearProgressIndicator(minHeight: 3),
                        ],
                        if (download != null && !active) ...[
                          const SizedBox(height: 16),
                          LText(
                            installed ? '更新已安装，重新启动后生效。' : '安装包已通过 SHA-256 校验。',
                            style: TextStyle(
                              color: p.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!installed) ...[
                            const SizedBox(height: 8),
                            caption(
                              context,
                              platform == 'windows'
                                  ? '安装将关闭并重新启动应用，请先导出需要保留的结果。'
                                  : '安装需要系统授权；请先导出结果，再安装并重新启动。',
                            ),
                          ],
                        ],
                        if (error.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          LText(
                            error,
                            key: const Key('update-error'),
                            style: TextStyle(
                              color: p.alertText,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (result != null &&
                        result.hasUpdate &&
                        result.canInstall &&
                        download == null &&
                        !downloading)
                      DeskButton(
                        '下载更新',
                        primary: true,
                        icon: Icons.download_outlined,
                        onPressed: active ? null : () => unawaited(fetch()),
                      ),
                    if (downloading)
                      DeskButton(
                        '取消下载',
                        icon: Icons.close,
                        onPressed: () => service?.cancel(),
                      ),
                    if (download != null && !installed)
                      DeskButton(
                        '安装更新',
                        primary: true,
                        icon: Icons.system_update_alt,
                        onPressed: active ? null : () => unawaited(install()),
                      ),
                    if (installed)
                      DeskButton(
                        '重新启动应用',
                        primary: true,
                        icon: Icons.restart_alt,
                        onPressed: active ? null : () => unawaited(restart()),
                      ),
                    if (error.isNotEmpty && release == null)
                      DeskButton(
                        '重试',
                        onPressed: active ? null : () => unawaited(check()),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
