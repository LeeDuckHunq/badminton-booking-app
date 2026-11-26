package vn.smashzone.app;

import android.Manifest;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;
import androidx.work.Constraints;
import androidx.work.ExistingPeriodicWorkPolicy;
import androidx.work.ExistingWorkPolicy;
import androidx.work.NetworkType;
import androidx.work.OneTimeWorkRequest;
import androidx.work.PeriodicWorkRequest;
import androidx.work.WorkManager;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.TimeUnit;

/**
 * Thông báo hệ thống khi app không mở (không cần Firebase):
 * <ul>
 *   <li>App lưu địa chỉ máy chủ + token vào bộ nhớ riêng ({@link #configure}).</li>
 *   <li>WorkManager hỏi {@code GET /thong-bao/chua-gui} mỗi 15 phút; ngay sau khi thoát app
 *       thì hỏi dày hơn (khoảng mỗi phút, trong ~30 phút) để báo kịp lúc.</li>
 *   <li>Mỗi thông báo hiện thành notification; bấm vào mở đúng màn hình trong app.</li>
 * </ul>
 */
public final class NotifyCenter {

    static final String PREFS = "sz_notify";
    static final String EXTRA_TYPE = "sz_target_type";
    static final String EXTRA_ID = "sz_target_id";
    static final String EXTRA_NOTIFICATION = "sz_notification_id";
    private static final String PERIODIC = "sz_notify_periodic";
    private static final String BURST = "sz_notify_burst";
    private static final int BURST_RUNS = 30;

    static final String CH_BOOKING = "sz_booking";
    static final String CH_CHAT = "sz_chat";
    static final String CH_COMMUNITY = "sz_community";

    private NotifyCenter() { }

    // ── Cấu hình từ Dart ────────────────────────────────────────────────────

    static void configure(Context ctx, String baseUrl, String token) {
        prefs(ctx).edit().putString("baseUrl", baseUrl).putString("token", token).apply();
        createChannels(ctx);
        Constraints net = new Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build();
        PeriodicWorkRequest periodic = new PeriodicWorkRequest.Builder(NotifyWorker.class, 15, TimeUnit.MINUTES)
                .setConstraints(net).build();
        WorkManager.getInstance(ctx).enqueueUniquePeriodicWork(PERIODIC, ExistingPeriodicWorkPolicy.UPDATE, periodic);
    }

    static void clear(Context ctx) {
        prefs(ctx).edit().clear().apply();
        WorkManager wm = WorkManager.getInstance(ctx);
        wm.cancelUniqueWork(PERIODIC);
        wm.cancelUniqueWork(BURST);
        NotificationManagerCompat.from(ctx).cancelAll();
    }

    /** App vừa vào nền: hỏi dày hơn một thời gian. */
    static void startBurst(Context ctx) {
        if (prefs(ctx).getString("token", null) == null) return;
        prefs(ctx).edit().putInt("burstLeft", BURST_RUNS).apply();
        enqueueBurst(ctx, ExistingWorkPolicy.REPLACE);
    }

    /** App quay lại: Dart tự hỏi, dừng hỏi dày. */
    static void stopBurst(Context ctx) {
        prefs(ctx).edit().putInt("burstLeft", 0).apply();
        WorkManager.getInstance(ctx).cancelUniqueWork(BURST);
    }

    static void continueBurst(Context ctx) {
        SharedPreferences p = prefs(ctx);
        int left = p.getInt("burstLeft", 0);
        if (left <= 0) return;
        p.edit().putInt("burstLeft", left - 1).apply();
        enqueueBurst(ctx, ExistingWorkPolicy.APPEND_OR_REPLACE);
    }

