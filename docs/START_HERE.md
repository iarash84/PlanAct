# از اینجا شروع کن

این پوشه برای کپی مستقیم داخل repository پروژه آماده شده است.

## فایل‌های اصلی

- `AGENTS.md` — قانون مادر پروژه برای هر AI Coding Agent و Developer.
- `docs/ARCHITECTURE_AND_DOMAIN_RULES.md` — قواعد دامنه و معماری محصول.
- `docs/IMPLEMENTATION_PLAN.md` — ترتیب Milestoneها و Taskها.
- `docs/PROMPT_WORKFLOW.md` — روش درست استفاده از Promptها.
- `prompts/README.md` — فهرست تمام Promptها.
- `prompts/P00_...` تا `P38_...` — Promptهای آماده اجرا.

## روش پیشنهادی

1. این فایل‌ها را در root repository قرار بده.
2. در ابزار vibe coding، `AGENTS.md` را به‌عنوان project instruction/rule در دسترس دائمی Agent قرار بده.
3. قبل از اولین Feature، Prompt `P00` را اجرا کن.
4. بعد از هر Prompt:
   - diff را بررسی کن؛
   - تست‌ها را اجرا/بررسی کن؛
   - commit جدا بزن؛
   - سپس Prompt بعدی را بده.
5. اگر Agent در میانه راه خواست Feature مرحله بعد را هم اضافه کند، جلوی آن را بگیر. کوچک ماندن change-set عمداً بخشی از معماری توسعه است.

## Context پیشنهادی برای هر Prompt

به Agent بگو همیشه این‌ها را بخواند:

```text
AGENTS.md
docs/ARCHITECTURE_AND_DOMAIN_RULES.md
prompts/Pxx_....md
```

و سپس repository فعلی را inspect کند.

## نکته مهم

این بسته عمداً بعضی انتخاب‌های implementation مثل State Management، UUIDv7 در برابر ULID، DB encryption library و notification package را قطعی نکرده است؛ چون نقشه راه اصلی هم آن‌ها را تصمیمات زمان پیاده‌سازی می‌داند. Agent حق ندارد این تصمیمات را بی‌صدا بگیرد؛ باید از existing project choice استفاده کند یا ADR ایجاد کند.
