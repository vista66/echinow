# Backtest Pack (XAUUSD_EA)

## هدف
این بسته برای اجرای بک‌تست استاندارد، مقایسه ۳ پروفایل تنظیمات، و ثبت KPI ها تهیه شده است.

## سناریوی تست پایه
- Symbol: `XAUUSD`
- Model: Every tick (real ticks اگر در دسترس است)
- Timeframe chart: H1
- بازه پیشنهادی: 2020-01-01 تا 2025-12-31
- Deposit: 10000
- Leverage: مطابق بروکر تست

## KPI های اجباری
- Net Profit
- Profit Factor
- Expected Payoff
- Recovery Factor
- Max Drawdown (%)
- Total Trades
- Win Rate (%)

## پروفایل‌های آماده
از فایل‌های زیر استفاده کنید:
1. `Presets/XAUUSD_Conservative.set`
2. `Presets/XAUUSD_Balanced.set`
3. `Presets/XAUUSD_Aggressive.set`

## روند اجرا
1. فایل `XAUUSD_EA.mq5` را کامپایل کنید.
2. هر preset را جداگانه Load کنید.
3. خروجی Report/Graph را ذخیره کنید.
4. نتایج را در `Docs/Optimization_Summary.md` ثبت کنید.

## نکات اعتبارسنجی
- اگر `UseFundamentalData=true` است، CSV ها در Common/Files/Data موجود باشند.
- لاگ روزانه در `Data\\logs\\` بررسی شود.
- در Visual Mode دکمه‌های پنل (`Auto Trade ON/OFF` و `Close All`) تست شوند.
