import 'dart:io';

import 'package:cambric_app/core/updates/install_layout.dart';
import 'package:cambric_app/core/updates/update_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('version comparison', () {
    test('orders dotted versions numerically', () {
      expect(UpdateService.compareVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(UpdateService.compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(UpdateService.compareVersions('1.0.0', '1.0.0'), 0);
      expect(UpdateService.compareVersions('2.0.0', '1.9.9'), greaterThan(0));
      expect(UpdateService.compareVersions('1.10.0', '1.9.0'), greaterThan(0));
    });

    test('a pre-release is older than the stable build', () {
      expect(
        UpdateService.compareVersions('1.0.1-beta1', '1.0.1'),
        lessThan(0),
      );
      expect(
        UpdateService.compareVersions('1.0.1', '1.0.1-beta1'),
        greaterThan(0),
      );
    });

    test('missing parts count as zero', () {
      expect(UpdateService.compareVersions('1.1', '1.1.0'), 0);
      expect(UpdateService.compareVersions('1', '1.0.1'), lessThan(0));
    });
  });

  group('digest parsing', () {
    test('accepts a sha256 digest and a bare hash', () {
      final hash = 'a' * 64;
      expect(UpdateService.parseDigest('sha256:$hash'), hash);
      expect(UpdateService.parseDigest(hash.toUpperCase()), hash);
    });

    test('rejects malformed digests', () {
      expect(UpdateService.parseDigest(null), isNull);
      expect(UpdateService.parseDigest('sha256:1234'), isNull);
      expect(UpdateService.parseDigest('md5:${'a' * 32}'), isNull);
      expect(UpdateService.parseDigest('not a digest'), isNull);
    });

    test('reads the hash from a sha256 sidecar', () {
      final hash = 'b' * 64;
      expect(ReleaseAsset.parseChecksum('$hash  windows.zip\n'), hash);
      expect(ReleaseAsset.parseChecksum('garbage'), isNull);
    });
  });

  group('release assets', () {
    test('parses only entries with a name and URL', () {
      final assets = ReleaseAsset.parseAll(<dynamic>[
        <String, dynamic>{
          'name': 'windows.zip',
          'browser_download_url': 'https://example.test/windows.zip',
          'size': 42,
        },
        <String, dynamic>{'name': 'missing-url.zip'},
        <String, dynamic>{'browser_download_url': 'https://example.test/x'},
        'not a map',
      ]);
      expect(assets, hasLength(1));
      expect(assets.single.name, 'windows.zip');
      expect(assets.single.sizeBytes, 42);
    });

    test('selects the package for the host platform', () {
      final assets = ReleaseAsset.parseAll(<dynamic>[
        <String, dynamic>{
          'name': 'windows.zip',
          'browser_download_url': 'https://example.test/windows.zip',
        },
        <String, dynamic>{
          'name': 'linux.tar.gz',
          'browser_download_url': 'https://example.test/linux.tar.gz',
        },
        <String, dynamic>{
          'name': 'android.apk',
          'browser_download_url': 'https://example.test/android.apk',
        },
      ]);
      final selected = ReleaseAsset.forCurrentPlatform(assets);
      expect(selected, isNotNull);
      if (Platform.isWindows) {
        expect(selected!.name, 'windows.zip');
      } else if (Platform.isLinux) {
        expect(selected!.name, 'linux.tar.gz');
      } else if (Platform.isAndroid) {
        expect(selected!.name, 'android.apk');
      }
    });

    test('no matching package returns null', () {
      expect(ReleaseAsset.forCurrentPlatform(const <ReleaseAsset>[]), isNull);
    });
  });

  group('install layout', () {
    test('recognises a versioned install and reads its version', () {
      final sep = Platform.pathSeparator;
      final exe = 'C:${sep}apps${sep}CAround${sep}versions${sep}1.0.1'
          '${sep}c_around.exe';
      final layout = InstallLayout.detect(executablePath: exe);
      expect(layout.isVersioned, isTrue);
      expect(layout.runningVersion, '1.0.1');
      expect(layout.versionDirectory('1.0.2').path, endsWith('1.0.2'));
    });

    test('a flat build is not versioned', () {
      final sep = Platform.pathSeparator;
      final exe = 'C:${sep}apps${sep}CAround${sep}c_around.exe';
      final layout = InstallLayout.detect(executablePath: exe);
      expect(layout.isVersioned, isFalse);
    });

    test('activation writes the pointer and rollback restores it', () async {
      final temp = await Directory.systemTemp.createTemp('c_around_layout');
      addTearDown(() => temp.delete(recursive: true));
      final versions = Directory('${temp.path}${Platform.pathSeparator}versions');
      final first = Directory('${versions.path}${Platform.pathSeparator}1.0.0');
      final second = Directory('${versions.path}${Platform.pathSeparator}1.0.1');
      await first.create(recursive: true);
      await second.create(recursive: true);
      final exeName = InstallLayout.executableName;
      await File('${first.path}${Platform.pathSeparator}$exeName').writeAsString('');
      await File('${second.path}${Platform.pathSeparator}$exeName').writeAsString('');

      final layout = InstallLayout.detect(
        executablePath: '${first.path}${Platform.pathSeparator}$exeName',
      );
      final installer = UpdateInstaller(layout);

      final activated = await installer.activateVersion('1.0.1');
      expect(activated.ok, isTrue);
      expect(activated.previousVersion, isNull);
      expect(layout.activeVersion, '1.0.1');

      final rolledBack = await installer.rollbackTo('1.0.0');
      expect(rolledBack.ok, isTrue);
      expect(layout.activeVersion, '1.0.0');
    });

    test('activation refuses a version with no executable', () async {
      final temp = await Directory.systemTemp.createTemp('c_around_layout');
      addTearDown(() => temp.delete(recursive: true));
      final versions = Directory('${temp.path}${Platform.pathSeparator}versions');
      final first = Directory('${versions.path}${Platform.pathSeparator}1.0.0');
      await first.create(recursive: true);
      final exeName = InstallLayout.executableName;
      await File('${first.path}${Platform.pathSeparator}$exeName').writeAsString('');

      final layout = InstallLayout.detect(
        executablePath: '${first.path}${Platform.pathSeparator}$exeName',
      );
      final installer = UpdateInstaller(layout);
      final outcome = await installer.activateVersion('9.9.9');
      expect(outcome.ok, isFalse);
      expect(layout.activeVersion, isNull);
    });
  });
}
