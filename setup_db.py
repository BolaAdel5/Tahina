"""
تشغيل هذا الملف على جهازك:
1. تأكد إن Python مثبت
2. شغّل: pip install supabase
3. شغّل: python setup_db.py
"""

from supabase import create_client

SUPABASE_URL = "https://txeozkjziyqjoozrjzia.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR4ZW96a2p6aXlxam9venJqemlhIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MjUwOTI3NywiZXhwIjoyMDk4MDg1Mjc3fQ.R9vJwNDzNjDUm9XmGGvrjTEcPMvmh5WROuSAaF4SGTY"

supa = create_client(SUPABASE_URL, SERVICE_KEY)

print("🔄 جارٍ إعداد قاعدة البيانات...")

# مسح البيانات القديمة
try:
    supa.table("payments").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
    supa.table("invoices").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
    supa.table("inventory").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
    supa.table("customers").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
    supa.table("products").delete().neq("id", "00000000-0000-0000-0000-000000000000").execute()
    print("✅ تم مسح البيانات القديمة")
except Exception as e:
    print(f"⚠️ مسح: {e}")

# إضافة المنتجات
products = supa.table("products").insert([
    {"name": "طحينة", "unit": "كيلو", "price": 18.00, "stock": 450},
    {"name": "زيت حار", "unit": "كيلو", "price": 22.00, "stock": 280},
]).execute()
print(f"✅ المنتجات: {len(products.data)} منتج")

p_tahini = products.data[0]["id"]
p_oil = products.data[1]["id"]

# إضافة العملاء
customers = supa.table("customers").insert([
    {"name": "أحمد محمد السيد",    "shop": "مطعم الشام",              "phone": "0501234567", "address": "الرياض - حي النزهة",      "balance": 450.00},
    {"name": "محمد علي حسن",       "shop": "بقالة النور",             "phone": "0559876543", "address": "جدة - حي الروضة",         "balance": 0.00},
    {"name": "خالد إبراهيم عمر",   "shop": "مطعم الخليج",             "phone": "0531112222", "address": "الدمام - حي الفيصلية",    "balance": 1200.00, "notes": "عميل مميز"},
    {"name": "سامي حسن أحمد",      "shop": "سوبرماركت الأمل",         "phone": "0543334444", "address": "مكة - حي العزيزية",       "balance": 320.00},
    {"name": "يوسف عبدالله",        "shop": "مطعم الربيع",             "phone": "0512223333", "address": "الرياض - حي الملز",       "balance": 0.00,   "notes": "عميل جديد"},
    {"name": "فيصل الراشد",         "shop": "محل الفيصل",              "phone": "0567778888", "address": "الرياض - حي العليا",      "balance": 750.00},
    {"name": "عبدالرحمن القحطاني", "shop": "مطعم البيت العربي",       "phone": "0534445555", "address": "جدة - حي الزهراء",        "balance": 0.00},
    {"name": "ناصر الدوسري",        "shop": "كافيه الياسمين",          "phone": "0523336666", "address": "الدمام - حي الشاطئ",      "balance": 180.00},
    {"name": "طارق الشمري",         "shop": "مطعم طارق",               "phone": "0556667777", "address": "الرياض - حي السليمانية", "balance": 0.00},
    {"name": "حمد البلوي",          "shop": "بقالة الأمين",            "phone": "0509998888", "address": "المدينة المنورة",         "balance": 600.00, "notes": "عميل قديم"},
]).execute()
print(f"✅ العملاء: {len(customers.data)} عميل")

c = {c["name"]: c["id"] for c in customers.data}

# إضافة المخزون
from datetime import date, timedelta
today = date.today().isoformat()
def days_ago(n): return (date.today() - timedelta(days=n)).isoformat()

supa.table("inventory").insert([
    {"product_id": p_tahini, "qty": 600, "price": 12.00, "date": days_ago(14), "notes": "وارد من المصنع - دفعة شهرية"},
    {"product_id": p_oil,    "qty": 350, "price": 15.00, "date": days_ago(14), "notes": "وارد من المصنع - دفعة شهرية"},
    {"product_id": p_tahini, "qty": 200, "price": 12.00, "date": days_ago(5),  "notes": "وارد إضافي"},
    {"product_id": p_oil,    "qty": 100, "price": 15.00, "date": days_ago(3),  "notes": "وارد إضافي"},
]).execute()
print("✅ المخزون: 4 سجلات")

