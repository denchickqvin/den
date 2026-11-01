# Ads Board — OLX-style classifieds web app

A mobile-first classifieds app (sell / rent) built with plain HTML, CSS and JavaScript in a single `index.html`, backed by [Supabase](https://supabase.com) (Postgres + Storage + Auth). Hosted on GitHub Pages.

**Live demo:** https://denchickqvin.github.io/den/
<!-- If you rename the repository, update the link above -->

<!-- Add a screenshot: upload an image to the repo and uncomment the line below -->
<!-- ![Screenshot](screenshot.png) -->

## Features

- Bottom navigation with three tabs: **Home** (feed), **Post** (create an ad), **Search** (live search by title and description)
- Ad form: photo upload, title, description, deal type (sale / rent), price, address, phone number
- Newest ads appear first; ads are shared between all devices and visitors
- Photos are read with `FileReader`, resized and compressed in the browser (canvas → JPEG) before upload
- Anonymous authentication — no registration needed; each browser gets a unique user ID
- The **Delete** button is shown only to the ad's author, and this is **enforced on the server** with Postgres Row Level Security, not just hidden in the UI
- Spam protection: file type and size limits, field length constraints, and a per-user limit of 20 ads (database trigger)
- All user content is rendered with `textContent` (no HTML injection / XSS)

## Tech stack

| Layer | Technology |
|---|---|
| Frontend | HTML, CSS, vanilla JavaScript (no build step) |
| Database | Supabase Postgres with Row Level Security |
| File storage | Supabase Storage (public bucket, per-user folders) |
| Auth | Supabase anonymous sign-ins |
| Hosting | GitHub Pages |

## How security works

The Supabase *publishable* key is public by design and is included in `index.html`. Real protection comes from the database rules in [`setup.sql`](setup.sql):

- anyone can **read** ads;
- only a signed-in (anonymous) user can **create** ads, and only with their own `author_id`;
- a user can **delete** only rows (and photo files) they own.

The secret / `service_role` key is never used and must never be committed.

## Run your own copy

1. Create a free project at [supabase.com](https://supabase.com).
2. Open **SQL Editor**, paste the contents of [`setup.sql`](setup.sql) and run it.
3. Go to **Authentication → Sign In / Providers** and enable **Allow anonymous sign-ins**.
4. Copy the **Project URL** and **Publishable key** into the two constants at the top of the script in `index.html`.
5. Publish with GitHub Pages (**Settings → Pages → Deploy from a branch → main / root**).

## Limitations

- On Supabase's free plan a project is paused after a week of inactivity; open the Supabase dashboard and restore it if the feed stops loading.
- Anonymous users can't recover their account after clearing browser data, so they lose the ability to delete their old ads. Email/OAuth sign-in could be added by linking identities.
- Phone numbers are public by design.

## What I learned

Working with a hosted Postgres from the browser, designing Row Level Security policies, anonymous auth, file uploads with per-user storage policies, and client-side image compression.
