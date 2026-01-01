# IN Institution Admin Panel

A powerful, theme-aware admin panel built with **Vite + React + TypeScript + Supabase**.

## Features

- 🎨 **4 Theme Options**: Black, Dim, Off-White, White
- 🔐 **Role-Based Access**: Support, Moderator, Super Admin
- 📊 **Dashboard**: Real-time stats and activity
- 👥 **User Management**: Full user lifecycle control
- 💳 **Plans Management**: Subscription tiers and limits
- 📁 **Storage Browser**: File management across buckets
- ⚙️ **Algorithm Settings**: Feed ranking, trending, spam controls
- 📜 **Audit Log**: Complete action history

---

## User Management Features

The Users page includes a comprehensive 8-tab user detail panel:

| Tab | Features |
|-----|----------|
| **Overview** | Bio, join date, verification status, boost/ban indicators |
| **Content** | Browse user's posts with engagement stats |
| **Activity** | Timeline of user actions + admin actions on user |
| **Notes** | Internal admin notes (not visible to user) |
| **Verify** | Set badge: None, Verified, Institution, Creator |
| **Ban** | Ban/unban with reason and duration (7d/30d/90d/permanent) |
| **Boost** | Profile visibility multiplier (1x-5x) with expiration |
| **Export** | Download posts, comments, DMs, media as JSON |

---

## Quick Start

### 1. Install Dependencies
```bash
cd admin-panel
npm install
```

### 2. Configure Environment
```bash
cp .env.example .env.local
```

Edit `.env.local`:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 3. Run Migrations
```bash
cd ..  # back to my_app
supabase db push
```

This creates:
- `profiles` enhancements (verified_type, is_locked, boost_multiplier)
- `admin_users` table
- `admin_audit_logs` table
- `admin_user_notes` table
- `plans` and subscription tables

### 3b. Deploy Edge Functions (Required)

This admin panel relies on Supabase Edge Functions for privileged actions (plans CRUD, admin management, audit logs, storage deletes, algorithm settings).

From `my_app/`:
```bash
supabase functions deploy admin-users
supabase functions deploy admin-plans
supabase functions deploy admin-admins
supabase functions deploy admin-posts
supabase functions deploy admin-audit
supabase functions deploy admin-settings
supabase functions deploy admin-storage
```

### Moderation Settings

Moderation controls live in `admin_settings` and are edited from the **Algorithm** page:
- `moderation.trending` - weights/time decay for the Dashboard + Posts trending list
- `moderation.posts` - takedown workflow defaults (reasons, restore toggle)

### 4. Create Your First Admin
```sql
INSERT INTO admin_users (user_id, role, is_active)
VALUES (
  (SELECT id FROM auth.users WHERE email = 'your@email.com'),
  'super_admin',
  true
);
```

### 5. Run Development Server
```bash
cd admin-panel
npm run dev
```

Opens at [http://localhost:5173](http://localhost:5173)

---

## Build for Production

```bash
npm run build
```

Output is in `/dist` - deploy to any static host:
- GitHub Pages
- Vercel
- Netlify
- Cloudflare Pages

For GitHub Pages subpath:
```ts
// vite.config.ts
base: '/your-repo-name/'
```

---

## Role Permissions

| Role | Dashboard | Users | Plans | Storage | Algorithm | Settings |
|------|-----------|-------|-------|---------|-----------|----------|
| Support | ✅ | ✅ Read | ❌ | ❌ | ❌ | ❌ |
| Moderator | ✅ | ✅ Edit | ❌ | ❌ | ❌ | ❌ |
| Super Admin | ✅ | ✅ Full | ✅ | ✅ | ✅ | ✅ |

---

## Themes

Switch themes from the sidebar. Persists in localStorage.

| Theme | Description |
|-------|-------------|
| **Black** | Pure dark mode, OLED-friendly |
| **Dim** | Softer dark with blue tint |
| **Off-White** | Warm light theme |
| **White** | Pure light mode |

---

## Database Tables

### Core Admin Tables
- `admin_users` - Who can access admin panel
- `admin_audit_logs` - Action history with before/after state
- `admin_user_notes` - Internal notes on users
- `admin_settings` - Algorithm and system settings

### Profile Enhancements
- `verified_type` - none, verified, institution, creator
- `is_locked` - Ban status
- `boost_multiplier` - Feed visibility boost

### Plans & Subscriptions
- `plans` - Subscription tiers
- `user_subscriptions` - User → plan mapping
- `user_overrides` - Per-user limit overrides

---

## Project Structure

```
admin-panel/
├── public/
│   └── logo.png
├── src/
│   ├── components/
│   │   ├── DataTable.tsx
│   │   ├── Layout.tsx
│   │   ├── Sidebar.tsx
│   │   ├── StatCard.tsx
│   │   ├── ThemeSwitcher.tsx
│   │   └── UserDetailPanel.tsx
│   ├── hooks/
│   │   └── useTheme.tsx
│   ├── pages/
│   │   ├── Login.tsx
│   │   ├── Dashboard.tsx
│   │   ├── Users.tsx
│   │   ├── Plans.tsx
│   │   ├── Storage.tsx
│   │   ├── Algorithm.tsx
│   │   ├── AuditLog.tsx
│   │   └── Settings.tsx
│   ├── lib/
│   │   ├── supabase.ts
│   │   ├── edge-functions.ts
│   │   └── utils.ts
│   ├── types/
│   │   └── database.ts
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
├── .env.example
├── vite.config.ts
└── package.json
```

---

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| Vite | 5.x | Build tool |
| React | 18.x | UI framework |
| TypeScript | 5.x | Type safety |
| Tailwind CSS | 4.x | Styling |
| TanStack Table | 8.x | Data tables |
| Supabase | 2.x | Backend |
| React Router | 6.x | Routing |

---

## Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start dev server |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build |
| `npm run lint` | Run ESLint |

---

## Manual QA Checklist

Recommended quick checks after schema changes or UI work:

1. **Login**: Sign in as a `super_admin` and verify routes load (Dashboard → Users → Plans → Storage → Algorithm → Settings).
2. **Plans**:
   - Click **New Plan** → create a plan → confirm it appears in the table.
   - Click **Edit** on an existing plan → change name/limits/features → save → confirm the table updates.
   - Click **Delete** → confirm delete removes it from the table (and that RLS/policies allow it).
3. **Users**: Open a user → verify tab navigation + actions (notes/verify/ban/boost/export) complete without console errors.
4. **Storage**: Browse a bucket → preview/download → delete a file (if enabled).
5. **Audit Log**: Open a record → verify the detail modal renders before/after JSON.

---

## License

Private - IN Institution © 2024
