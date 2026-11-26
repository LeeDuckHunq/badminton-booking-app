package vn.smashzone.app;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
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
 * Kênh "vn.smashzone.app/notify": thông báo hệ thống khi app ở nền (xem {@link NotifyCenter}).
 */
public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "vn.smashzone.app/updater";
    private static final String APK_MIME = "application/vnd.android.package-archive";
    private static final String NOTIFY_CHANNEL = "vn.smashzone.app/notify";
    private MethodChannel notifyChannel;
    /** Thông báo người dùng bấm để mở app (chờ Dart hỏi lúc khởi động). */
    private Map<String, Object> pendingTarget;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        pendingTarget = targetOf(getIntent());
        notifyChannel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), NOTIFY_CHANNEL);
        notifyChannel.setMethodCallHandler((call, result) -> {
            try {
                switch (call.method) {
                    case "configure":
                        NotifyCenter.configure(this, call.argument("baseUrl"), call.argument("token"));
                        result.success(true);
                        break;
                    case "clear":
                        NotifyCenter.clear(this);
                        result.success(true);
                        break;
                    case "background":
                        NotifyCenter.startBurst(this);
                        result.success(true);
                        break;
                    case "foreground":
                        NotifyCenter.stopBurst(this);
                        result.success(true);
                        break;
                    case "permitted":
                        result.success(NotifyCenter.permitted(this));
                        break;
                    case "requestPermission":
                        if (Build.VERSION.SDK_INT >= 33 && !NotifyCenter.permitted(this)) {
                            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.POST_NOTIFICATIONS}, 4711);
                        }
                        result.success(NotifyCenter.permitted(this));
                        break;
                    case "openSettings":
                        openNotificationSettings();
                        result.success(true);
                        break;
                    case "initialTarget":
                        result.success(pendingTarget);
                        pendingTarget = null;
                        break;
                    default:
                        result.notImplemented();
                }
            } catch (Exception e) {
                result.error("NOTIFY", e.getMessage(), null);
            }
        });

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

    @Override
    protected void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        Map<String, Object> target = targetOf(intent);
        if (target != null && notifyChannel != null) notifyChannel.invokeMethod("open", target);
    }

    private static Map<String, Object> targetOf(Intent intent) {
        if (intent == null || intent.getStringExtra(NotifyCenter.EXTRA_TYPE) == null) return null;
        Map<String, Object> m = new HashMap<>();
        m.put("doiTuong", intent.getStringExtra(NotifyCenter.EXTRA_TYPE));
        m.put("maDoiTuong", intent.getStringExtra(NotifyCenter.EXTRA_ID));
        m.put("maThongBao", intent.getStringExtra(NotifyCenter.EXTRA_NOTIFICATION));
        intent.removeExtra(NotifyCenter.EXTRA_TYPE);
        return m;
    }

    private void openNotificationSettings() {
        Intent intent = new Intent();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, getPackageName());
        } else {
            intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).setData(Uri.parse("package:" + getPackageName()));
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
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
