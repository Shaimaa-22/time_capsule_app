CREATE TABLE users (
    id SERIAL PRIMARY KEY,                -- رقم تسلسلي لكل مستخدم
    name VARCHAR(100) NOT NULL,           -- اسم المستخدم
    email VARCHAR(150) UNIQUE NOT NULL,   -- البريد الإلكتروني (فريد)
    password_hash TEXT NOT NULL,          -- كلمة المرور مشفرة
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- تاريخ الإنشاء
);
CREATE TABLE capsules (
    id SERIAL PRIMARY KEY,                -- رقم تسلسلي لكل كبسولة
    owner_id INTEGER NOT NULL,             -- صاحب الكبسولة (مفتاح أجنبي)
    recipient_email VARCHAR(150),          -- إيميل الشخص المستقبل (اختياري)
    content_type VARCHAR(20) NOT NULL,     -- نوع المحتوى (text / image / video)
    content_encrypted TEXT NOT NULL,       -- المحتوى مشفر
    open_date TIMESTAMP NOT NULL,          -- تاريخ الفتح
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- تاريخ الإنشاء
    is_opened BOOLEAN DEFAULT false,       -- حالة الفتح
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE sessions (
    id SERIAL PRIMARY KEY,                  -- رقم الجلسة
    user_id INTEGER NOT NULL,                -- المستخدم صاحب الجلسة
    session_token TEXT NOT NULL UNIQUE,      -- رمز الجلسة (JWT أو UUID)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- وقت إنشاء الجلسة
    expires_at TIMESTAMP NOT NULL,           -- وقت انتهاء الجلسة
    device_info TEXT,                         -- معلومات الجهاز (اختياري)
    ip_address VARCHAR(45),                   -- IP المستخدم (اختياري)
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
ALTER TABLE capsules
ADD COLUMN title VARCHAR(255),
ADD COLUMN opened_at TIMESTAMP,
ADD COLUMN notification_sent BOOLEAN DEFAULT false;