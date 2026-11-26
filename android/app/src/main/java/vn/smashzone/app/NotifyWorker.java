package vn.smashzone.app;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

/** Chạy nền: hỏi máy chủ thông báo mới và hiện thành notification. */
public class NotifyWorker extends Worker {

    public NotifyWorker(@NonNull Context context, @NonNull WorkerParameters params) {
        super(context, params);
    }

    @NonNull
    @Override
    public Result doWork() {
        boolean ok = NotifyCenter.poll(getApplicationContext());
        if (getTags().contains("burst")) {
            NotifyCenter.continueBurst(getApplicationContext());
            return Result.success();
        }
        return ok ? Result.success() : Result.retry();
    }
}
