import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/update_service.dart';
import 'design.dart';
import 'localized_text.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateService Function()? serviceFactory;
  final Future<String> Function()? versionLoader;
  final Future<bool> Function(Uri)? linkOpener;
  final String? platform;
  final String? architecture;
  const UpdateDialog({
    super.key,
    this.serviceFactory,
    this.versionLoader,
    this.linkOpener,
    this.platform,
    this.architecture,
  });
  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  UpdateService? service;
  AppRelease? release;
  String currentVersion = '', error = '', launchError = '';
  Uri? failedLink;
  bool checking = true, opening = false;
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
      launchError = '';
      failedLink = null;
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
          () =>
              error = e is UpdateException ? e.message : '检查更新失败，请稍后重试或查看发布页面。',
        );
      }
    } finally {
      request.close();
      if (identical(service, request)) service = null;
      if (mounted) setState(() => checking = false);
    }
  }

  Future<void> open(Uri link) async {
    if (opening) return;
    setState(() {
      opening = true;
      launchError = '';
      failedLink = null;
    });
    try {
      final ok =
          await (widget.linkOpener?.call(link) ??
                  launchUrl(link, mode: LaunchMode.externalApplication))
              .timeout(const Duration(seconds: 10));
      if (!ok) throw StateError('browser not available');
    } catch (_) {
      if (mounted) {
        setState(() {
          launchError = '无法打开系统浏览器，请复制链接后打开。';
          failedLink = link;
        });
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  void dispose() {
    service?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context), result = release;
    return Dialog(
      backgroundColor: p.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: p.line),
      ),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.system_update_alt, size: 20, color: p.accent),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: LText(
                      '检查更新',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: localText(context, '关闭'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (currentVersion.isNotEmpty)
                caption(context, '当前版本：$currentVersion'),
              caption(
                context,
                '${platform == 'macos'
                    ? 'macOS'
                    : platform == 'windows'
                    ? 'Windows'
                    : platform == 'linux'
                    ? 'Linux'
                    : platform} · ${widget.architecture ?? currentArchitecture}',
              ),
              const SizedBox(height: 10),
              if (checking) ...[
                const LText(
                  '正在检查更新…',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                if (MediaQuery.disableAnimationsOf(context))
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.hourglass_top, size: 18),
                  )
                else
                  const LinearProgressIndicator(minHeight: 3),
              ],
              if (error.isNotEmpty)
                LText(
                  error,
                  style: TextStyle(
                    color: p.alertText,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              if (result != null) ...[
                LText(
                  result.hasUpdate ? '发现新版本 ${result.latest}' : '当前已是最新版本',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                caption(context, '最新正式版本：${result.latest}'),
                const SizedBox(height: 18),
                const LText(
                  '更新说明',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      result.notes.isEmpty
                          ? localText(context, '此版本未提供更新说明。')
                          : result.notes,
                      style: const TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ),
                ),
                if (result.hasUpdate) ...[
                  const SizedBox(height: 12),
                  caption(
                    context,
                    result.installer == null
                        ? '暂未提供当前平台安装包，请查看发布页面。'
                        : '在系统浏览器中下载完整安装包。',
                  ),
                ],
              ],
              if (launchError.isNotEmpty) ...[
                const SizedBox(height: 12),
                LText(
                  launchError,
                  style: TextStyle(color: p.alertText, fontSize: 12),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  failedLink.toString(),
                  style: const TextStyle(fontSize: 11),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (result != null &&
                      result.hasUpdate &&
                      result.installer != null)
                    DeskButton(
                      switch (platform) {
                        'windows' => '下载 Windows 安装包',
                        'macos' => '下载 macOS 安装包',
                        _ => '下载 Linux 安装包',
                      },
                      primary: true,
                      icon: Icons.download_outlined,
                      onPressed: opening
                          ? null
                          : () => unawaited(open(result.installer!)),
                    ),
                  if (!checking)
                    DeskButton(
                      '查看发布页面',
                      icon: Icons.open_in_new,
                      onPressed: opening
                          ? null
                          : () => unawaited(open(result?.page ?? releasesPage)),
                    ),
                  if (error.isNotEmpty)
                    DeskButton(
                      '重试',
                      onPressed: checking ? null : () => unawaited(check()),
                    ),
                  if (failedLink != null)
                    DeskButton(
                      '复制链接',
                      icon: Icons.copy_outlined,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: failedLink.toString()),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