# إضافة الفواتير
invoices_data = [
    {
        "customer_id": c["أحمد محمد السيد"], "num": "INV-2025-1001",
        "total": 900.00, "paid": 450.00, "remaining": 450.00,
        "date": days_ago(2),
        "items": [
            {"product_id": p_tahini, "name": "طحينة",   "unit": "كيلو", "qty": 30,    "price": 18, "sub": 540},
            {"product_id": p_oil,    "name": "زيت حار", "unit": "كيلو", "qty": 16.36, "price": 22, "sub": 360},
        ]
    },
    {
        "customer_id": c["محمد علي حسن"], "num": "INV-2025-1002",
        "total": 540.00, "paid": 540.00, "remaining": 0.00,
        "date": days_ago(3),
        "items": [{"product_id": p_tahini, "name": "طحينة", "unit": "كيلو", "qty": 30, "price": 18, "sub": 540}]
    },
    {
        "customer_id": c["خالد إبراهيم عمر"], "num": "INV-2025-1003",
        "total": 1760.00, "paid": 560.00, "remaining": 1200.00,
        "date": days_ago(5),
        "items": [
            {"product_id": p_tahini, "name": "طحينة",   "unit": "كيلو", "qty": 50, "price": 18, "sub": 900},
            {"product_id": p_oil,    "name": "زيت حار", "unit": "كيلو", "qty": 39, "price": 22, "sub": 858},
        ]
    },
    {
        "customer_id": c["سامي حسن أحمد"], "num": "INV-2025-1004",
        "total": 608.00, "paid": 288.00, "remaining": 320.00,
        "date": days_ago(7),
        "items": [
            {"product_id": p_tahini, "name": "طحينة",   "unit": "كيلو", "qty": 16,    "price": 18, "sub": 288},
            {"product_id": p_oil,    "name": "زيت حار", "unit": "كيلو", "qty": 14.54, "price": 22, "sub": 320},
        ]
    },
    {
        "customer_id": c["فيصل الراشد"], "num": "INV-2025-1005",
        "total": 1250.00, "paid": 500.00, "remaining": 750.00,
        "date": days_ago(10),
        "items": [
            {"product_id": p_tahini, "name": "طحينة",   "unit": "كيلو", "qty": 40,    "price": 18, "sub": 720},
            {"product_id": p_oil,    "name": "زيت حار", "unit": "كيلو", "qty": 24.09, "price": 22, "sub": 530},
        ]
    },
    {
        "customer_id": c["ناصر الدوسري"], "num": "INV-2025-1006",
        "total": 396.00, "paid": 216.00, "remaining": 180.00,
        "date": days_ago(4),
        "items": [
            {"product_id": p_tahini, "name": "طحينة",   "unit": "كيلو", "qty": 12, "price": 18, "sub": 216},
            {"product_id": p_oil,    "name": "زيت حار", "unit": "كيلو", "qty": 8,  "price": 22, "sub": 176},
        ]
    },
    {
        "customer_id": c["أحمد محمد السيد"], "num": "INV-2025-1007",
        "total": 360.00, "paid": 360.00, "remaining": 0.00,
        "date": today,
        "items": [{"product_id": p_tahini, "name": "طحينة", "unit": "كيلو", "qty": 20, "price": 18, "sub": 360}]
    },
    {
        "customer_id": c["حمد البلوي"], "num": "INV-2025-1008",
        "total": 1040.00, "paid": 440.00, "remaining": 600.00,
        "date": today,
        "items": [
            {"product_id": p_tahini, "name": "طحينة",   "unit": "كيلو", "qty": 20, "price": 18, "sub": 360},
            {"product_id": p_oil,    "name": "زيت حار", "unit": "كيلو", "qty": 31, "price": 22, "sub": 682},
        ]
    },
]

invs = supa.table("invoices").insert(invoices_data).execute()
print(f"✅ الفواتير: {len(invs.data)} فاتورة")

# إضافة الدفعات
supa.table("payments").insert([
    {"customer_id": c["أحمد محمد السيد"],    "amount": 450.00, "date": days_ago(2),  "notes": "دفع نقدي"},
    {"customer_id": c["محمد علي حسن"],       "amount": 540.00, "date": days_ago(3),  "notes": "تحويل بنكي"},
    {"customer_id": c["خالد إبراهيم عمر"],   "amount": 560.00, "date": days_ago(5),  "notes": "دفع نقدي جزئي"},
    {"customer_id": c["سامي حسن أحمد"],      "amount": 288.00, "date": days_ago(7),  "notes": "دفع نقدي"},
    {"customer_id": c["فيصل الراشد"],         "amount": 500.00, "date": days_ago(10), "notes": "شيك بنكي"},
    {"customer_id": c["ناصر الدوسري"],        "amount": 216.00, "date": days_ago(4),  "notes": "دفع نقدي"},
    {"customer_id": c["أحمد محمد السيد"],    "amount": 360.00, "date": today,         "notes": "دفع كامل"},
    {"customer_id": c["حمد البلوي"],          "amount": 440.00, "date": today,         "notes": "دفع نقدي"},
]).execute()
print("✅ الدفعات: 8 دفعات")

print("\n🎉 تم إعداد قاعدة البيانات بنجاح!")
print(f"   - منتجات: طحينة (18₪) + زيت حار (22₪)")
print(f"   - عملاء: 10 عملاء")
print(f"   - فواتير: 8 فواتير")
print(f"   - دفعات: 8 دفعات")
print(f"   - مخزون: 4 سجلات")
