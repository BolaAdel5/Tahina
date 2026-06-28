-- =============================================
-- إنشاء الجداول
-- =============================================

-- جدول المنتجات
CREATE TABLE IF NOT EXISTS products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  unit TEXT DEFAULT 'كيلو',
  price NUMERIC DEFAULT 0,
  stock NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول العملاء
CREATE TABLE IF NOT EXISTS customers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  shop TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  address TEXT DEFAULT '',
  balance NUMERIC DEFAULT 0,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول الفواتير
CREATE TABLE IF NOT EXISTS invoices (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  num TEXT,
  total NUMERIC DEFAULT 0,
  paid NUMERIC DEFAULT 0,
  remaining NUMERIC DEFAULT 0,
  notes TEXT DEFAULT '',
  items JSONB DEFAULT '[]',
  date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول الدفعات
CREATE TABLE IF NOT EXISTS payments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  amount NUMERIC DEFAULT 0,
  date DATE DEFAULT CURRENT_DATE,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- جدول المخزون
CREATE TABLE IF NOT EXISTS inventory (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES products(id) ON DELETE SET NULL,
  qty NUMERIC DEFAULT 0,
  price NUMERIC DEFAULT 0,
  date DATE DEFAULT CURRENT_DATE,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- تعطيل RLS مؤقتاً (للاستخدام البسيط)
-- =============================================
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE customers DISABLE ROW LEVEL SECURITY;
ALTER TABLE invoices DISABLE ROW LEVEL SECURITY;
ALTER TABLE payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE inventory DISABLE ROW LEVEL SECURITY;

-- =============================================
-- بيانات المنتجات مع الأسعار
-- =============================================
INSERT INTO products (name, unit, price, stock) VALUES
  ('طحينة', 'كيلو', 18.00, 450),
  ('زيت حار', 'كيلو', 22.00, 280);

-- =============================================
-- بيانات العملاء
-- =============================================
INSERT INTO customers (name, shop, phone, address, balance, notes) VALUES
  ('أحمد محمد السيد',   'مطعم الشام',           '0501234567', 'الرياض - حي النزهة',     450.00,  'عميل منتظم - توصيل أسبوعي'),
  ('محمد علي حسن',     'بقالة النور',           '0559876543', 'جدة - حي الروضة',        0.00,    ''),
  ('خالد إبراهيم عمر', 'مطعم الخليج',           '0531112222', 'الدمام - حي الفيصلية',   1200.00, 'عميل مميز - يطلب كميات كبيرة'),
  ('سامي حسن أحمد',   'سوبرماركت الأمل',       '0543334444', 'مكة - حي العزيزية',      320.00,  ''),
  ('يوسف عبدالله',     'مطعم الربيع',           '0512223333', 'الرياض - حي الملز',      0.00,    'عميل جديد'),
  ('فيصل الراشد',      'محل الفيصل للمواد الغذائية', '0567778888', 'الرياض - حي العليا', 750.00,  'يفضل الدفع نقداً'),
  ('عبدالرحمن القحطاني','مطعم البيت العربي',    '0534445555', 'جدة - حي الزهراء',       0.00,    ''),
  ('ناصر الدوسري',     'كافيه الياسمين',        '0523336666', 'الدمام - حي الشاطئ',    180.00,  ''),
  ('طارق الشمري',      'مطعم طارق',             '0556667777', 'الرياض - حي السليمانية', 0.00,    ''),
  ('حمد البلوي',       'بقالة الأمين',          '0509998888', 'المدينة المنورة',         600.00,  'عميل قديم - موثوق');

-- =============================================
-- بيانات المخزون (وارد من المصنع)
-- =============================================
INSERT INTO inventory (product_id, qty, price, date, notes)
SELECT id, 600, 12.00, CURRENT_DATE - INTERVAL '14 days', 'وارد من المصنع - دفعة شهرية'
FROM products WHERE name = 'طحينة';

INSERT INTO inventory (product_id, qty, price, date, notes)
SELECT id, 350, 15.00, CURRENT_DATE - INTERVAL '14 days', 'وارد من المصنع - دفعة شهرية'
FROM products WHERE name = 'زيت حار';

INSERT INTO inventory (product_id, qty, price, date, notes)
SELECT id, 200, 12.00, CURRENT_DATE - INTERVAL '5 days', 'وارد إضافي'
FROM products WHERE name = 'طحينة';

INSERT INTO inventory (product_id, qty, price, date, notes)
SELECT id, 100, 15.00, CURRENT_DATE - INTERVAL '3 days', 'وارد إضافي'
FROM products WHERE name = 'زيت حار';

-- =============================================
-- فواتير تجريبية
-- =============================================
-- فاتورة 1 - أحمد محمد (معلقة)
WITH c AS (SELECT id FROM customers WHERE name = 'أحمد محمد السيد' LIMIT 1),
     p1 AS (SELECT id FROM products WHERE name = 'طحينة' LIMIT 1),
     p2 AS (SELECT id FROM products WHERE name = 'زيت حار' LIMIT 1)
INSERT INTO invoices (customer_id, num, total, paid, remaining, date, items)
SELECT c.id, 'INV-2025-1001', 900.00, 450.00, 450.00,
       CURRENT_DATE - INTERVAL '2 days',
       jsonb_build_array(
         jsonb_build_object('product_id', p1.id, 'name', 'طحينة', 'unit', 'كيلو', 'qty', 30, 'price', 18, 'sub', 540),
         jsonb_build_object('product_id', p2.id, 'name', 'زيت حار', 'unit', 'كيلو', 'qty', 16.36, 'price', 22, 'sub', 360)
       )
FROM c, p1, p2;

-- فاتورة 2 - محمد علي (مسددة)
WITH c AS (SELECT id FROM customers WHERE name = 'محمد علي حسن' LIMIT 1),
     p1 AS (SELECT id FROM products WHERE name = 'طحينة' LIMIT 1)
INSERT INTO invoices (customer_id, num, total, paid, remaining, date, items)
SELECT c.id, 'INV-2025-1002', 540.00, 540.00, 0.00,
       CURRENT_DATE - INTERVAL '3 days',
       jsonb_build_array(
         jsonb_build_object('product_id', p1.id, 'name', 'طحينة', 'unit', 'كيلو', 'qty', 30, 'price', 18, 'sub', 540)
       )
FROM c, p1;

-- فاتورة 3 - خالد إبراهيم (معلقة)
WITH c AS (SELECT id FROM customers WHERE name = 'خالد إبراهيم عمر' LIMIT 1),
     p1 AS (SELECT id FROM products WHERE name = 'طحينة' LIMIT 1),
     p2 AS (SELECT id FROM products WHERE name = 'زيت حار' LIMIT 1)
INSERT INTO invoices (customer_id, num, total, paid, remaining, date, items)
SELECT c.id, 'INV-2025-1003', 1760.00, 560.00, 1200.00,
       CURRENT_DATE - INTERVAL '5 days',
       jsonb_build_array(
         jsonb_build_object('product_id', p1.id, 'name', 'طحينة', 'unit', 'كيلو', 'qty', 50, 'price', 18, 'sub', 900),
         jsonb_build_object('product_id', p2.id, 'name', 'زيت حار', 'unit', 'كيلو', 'qty', 39, 'price', 22, 'sub', 858)
       )
FROM c, p1, p2;

-- فاتورة 4 - سامي حسن (معلقة)
WITH c AS (SELECT id FROM customers WHERE name = 'سامي حسن أحمد' LIMIT 1),
     p1 AS (SELECT id FROM products WHERE name = 'طحينة' LIMIT 1),
     p2 AS (SELECT id FROM products WHERE name = 'زيت حار' LIMIT 1)
INSERT INTO invoices (customer_id, num, total, paid, remaining, date, items)
SELECT c.id, 'INV-2025-1004', 608.00, 288.00, 320.00,
       CURRENT_DATE - INTERVAL '7 days',
       jsonb_build_array(
         jsonb_build_object('product_id', p1.id, 'name', 'طحينة', 'unit', 'كيلو', 'qty', 16, 'price', 18, 'sub', 288),
         jsonb_build_object('product_id', p2.id, 'name', 'زيت حار', 'unit', 'كيلو', 'qty', 14.54, 'price', 22, 'sub', 320)
       )
FROM c, p1, p2;

-- فاتورة 5 - فيصل الراشد (معلقة)
WITH c AS (SELECT id FROM customers WHERE name = 'فيصل الراشد' LIMIT 1),
     p1 AS (SELECT id FROM products WHERE name = 'طحينة' LIMIT 1),
     p2 AS (SELECT id FROM products WHERE name = 'زيت حار' LIMIT 1)
INSERT INTO invoices (customer_id, num, total, paid, remaining, date, items)
SELECT c.id, 'INV-2025-1005', 1250.00, 500.00, 750.00,
       CURRENT_DATE - INTERVAL '10 days',
       jsonb_build_array(
         jsonb_build_object('product_id', p1.id, 'name', 'طحينة', 'unit', 'كيلو', 'qty', 40, 'price', 18, 'sub', 720),
         jsonb_build_object('product_id', p2.id, 'name', 'زيت حار', 'unit', 'كيلو', 'qty', 24.09, 'price', 22, 'sub', 530)
       )
FROM c, p1, p2;

-- فاتورة اليوم - أحمد محمد
WITH c AS (SELECT id FROM customers WHERE name = 'أحمد محمد السيد' LIMIT 1),
     p1 AS (SELECT id FROM products WHERE name = 'طحينة' LIMIT 1)
INSERT INTO invoices (customer_id, num, total, paid, remaining, date, items)
SELECT c.id, 'INV-2025-1006', 360.00, 360.00, 0.00,
       CURRENT_DATE,
       jsonb_build_array(
         jsonb_build_object('product_id', p1.id, 'name', 'طحينة', 'unit', 'كيلو', 'qty', 20, 'price', 18, 'sub', 360)
       )
FROM c, p1;

-- فاتورة اليوم - حمد البلوي
WITH c AS (SELECT id FROM customers WHERE name = 'حمد البلوي' LIMIT 1),
     p1 AS (SELECT id FROM products WHERE name = 'طحينة' LIMIT 1),
     p2 AS (SELECT id FROM products WHERE name = 'زيت حار' LIMIT 1)
INSERT INTO invoices (customer_id, num, total, paid, remaining, date, items)
SELECT c.id, 'INV-2025-1007', 1040.00, 440.00, 600.00,
       CURRENT_DATE,
       jsonb_build_array(
         jsonb_build_object('product_id', p1.id, 'name', 'طحينة', 'unit', 'كيلو', 'qty', 20, 'price', 18, 'sub', 360),
         jsonb_build_object('product_id', p2.id, 'name', 'زيت حار', 'unit', 'كيلو', 'qty', 31, 'price', 22, 'sub', 682)
       )
FROM c, p1, p2;

-- =============================================
-- دفعات تحصيل
-- =============================================
INSERT INTO payments (customer_id, amount, date, notes)
SELECT id, 450.00, CURRENT_DATE - INTERVAL '2 days', 'دفع نقدي'
FROM customers WHERE name = 'أحمد محمد السيد' LIMIT 1;

INSERT INTO payments (customer_id, amount, date, notes)
SELECT id, 540.00, CURRENT_DATE - INTERVAL '3 days', 'تحويل بنكي'
FROM customers WHERE name = 'محمد علي حسن' LIMIT 1;

INSERT INTO payments (customer_id, amount, date, notes)
SELECT id, 560.00, CURRENT_DATE - INTERVAL '5 days', 'دفع نقدي جزئي'
FROM customers WHERE name = 'خالد إبراهيم عمر' LIMIT 1;

INSERT INTO payments (customer_id, amount, date, notes)
SELECT id, 288.00, CURRENT_DATE - INTERVAL '7 days', 'دفع نقدي'
FROM customers WHERE name = 'سامي حسن أحمد' LIMIT 1;

INSERT INTO payments (customer_id, amount, date, notes)
SELECT id, 500.00, CURRENT_DATE - INTERVAL '10 days', 'شيك بنكي'
FROM customers WHERE name = 'فيصل الراشد' LIMIT 1;

INSERT INTO payments (customer_id, amount, date, notes)
SELECT id, 360.00, CURRENT_DATE, 'دفع نقدي كامل'
FROM customers WHERE name = 'أحمد محمد السيد' LIMIT 1;

INSERT INTO payments (customer_id, amount, date, notes)
SELECT id, 440.00, CURRENT_DATE, 'دفع نقدي'
FROM customers WHERE name = 'حمد البلوي' LIMIT 1;

-- =============================================
-- تحديث أرصدة العملاء بشكل صحيح
-- =============================================
UPDATE customers SET balance =
  COALESCE((SELECT SUM(remaining) FROM invoices WHERE customer_id = customers.id), 0)
  - COALESCE((SELECT SUM(amount) FROM payments WHERE customer_id = customers.id
              AND date > (SELECT COALESCE(MAX(created_at), '2000-01-01') FROM invoices WHERE customer_id = customers.id)), 0);

-- تصفير الأرصدة السالبة
UPDATE customers SET balance = 0 WHERE balance < 0;

-- حساب الأرصدة الصحيحة مباشرة
UPDATE customers c SET balance = (
  SELECT COALESCE(SUM(i.remaining), 0)
  FROM invoices i WHERE i.customer_id = c.id
);