    private static void enqueueBurst(Context ctx, ExistingWorkPolicy policy) {
        OneTimeWorkRequest req = new OneTimeWorkRequest.Builder(NotifyWorker.class)
                .setInitialDelay(60, TimeUnit.SECONDS)
                .setConstraints(new Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .addTag("burst")
                .build();
        WorkManager.getInstance(ctx).enqueueUniqueWork(BURST, policy, req);
    }

    static boolean permitted(Context ctx) {
        if (Build.VERSION.SDK_INT >= 33
                && ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            return false;
        }
        return NotificationManagerCompat.from(ctx).areNotificationsEnabled();
    }

    // ── Lấy và hiện thông báo ───────────────────────────────────────────────

    /** Gọi máy chủ, hiện các thông báo chưa gửi. Trả về false nếu cần thử lại (lỗi mạng). */
    static boolean poll(Context ctx) {
        SharedPreferences p = prefs(ctx);
        String base = p.getString("baseUrl", null);
        String token = p.getString("token", null);
        if (base == null || token == null) return true;
        HttpURLConnection con = null;
        try {
            con = (HttpURLConnection) new URL(base + "/thong-bao/chua-gui").openConnection();
            con.setConnectTimeout(15000);
            con.setReadTimeout(20000);
            con.setRequestProperty("Accept", "application/json");
            con.setRequestProperty("Authorization", "Bearer " + token);
            int code = con.getResponseCode();
            if (code == 401 || code == 403) {
                clear(ctx); // token hết hạn → thôi hỏi cho tới khi đăng nhập lại
                return true;
            }
            if (code != 200) return false;
            JSONArray items = new JSONArray(read(con.getInputStream()));
            for (int i = 0; i < items.length(); i++) show(ctx, items.getJSONObject(i));
            return true;
        } catch (Exception e) {
            return false;
        } finally {
            if (con != null) con.disconnect();
        }
    }

    static void show(Context ctx, JSONObject n) {
        if (!permitted(ctx)) return;
        createChannels(ctx);
        String loai = n.optString("loai");
        String title = n.optString("tieuDe", "SmashZone");
        String body = n.optString("noiDung", "");
        String type = n.optString("doiTuong", "");
        String target = n.optString("maDoiTuong", "");
        // Tin nhắn cùng người gửi dùng chung một id để thay thế thông báo cũ.
        int id = "TIN_NHAN".equals(loai) ? ("chat:" + n.optString("nguoiGui")).hashCode() : n.optString("maThongBao").hashCode();

        Intent open = new Intent(ctx, MainActivity.class)
                .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP | Intent.FLAG_ACTIVITY_CLEAR_TOP)
                .putExtra(EXTRA_TYPE, type)
                .putExtra(EXTRA_ID, target)
                .putExtra(EXTRA_NOTIFICATION, n.optString("maThongBao"));
        PendingIntent tap = PendingIntent.getActivity(ctx, id, open, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);

        NotificationCompat.Builder b = new NotificationCompat.Builder(ctx, channelOf(loai))
                .setSmallIcon(R.drawable.ic_stat_notify)
                .setColor(0xFF1A7A3C)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(new NotificationCompat.BigTextStyle().bigText(body))
                .setCategory("TIN_NHAN".equals(loai) ? NotificationCompat.CATEGORY_MESSAGE : NotificationCompat.CATEGORY_EVENT)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(tap);
        try {
            NotificationManagerCompat.from(ctx).notify(id, b.build());
        } catch (SecurityException ignored) {
            // Người dùng tắt quyền thông báo giữa chừng.
        }
    }

    private static String channelOf(String loai) {
        if ("TIN_NHAN".equals(loai)) return CH_CHAT;
        if (loai != null && loai.startsWith("TRAN_")) return CH_COMMUNITY;
        return CH_BOOKING;
    }

    static void createChannels(Context ctx) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;
        NotificationManager nm = ctx.getSystemService(NotificationManager.class);
        if (nm == null) return;
        NotificationChannel booking = new NotificationChannel(CH_BOOKING, "Đặt sân", NotificationManager.IMPORTANCE_HIGH);
        booking.setDescription("Xác nhận, huỷ, đổi sân và đơn mới");
        NotificationChannel chat = new NotificationChannel(CH_CHAT, "Tin nhắn", NotificationManager.IMPORTANCE_HIGH);
        chat.setDescription("Tin nhắn từ chủ sân và người chơi");
        NotificationChannel community = new NotificationChannel(CH_COMMUNITY, "Ghép trận & hội nhóm", NotificationManager.IMPORTANCE_DEFAULT);
        community.setDescription("Yêu cầu vào trận, duyệt, huỷ trận, góp tiền");
        nm.createNotificationChannel(booking);
        nm.createNotificationChannel(chat);
        nm.createNotificationChannel(community);
    }

    private static SharedPreferences prefs(Context ctx) {
        return ctx.getApplicationContext().getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    private static String read(InputStream in) throws Exception {
        try (InputStream s = in; ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] buf = new byte[8192];
            int n;
            while ((n = s.read(buf)) > 0) out.write(buf, 0, n);
            return out.toString(StandardCharsets.UTF_8.name());
        }
    }
}
