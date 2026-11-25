package vn.smashzone.app;

import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import java.io.File;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/**
 * Kênh "vn.smashzone.app/updater" cho chức năng tự cập nhật:
 * thông tin phiên bản / kiến trúc CPU, quyền cài ứng dụng và mở trình cài APK đã tải.
 */
public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "vn.smashzone.app/updater";
    private static final String APK_MIME = "application/vnd.android.package-archive";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL).setMethodCallHandler((call, result) -> {
            try {
                switch (call.method) {
                    case "info":
                        result.success(info());
                        break;
                    case "canInstall":
                        result.success(Build.VERSION.SDK_INT < Build.VERSION_CODES.O || getPackageManager().canRequestPackageInstalls());
                        break;
                    case "openInstallSettings":
                        openInstallSettings();
                        result.success(true);
                        break;
                    case "install":
                        install(call.argument("path"));
                        result.success(true);
                        break;
                    default:
                        result.notImplemented();
                }
            } catch (Exception e) {
                result.error("UPDATER", e.getMessage(), null);
            }
        });
    }

    private Map<String, Object> info() throws PackageManager.NameNotFoundException {
        PackageInfo p = getPackageManager().getPackageInfo(getPackageName(), 0);
        long code = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P ? p.getLongVersionCode() : p.versionCode;
        Map<String, Object> m = new HashMap<>();
        m.put("versionName", p.versionName);
        m.put("versionCode", code);
        m.put("abis", Arrays.asList(Build.SUPPORTED_ABIS));
        m.put("sdk", Build.VERSION.SDK_INT);
        m.put("updateDir", updateDir().getAbsolutePath());
        return m;
    }

    /** Thư mục chứa APK tải về (khớp với res/xml/update_paths.xml). */
    private File updateDir() {
        File dir = new File(getCacheDir(), "updates");
        if (!dir.exists()) dir.mkdirs();
        return dir;
    }

    private void openInstallSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent intent = new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:" + getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
        }
    }

    private void install(String path) {
        if (path == null) throw new IllegalArgumentException("Thiếu đường dẫn file cài đặt");
        File apk = new File(path);
        if (!apk.exists()) throw new IllegalArgumentException("Không tìm thấy file cài đặt");
        Uri uri = FileProvider.getUriForFile(this, getPackageName() + ".updater", apk);
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setDataAndType(uri, APK_MIME);
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }
}
