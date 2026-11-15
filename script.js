/* =========================================================
   CONFIG
   ========================================================= */
const API_BASE = "https://vidsrc.mov";
const movieUrl = (id) => `${API_BASE}/embed/movie/${id}`;
const tvUrl = (id, season, ep) => `${API_BASE}/embed/tv/${id}/${season}/${ep}`;

/* Iframe sandbox for the player. OFF, because vidsrc.mov refuses to load in a
   sandboxed frame ("This content can't be embedded in a sandboxed frame").

   With a provider that allows it, this value stops the player from opening
   pop-ups or new tabs, redirecting this page, showing alert boxes or starting
   downloads, while still letting it run and play video:
     "allow-scripts allow-same-origin allow-forms allow-presentation"          */
const PLAYER_SANDBOX = "";

const TMDB_KEY ="67efa981973baa37ef02e529456ba057";
const TMDB = "https://api.themoviedb.org/3";
const IMG = "https://image.tmdb.org/t/p";

/* Where profiles are kept in this browser's localStorage */
const PROFILES_KEY = "fakeflix.profiles";          // [{ id, name, avatar }]
const ACTIVE_KEY = "fakeflix.activeProfile";       // id of the profile in use, or null for guest
const dataKey = (profileId) => `fakeflix.data.${profileId}`;   // that profile's saved titles
const MAX_PROFILES = 5;
const AVATAR_COLORS = ["#e0001e", "#1f6feb", "#2ea043", "#d29922", "#8957e5", "#db61a2", "#12a5a5", "#6e7681"];

/* Rows shown on each browse page. "type" is set when the endpoint
   returns only movies or only TV (those results carry no media_type). */
const ROWS = {
  home: [
    { title: "Trending Now", path: "/trending/all/week" },
    { title: "Top 10 Today", path: "/trending/all/day", top10: true },
    { title: "Popular Movies", path: "/movie/popular", type: "movie" },
    { title: "Popular TV Shows", path: "/discover/tv", type: "tv", params: { "vote_count.gte": "300" } },
    { title: "Top Rated Movies", path: "/movie/top_rated", type: "movie" },
    { title: "Action & Adventure", path: "/discover/movie", type: "movie", params: { with_genres: "28" } },
    { title: "Comedies", path: "/discover/movie", type: "movie", params: { with_genres: "35" } },
    { title: "Sci-Fi & Fantasy TV", path: "/discover/tv", type: "tv", params: { with_genres: "10765", "vote_count.gte": "100" } },
    { title: "Horror", path: "/discover/movie", type: "movie", params: { with_genres: "27" } },
    { title: "Critically Acclaimed TV", path: "/tv/top_rated", type: "tv" },
    { title: "Documentaries", path: "/discover/movie", type: "movie", params: { with_genres: "99" } },
  ],
  movies: [
    { title: "Trending Movies", path: "/trending/movie/week", type: "movie" },
    { title: "Top 10 Movies Today", path: "/trending/movie/day", type: "movie", top10: true },
    { title: "Popular", path: "/movie/popular", type: "movie" },
    { title: "In Theaters Now", path: "/movie/now_playing", type: "movie" },
    { title: "Top Rated", path: "/movie/top_rated", type: "movie" },
    { title: "Action", path: "/discover/movie", type: "movie", params: { with_genres: "28" } },
    { title: "Comedy", path: "/discover/movie", type: "movie", params: { with_genres: "35" } },
    { title: "Thrillers", path: "/discover/movie", type: "movie", params: { with_genres: "53" } },
    { title: "Sci-Fi", path: "/discover/movie", type: "movie", params: { with_genres: "878" } },
    { title: "Horror", path: "/discover/movie", type: "movie", params: { with_genres: "27" } },
    { title: "Romance", path: "/discover/movie", type: "movie", params: { with_genres: "10749" } },
    { title: "Animation", path: "/discover/movie", type: "movie", params: { with_genres: "16" } },
  ],
  tv: [
    { title: "Trending Shows", path: "/trending/tv/week", type: "tv" },
    { title: "Top 10 Shows Today", path: "/trending/tv/day", type: "tv", top10: true },
    { title: "Popular", path: "/discover/tv", type: "tv", params: { "vote_count.gte": "300" } },
    { title: "Top Rated", path: "/tv/top_rated", type: "tv" },
    { title: "Drama", path: "/discover/tv", type: "tv", params: { with_genres: "18", "vote_count.gte": "100" } },
    { title: "Comedy", path: "/discover/tv", type: "tv", params: { with_genres: "35", "vote_count.gte": "100" } },
    { title: "Crime", path: "/discover/tv", type: "tv", params: { with_genres: "80", "vote_count.gte": "100" } },
    { title: "Sci-Fi & Fantasy", path: "/discover/tv", type: "tv", params: { with_genres: "10765", "vote_count.gte": "100" } },
    { title: "Animation", path: "/discover/tv", type: "tv", params: { with_genres: "16", "vote_count.gte": "100" } },
    { title: "Mystery", path: "/discover/tv", type: "tv", params: { with_genres: "9648", "vote_count.gte": "100" } },
    { title: "Docuseries", path: "/discover/tv", type: "tv", params: { with_genres: "99", "vote_count.gte": "50" } },
  ],
  new: [
    { title: "Everyone's Watching", path: "/trending/all/day" },
    { title: "Top 10 Movies Today", path: "/trending/movie/day", type: "movie", top10: true },
    { title: "Top 10 Shows Today", path: "/trending/tv/day", type: "tv", top10: true },
    { title: "Coming Soon", path: "/movie/upcoming", type: "movie" },
    { title: "New in Theaters", path: "/movie/now_playing", type: "movie" },
    { title: "New Episodes This Week", path: "/tv/on_the_air", type: "tv" },
    { title: "Airing Today", path: "/tv/airing_today", type: "tv" },
  ],
};

/* The Categories picker. TMDB uses different genre ids for movies and TV,
   and some genres only exist for movies. */
const CATEGORIES = [
  { slug: "action", name: "Action", movie: "28", tv: "10759" },
  { slug: "animation", name: "Animation", movie: "16", tv: "16" },
  { slug: "comedy", name: "Comedies", movie: "35", tv: "35" },
  { slug: "crime", name: "Crime", movie: "80", tv: "80" },
  { slug: "documentary", name: "Documentaries", movie: "99", tv: "99" },
  { slug: "drama", name: "Dramas", movie: "18", tv: "18" },
  { slug: "family", name: "Kids & Family", movie: "10751", tv: "10751" },
  { slug: "fantasy", name: "Fantasy", movie: "14" },
  { slug: "horror", name: "Horror", movie: "27" },
  { slug: "mystery", name: "Mysteries", movie: "9648", tv: "9648" },
  { slug: "romance", name: "Romance", movie: "10749" },
  { slug: "scifi", name: "Sci-Fi", movie: "878", tv: "10765" },
  { slug: "thriller", name: "Thrillers", movie: "53" },
];

/* Page names shown in the phone header */
const VIEW_TITLES = {
  home: "Home",
  tv: "TV Shows",
  movies: "Movies",
  new: "New & Hot",
  search: "Search",
  me: "My FakeFlix",
  "my-list": "My List",
  liked: "Liked",
  history: "Watch History",
};

/* Which type of title each browse page is limited to (null = both) */
const VIEW_TYPE = { home: null, movies: "movie", tv: "tv" };

const isPhone = () => window.matchMedia("(max-width: 760px)").matches;

/* ---------- Elements ---------- */
const $ = (id) => document.getElementById(id);

const nav          = $("nav");
const navLinks     = document.querySelectorAll(".nav-links a");
const searchForm   = $("search-form");
const searchInput  = $("search-input");
const searchToggle = $("search-toggle");
const searchClear  = $("search-clear");
const heroEl       = $("hero");
const rowsEl       = $("rows");
const gridView     = $("grid-view");
const gridTitle    = $("grid-title");
const gridEl       = $("grid");
const gridEmpty    = $("grid-empty");
const gridAction   = $("grid-action");
const profileBtn   = $("profile-btn");
const profileMenu  = $("profile-menu");
const profilesEl   = $("profiles");
const profilesBody = $("profiles-body");
const toastEl      = $("toast");
const toastText    = $("toast-text");
const toastAction  = $("toast-action");
const mTitle       = $("m-title");
const chipsEl      = $("chips");
const tabbar       = $("tabbar");
const tabAvatar    = $("tab-avatar");
const categoriesEl = $("categories");
const categoriesList = $("categories-list");
const modalEl      = $("modal");
const modalBody    = $("modal-body");
const modalClose   = $("modal-close");
const watchEl      = $("watch");
const watchFrame   = $("watch-frame");
const watchBack    = $("watch-back");
const watchTitle   = $("watch-title");
const watchNext    = $("watch-next");

/* ---------- State ---------- */
let baseKey = null;          // which page is rendered underneath any overlay
let baseView = "home";       // "home" | "movies" | "tv" | "my-list" | "liked" | "history" | "search"
let baseHash = "#/";         // where closing the modal returns to
let preSearchHash = "#/";    // where clearing the search returns to
let lastHash = "#/";         // where leaving the profile screen returns to
let profileMode = "pick";    // "pick" | "manage" | "edit"
let editing = null;          // the profile being edited (null while adding a new one)
let draftAvatar = 0;         // colour picked in the add/edit form
let toastTimer;
let categoryType = null;     // "movie" | "tv" | null: what the Categories picker is limited to
let heroToken = 0;           // used to ignore slow extras for a billboard that was replaced
let lastScrollY = 0;
let personalToken = 0;       // used to ignore a slow "Because you liked" response
let renderToken = 0;         // used to ignore responses for a page we already left
let modalToken = 0;
let watchToken = 0;
let episodeKey = "";         // "<showId>:<season>" of the episode list being loaded
let playingUrl = "";
let debounceTimer;
let searchCount = 0;         // used to ignore old, slow search responses

/* ---------- Small helpers ---------- */

/* Movies use "title" + "release_date", TV shows use "name" + "first_air_date" */
const titleOf = (item) => item.title || item.name;
const dateOf  = (item) => item.release_date || item.first_air_date || "No date";
const yearOf  = (item) => (item.release_date || item.first_air_date || "").slice(0, 4);
const typeOf  = (item) => item.media_type || (item.title !== undefined ? "movie" : "tv");

const image = (path, size) => (path ? `${IMG}/${size}${path}` : "");

/* Everything from the API goes through this before it is put into HTML */
const ESCAPES = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
const esc = (value) => String(value ?? "").replace(/[&<>"']/g, (ch) => ESCAPES[ch]);

const runtimeText = (minutes) => {
  if (!minutes) return "";
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return h ? `${h}h ${m}m` : `${m}m`;
};

const ICON = {
  play: `<svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true"><path fill="currentColor" d="M6 4.6v14.8a1 1 0 0 0 1.5.87l12.8-7.4a1 1 0 0 0 0-1.74L7.5 3.73A1 1 0 0 0 6 4.6z"/></svg>`,
  info: `<svg viewBox="0 0 24 24" width="24" height="24" aria-hidden="true"><circle cx="12" cy="12" r="9.5" fill="none" stroke="currentColor" stroke-width="2"/><path fill="currentColor" d="M11 10.5h2V17h-2zM11 7h2v2h-2z"/></svg>`,
  plus: `<svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path d="M12 5v14M5 12h14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>`,
  check: `<svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  prev: `<svg viewBox="0 0 24 24" width="28" height="28" aria-hidden="true"><path d="M15 5l-7 7 7 7" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  next: `<svg viewBox="0 0 24 24" width="28" height="28" aria-hidden="true"><path d="M9 5l7 7-7 7" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  thumb: `<svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" d="M2 21h4V9H2v12zm21-11c0-1.1-.9-2-2-2h-6.3l1-4.6v-.3c0-.4-.2-.8-.4-1L14.2 1 7.6 7.6C7.2 8 7 8.5 7 9v10c0 1.1.9 2 2 2h9c.8 0 1.5-.5 1.8-1.2l3-7c.1-.3.2-.5.2-.8v-2z"/></svg>`,
  thumbOn: `<svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="currentColor" d="M2 21h4V9H2v12zm21-11c0-1.1-.9-2-2-2h-6.3l1-4.6v-.3c0-.4-.2-.8-.4-1L14.2 1 7.6 7.6C7.2 8 7 8.5 7 9v10c0 1.1.9 2 2 2h9c.8 0 1.5-.5 1.8-1.2l3-7c.1-.3.2-.5.2-.8v-2z"/></svg>`,
  face: `<svg viewBox="0 0 32 32" aria-hidden="true"><circle cx="10.5" cy="12.5" r="2.1" fill="#fff"/><circle cx="21.5" cy="12.5" r="2.1" fill="#fff"/><path d="M8.5 19.5c4 4 11 4 15 0" fill="none" stroke="#fff" stroke-width="2.2" stroke-linecap="round"/></svg>`,
  pencil: `<svg viewBox="0 0 24 24" width="30" height="30" aria-hidden="true"><path d="M4 20h4L19 9l-4-4L4 16v4zM13.5 6.5l4 4" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  caret: `<svg class="caret" viewBox="0 0 12 12" width="10" height="10" aria-hidden="true"><path d="M1 3.5h10L6 9z" fill="currentColor"/></svg>`,
  x: `<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>`,
};

/* =========================================================
   TMDB HELPER: one place that builds the URL and checks errors
   ========================================================= */
async function tmdb(path, params = {}) {
  const url = new URL(TMDB + path);
  url.searchParams.set("api_key", TMDB_KEY);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }
  const res = await fetch(url);
  if (!res.ok) throw new Error(`TMDB error ${res.status}`);
  return res.json();
}

/* Same as tmdb(), but remembers answers so going back and forth is instant */
const cache = new Map();
function cached(path, params = {}) {
  const key = path + "?" + JSON.stringify(params);
  if (!cache.has(key)) {
    const request = tmdb(path, params).catch((err) => {
      cache.delete(key);                      // don't remember failures
      throw err;
    });
    cache.set(key, request);
  }
  return cache.get(key);
}

const details = (type, id) =>
  cached(`/${type}/${id}`, { append_to_response: "credits,recommendations" });

/* season 0 is usually "Specials", so skip it and any empty seasons */
const realSeasons = (show) =>
  (show.seasons || [])
    .filter((s) => s.season_number > 0 && s.episode_count > 0)
    .sort((a, b) => a.season_number - b.season_number);

/* =========================================================
   PROFILES + SAVED STUFF (localStorage)

   Profiles are optional. With no profile picked you are a guest:
   everything still plays, but nothing is remembered.

   Each profile keeps four lists:
     list     My List
     likes    titles given a thumbs up
     resume   Continue Watching (which episode you were on)
     history  everything played, newest first
   ========================================================= */
const disk = {
  read(key, fallback) {
    try {
      const value = JSON.parse(localStorage.getItem(key));
      return value ?? fallback;
    } catch {
      return fallback;
    }
  },
  write(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch {
      /* private mode or storage full: the app still works, it just won't remember */
    }
  },
  remove(key) {
    try {
      localStorage.removeItem(key);
    } catch {
      /* nothing to clean up */
    }
  },
};

const emptySaved = () => ({ list: [], likes: [], resume: [], history: [] });

function readProfiles() {
  const value = disk.read(PROFILES_KEY, []);
  if (!Array.isArray(value)) return [];
  return value.filter((p) => p && typeof p.id === "string" && typeof p.name === "string");
}

function readSaved(profile) {
  const result = emptySaved();
  if (!profile) return result;
  const value = disk.read(dataKey(profile.id), null) || {};
  for (const kind of Object.keys(result)) {
    if (Array.isArray(value[kind])) result[kind] = value[kind];
  }
  return result;
}

let profiles = readProfiles();
let activeProfile = profiles.find((p) => p.id === disk.read(ACTIVE_KEY, null)) || null;
let saved = readSaved(activeProfile);        // the active profile's lists (always empty for a guest)

function persist() {
  if (activeProfile) disk.write(dataKey(activeProfile.id), saved);
}

function setActiveProfile(profile) {
  activeProfile = profile;
  disk.write(ACTIVE_KEY, profile ? profile.id : null);
  saved = readSaved(profile);
  baseKey = null;                             // redraw the page with this profile's rows
  paintProfileButton();
}

function createProfile(name, avatar) {
  const id = `p${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
  const profile = { id, name, avatar };
  profiles.push(profile);
  disk.write(PROFILES_KEY, profiles);
  return profile;
}

function updateProfile(profile, name, avatar) {
  profile.name = name;
  profile.avatar = avatar;
  disk.write(PROFILES_KEY, profiles);
  paintProfileButton();
}

function deleteProfile(profile) {
  profiles = profiles.filter((p) => p.id !== profile.id);
  disk.write(PROFILES_KEY, profiles);
  disk.remove(dataKey(profile.id));           // its lists go with it
  if (activeProfile && activeProfile.id === profile.id) setActiveProfile(null);
  else paintProfileButton();
}

/* Saving needs a profile. Guests get a nudge instead. */
function needProfile() {
  if (activeProfile) return true;
  showToast("Create a profile to save your list, likes and progress.", true);
  return false;
}

/* The few fields a card needs, so we don't store whole API responses */
const slim = (item, type) => ({
  id: item.id,
  media_type: type,
  title: titleOf(item),
  poster_path: item.poster_path || null,
  backdrop_path: item.backdrop_path || null,
  release_date: item.release_date || item.first_air_date || "",
  vote_average: item.vote_average || 0,
});

const sameTitle = (type, id) => (x) => x.media_type === type && String(x.id) === String(id);

const isSaved = (kind, type, id) => saved[kind].some(sameTitle(type, id));

/* Add or remove a title from "list" or "likes" */
function toggleSaved(kind, item, type) {
  const index = saved[kind].findIndex(sameTitle(type, item.id));
  if (index === -1) saved[kind].unshift(slim(item, type));
  else saved[kind].splice(index, 1);
  persist();
  return index === -1;                        // true when it was just added
}

function removeSaved(kind, type, id) {
  saved[kind] = saved[kind].filter((x) => !sameTitle(type, id)(x));
  persist();
}

const getResume = (type, id) => saved.resume.find(sameTitle(type, id));
const getHistory = (type, id) => saved.history.find(sameTitle(type, id));

/* "2x5" = season 2 episode 5, the form watched episodes are remembered in */
const episodeTag = (season, episode) => `${season}x${episode}`;

/* Something started playing: remember where to resume and add it to the history */
function recordWatch(item, type, season, episode) {
  if (!activeProfile) return;                 // guests leave no trace
  const entry = slim(item, type);
  const others = (x) => !sameTitle(type, item.id)(x);

  const resume = type === "tv" ? { ...entry, season, episode } : entry;
  saved.resume = [resume, ...saved.resume.filter(others)].slice(0, 20);

  const old = getHistory(type, item.id);
  const episodes = old && Array.isArray(old.episodes) ? old.episodes : [];
  if (type === "tv" && !episodes.includes(episodeTag(season, episode))) {
    episodes.push(episodeTag(season, episode));
  }
  saved.history = [{ ...entry, watchedAt: Date.now(), episodes }, ...saved.history.filter(others)].slice(0, 200);

  persist();
}

/* Where "Play" should go: movies play directly, shows resume or start at the first episode */
function watchHref(type, id, seasons) {
  if (type === "movie") return `#/watch/movie/${id}`;
  const resume = getResume("tv", id);
  if (resume) return `#/watch/tv/${id}/${resume.season}/${resume.episode}`;
  const first = seasons && seasons.length ? seasons[0].season_number : 1;
  return `#/watch/tv/${id}/${first}/1`;
}

/* =========================================================
   CARDS + ROWS
   ========================================================= */
function cardHtml(item, opts = {}) {
  const type = typeOf(item);
  const id = Number(item.id);
  const title = titleOf(item) || "Untitled";
  const href = opts.href || `#/title/${type}/${id}`;

  const art = item.poster_path
    ? `<img src="${esc(image(item.poster_path, "w342"))}" alt="${esc(title)}" loading="lazy">`
    : `<div class="card-fallback">${esc(title)}</div>`;
  const match = item.vote_average
    ? `<b class="match">${Math.round(item.vote_average * 10)}% Match</b> · `
    : "";
  const meta = [yearOf(item), type === "tv" ? "Series" : "Movie"].filter(Boolean).join(" · ");

  return `
    <a class="card${opts.rank ? " card-rank" : ""}" href="${esc(href)}" title="${esc(title)}">
      ${opts.rank ? `<span class="rank" aria-hidden="true">${opts.rank}</span>` : ""}
      <div class="card-art">
        ${art}
        ${opts.badge ? `<span class="card-badge">${esc(opts.badge)}</span>` : ""}
        ${opts.play ? `<span class="card-play">${ICON.play}</span>` : ""}
        ${opts.remove ? `<span class="card-remove" role="button" tabindex="0" data-remove="${type}:${id}" aria-label="Remove from Continue Watching" title="Remove">✕</span>` : ""}
        <div class="card-info">
          <strong>${esc(title)}</strong>
          <span>${match}${esc(meta)}</span>
        </div>
      </div>
    </a>`;
}

const skeletonCards = (count) => `<div class="card skeleton"></div>`.repeat(count);

/* An empty row with placeholders; fillRow() swaps in the real cards */
function rowShell(title, moreHref) {
  const section = document.createElement("section");
  section.className = "row at-start";
  section.innerHTML = `
    <h2><span>${esc(title)}</span>${moreHref ? `<a class="row-more" href="${moreHref}">See All</a>` : ""}</h2>
    <div class="row-body">
      <button type="button" class="row-arrow prev" aria-label="Scroll left">${ICON.prev}</button>
      <div class="row-track">${skeletonCards(10)}</div>
      <button type="button" class="row-arrow next" aria-label="Scroll right">${ICON.next}</button>
    </div>`;

  const track = section.querySelector(".row-track");
  const updateArrows = () => {
    section.classList.toggle("at-start", track.scrollLeft < 8);
    section.classList.toggle("at-end", track.scrollLeft + track.clientWidth > track.scrollWidth - 8);
  };
  track.addEventListener("scroll", updateArrows, { passive: true });
  section.querySelector(".prev").addEventListener("click", () => {
    track.scrollBy({ left: -track.clientWidth * 0.85, behavior: "smooth" });
  });
  section.querySelector(".next").addEventListener("click", () => {
    track.scrollBy({ left: track.clientWidth * 0.85, behavior: "smooth" });
  });
  section.updateArrows = updateArrows;
  return section;
}

function fillRow(section, items, opts = {}) {
  const list = opts.top10 ? items.slice(0, 10) : items;
  section.querySelector(".row-track").innerHTML = list
    .map((item, i) => cardHtml(item, {
      rank: opts.top10 ? i + 1 : 0,
      ...(opts.card ? opts.card(item) : {}),
    }))
    .join("");
  section.updateArrows();
}

/* Fetch one row and tag every result with its type */
async function loadRow(def) {
  const data = await cached(def.path, def.params);
  return (data.results || [])
    .map((item) => ({ ...item, media_type: item.media_type || def.type }))
    .filter((item) => (item.media_type === "movie" || item.media_type === "tv") && item.poster_path);
}

/* =========================================================
   BROWSE PAGES: hero + rows
   ========================================================= */
function showBrowse() {
  heroEl.hidden = false;
  rowsEl.hidden = false;
  gridView.hidden = true;
}

function showGrid() {
  ++heroToken;                                // any billboard extras still loading are stale now
  heroEl.hidden = true;
  rowsEl.hidden = true;
  gridView.hidden = false;
  gridEl.classList.remove("as-list");
}

async function renderBrowse(view) {
  const token = ++renderToken;
  const defs = ROWS[view];

  showBrowse();
  heroEl.className = "hero loading";
  heroEl.innerHTML = "";
  rowsEl.className = "rows overlap";
  rowsEl.innerHTML = "";

  const sections = defs.map((def) => {
    const section = rowShell(def.title);
    rowsEl.appendChild(section);
    return section;
  });
  refreshPersonalRows();

  const results = await Promise.allSettled(
    defs.map(async (def, i) => {
      const items = await loadRow(def);
      if (token !== renderToken) return items;
      if (items.length) fillRow(sections[i], items, def);
      else sections[i].remove();
      if (i === 0) renderHero(items);
      return items;
    })
  );
  if (token !== renderToken) return;

  results.forEach((result, i) => {
    if (result.status === "rejected") {
      console.error(result.reason);
      sections[i].remove();
    }
  });

  if (results[0].status === "rejected") renderHero([]);
  if (results.every((result) => result.status === "rejected")) showLoadError();
}

function renderHero(items) {
  const token = ++heroToken;
  const picks = items
    .filter((item) => item.backdrop_path && item.poster_path && item.overview)
    .slice(0, 8);
  if (!picks.length) {
    heroEl.hidden = true;
    rowsEl.className = "rows no-hero";
    return;
  }

  const item = picks[Math.floor(Math.random() * picks.length)];
  const type = typeOf(item);
  const id = Number(item.id);

  const title = titleOf(item) || "Untitled";

  // Wide screens get the landscape backdrop, phones get the tall poster
  heroEl.className = "hero";
  heroEl.style.removeProperty("--ambient");
  heroEl.innerHTML = `
    <div class="hero-card">
      <a class="hero-link" href="#/title/${type}/${id}" aria-label="${esc(title)}: details">
        <picture>
          <source media="(max-width: 760px)" srcset="${esc(image(item.poster_path, "w780"))}">
          <img class="hero-img" src="${esc(image(item.backdrop_path, "w1280"))}" alt="">
        </picture>
      </a>
      <div class="hero-shade"></div>
      <div class="hero-body">
        <div class="hero-kicker">
          <img src="assets/fakeflix-icon.png" alt="">
          <span>${type === "tv" ? "SERIES" : "FILM"}</span>
        </div>
        <h1 id="hero-title">${esc(title)}</h1>
        <p class="hero-overview">${esc(item.overview)}</p>
        <p class="hero-genres" id="hero-genres"></p>
        <div class="hero-actions">
          <a class="btn btn-play" href="${watchHref(type, id)}">${ICON.play}Play</a>
          <a class="btn btn-info hero-info" href="#/title/${type}/${id}">${ICON.info}More Info</a>
          <button type="button" class="btn btn-info hero-list" id="hero-list"></button>
        </div>
      </div>
    </div>`;

  // "My List" button (shown on phones in place of More Info)
  const listBtn = $("hero-list");
  const paintListBtn = (added) => {
    listBtn.innerHTML = `${added ? ICON.check : ICON.plus}My List`;
    listBtn.setAttribute("aria-pressed", String(added));
  };
  paintListBtn(isSaved("list", type, id));
  listBtn.addEventListener("click", () => {
    if (!needProfile()) return;
    paintListBtn(toggleSaved("list", item, type));
    refreshPersonalRows();
  });

  decorateHero(item, type, token);
}

/* Extras that arrive after the billboard is on screen: the title's logo art,
   its genres, and a background tint taken from the poster. */
async function decorateHero(item, type, token) {
  sampleAmbient(item.poster_path, token);

  genreNames(type)
    .then((names) => {
      const el = $("hero-genres");
      if (token !== heroToken || !el) return;
      el.textContent = (item.genre_ids || []).map((id) => names[id]).filter(Boolean).slice(0, 3).join(" • ");
    })
    .catch((err) => console.error(err));

  try {
    const data = await cached(`/${type}/${Number(item.id)}/images`, { include_image_language: "en,null" });
    const heading = $("hero-title");
    if (token !== heroToken || !heading) return;

    const logos = data.logos || [];
    const logo = logos.find((l) => l.iso_639_1 === "en") || logos[0];
    if (!logo || !logo.file_path) return;       // no logo art: keep the plain text title

    const size = logo.file_path.endsWith(".svg") ? "original" : "w500";
    heading.innerHTML = `<img class="hero-logo" src="${esc(image(logo.file_path, size))}" alt="${esc(titleOf(item))}">`;
  } catch (err) {
    console.error(err);
  }
}

/* { genreId: "Name" } for movies or TV */
async function genreNames(type) {
  const data = await cached(`/genre/${type}/list`);
  const names = {};
  for (const genre of data.genres || []) names[genre.id] = genre.name;
  return names;
}

/* Average colour of the poster, darkened, used as the glow behind the phone billboard */
function sampleAmbient(posterPath, token) {
  const probe = new Image();
  probe.crossOrigin = "anonymous";              // needed to read the pixels back
  probe.onload = () => {
    if (token !== heroToken) return;
    try {
      const canvas = document.createElement("canvas");
      canvas.width = canvas.height = 8;
      const ctx = canvas.getContext("2d");
      ctx.drawImage(probe, 0, 0, 8, 8);
      const px = ctx.getImageData(0, 0, 8, 8).data;

      let r = 0, g = 0, b = 0;
      for (let i = 0; i < px.length; i += 4) {
        r += px[i];
        g += px[i + 1];
        b += px[i + 2];
      }
      const scale = 0.6 / (px.length / 4);      // average, then darken
      heroEl.style.setProperty("--ambient", `rgb(${Math.round(r * scale)}, ${Math.round(g * scale)}, ${Math.round(b * scale)})`);
    } catch {
      /* couldn't read the image: keep the default colour */
    }
  };
  probe.src = image(posterPath, "w92");
}

function showLoadError() {
  heroEl.hidden = true;
  rowsEl.className = "rows";
  rowsEl.innerHTML = `
    <div class="notice">
      <p>Couldn't load titles from TMDB.<br>Check your internet connection and try again.</p>
      <button type="button" id="retry">Retry</button>
    </div>`;
  $("retry").addEventListener("click", () => {
    baseKey = null;
    route();
  });
}

/* How a Continue Watching card looks: it plays straight away, shows which
   episode you were on, and has a ✕ to drop it from the row. */
const resumeCard = (item) =>
  item.media_type === "tv"
    ? {
        play: true,
        remove: true,
        href: `#/watch/tv/${Number(item.id)}/${Number(item.season)}/${Number(item.episode)}`,
        badge: `S${Number(item.season)} E${Number(item.episode)}`,
      }
    : { play: true, remove: true, href: `#/watch/movie/${Number(item.id)}` };

/* The active profile's rows ("Continue Watching", "My List", "Because you
   liked …"), kept right under the first row. Guests have none. */
function refreshPersonalRows() {
  const token = ++personalToken;
  if (!(baseView in VIEW_TYPE)) return;       // only Home, Movies and TV Shows have them
  rowsEl.querySelectorAll(".row[data-personal]").forEach((row) => row.remove());

  const only = VIEW_TYPE[baseView];
  const wanted = (item) => !only || item.media_type === only;
  const sections = [];

  const resume = saved.resume.filter(wanted);
  if (resume.length) {
    const name = activeProfile ? `Continue Watching for ${activeProfile.name}` : "Continue Watching";
    const section = rowShell(name);
    section.dataset.personal = "resume";
    sections.push([section, resume, { card: resumeCard }]);
  }

  const list = saved.list.filter(wanted);
  if (list.length) {
    const section = rowShell("My List");
    section.dataset.personal = "list";
    sections.push([section, list, {}]);
  }

  const anchor = rowsEl.querySelector(".row");
  for (const [section, items, opts] of sections.reverse()) {
    if (anchor) anchor.after(section);
    else rowsEl.prepend(section);
    fillRow(section, items, opts);
  }

  const liked = saved.likes.find(wanted);
  if (liked) addBecauseRow(liked, wanted, token);
}

/* Recommendations based on the most recent thumbs up */
async function addBecauseRow(liked, wanted, token) {
  try {
    const data = await cached(`/${liked.media_type}/${Number(liked.id)}/recommendations`);
    if (token !== personalToken) return;      // the rows were redrawn meanwhile

    const items = (data.results || [])
      .map((item) => ({ ...item, media_type: item.media_type || liked.media_type }))
      .filter((item) => (item.media_type === "movie" || item.media_type === "tv") && item.poster_path && wanted(item));
    if (items.length < 4) return;

    const section = rowShell(`Because you liked ${liked.title}`);
    section.dataset.personal = "because";
    const personal = rowsEl.querySelectorAll(".row[data-personal]");
    const anchor = personal.length ? personal[personal.length - 1] : rowsEl.querySelector(".row");
    if (anchor) anchor.after(section);
    else rowsEl.prepend(section);
    fillRow(section, items);
  } catch (err) {
    console.error(err);
  }
}

/* =========================================================
   GRID PAGES: My List, Liked, Watch History + Search
   ========================================================= */
const SAVED_PAGES = {
  "my-list": { kind: "list", title: "My List", empty: "You haven't added anything to your list yet." },
  liked: { kind: "likes", title: "Liked", empty: "Titles you give a thumbs up will show up here." },
  history: { kind: "history", title: "Watch History", empty: "Nothing watched on this profile yet." },
};

const watchedOn = (item) =>
  item.watchedAt
    ? new Date(item.watchedAt).toLocaleDateString(undefined, { month: "short", day: "numeric" })
    : "";

function renderSavedPage(name) {
  ++renderToken;
  showGrid();

  const page = SAVED_PAGES[name];
  const items = saved[page.kind];

  gridTitle.textContent = page.title;
  gridEl.innerHTML = items
    .map((item) => cardHtml(item, name === "history" ? { badge: watchedOn(item) } : {}))
    .join("");

  gridEmpty.hidden = items.length > 0;
  if (activeProfile) {
    gridEmpty.textContent = page.empty;
  } else {
    gridEmpty.innerHTML = `
      You're browsing as a guest, so nothing is saved.<br>
      A profile keeps your list, likes and watch history in this browser.<br>
      <a class="ghost-btn" href="#/profiles">${profiles.length ? "Choose a profile" : "Create a profile"}</a>`;
  }

  gridAction.hidden = !(name === "history" && items.length);
  gridAction.textContent = "Clear history";
}

gridAction.addEventListener("click", () => {
  if (baseView !== "history") return;
  if (!confirm("Clear this profile's watch history? Continue Watching is kept.")) return;
  saved.history = [];
  persist();
  renderSavedPage("history");
});

// the ✕ on a Continue Watching card
rowsEl.addEventListener("click", (e) => {
  const removeBtn = e.target.closest("[data-remove]");
  if (!removeBtn) return;
  e.preventDefault();                         // it sits inside the card's link
  const [type, id] = removeBtn.dataset.remove.split(":");
  removeSaved("resume", type, id);
  if (baseView === "me") renderMe();
  else refreshPersonalRows();
});

/* The search page before anything is typed: a list of what's popular */
async function renderTopSearches(thisSearch) {
  gridTitle.textContent = "Top Searches";
  gridEl.classList.add("as-list");
  gridEl.innerHTML = "";

  try {
    const items = (await loadRow({ path: "/trending/all/week" })).filter((item) => item.backdrop_path);
    if (thisSearch !== searchCount) return;
    gridEl.innerHTML = items
      .map((item) => `
        <a class="top-row" href="#/title/${typeOf(item)}/${Number(item.id)}">
          <img src="${esc(image(item.backdrop_path, "w300"))}" alt="" loading="lazy">
          <span>${esc(titleOf(item))}</span>
          <span class="top-play">${ICON.play}</span>
        </a>`)
      .join("");
  } catch (err) {
    console.error(err);
    if (thisSearch !== searchCount) return;
    gridEmpty.hidden = false;
    gridEmpty.textContent = "Couldn't load suggestions. Check your connection and try again.";
  }
}

/* Everything in one category, movies and shows taking turns */
async function renderGenre(slug, type) {
  const token = ++renderToken;
  const category = CATEGORIES.find((c) => c.slug === slug);

  showGrid();
  gridTitle.textContent = category.name + (type === "movie" ? " Movies" : type === "tv" ? " Shows" : "");
  gridAction.hidden = true;
  gridEmpty.hidden = true;
  gridEl.innerHTML = skeletonCards(18);

  const types = ["movie", "tv"].filter((t) => category[t] && (!type || type === t));
  try {
    const lists = await Promise.all(
      types.map((t) => loadRow({
        path: `/discover/${t}`,
        type: t,
        params: { with_genres: category[t], "vote_count.gte": "100" },
      }))
    );
    if (token !== renderToken) return;

    const items = [];
    const longest = Math.max(0, ...lists.map((list) => list.length));
    for (let i = 0; i < longest; i++) {
      for (const list of lists) if (list[i]) items.push(list[i]);
    }
    gridEl.innerHTML = items.map((item) => cardHtml(item)).join("");
    gridEmpty.hidden = items.length > 0;
    gridEmpty.textContent = "Nothing in this category yet.";
  } catch (err) {
    console.error(err);
    if (token !== renderToken) return;
    gridEl.innerHTML = "";
    gridEmpty.hidden = false;
    gridEmpty.textContent = "Couldn't load this category. Check your connection and try again.";
  }
}

/* "My FakeFlix": the profile and everything saved on it, in one place */
function renderMe() {
  ++renderToken;
  ++heroToken;
  showBrowse();
  heroEl.hidden = true;
  rowsEl.className = "rows no-hero";

  rowsEl.innerHTML = activeProfile
    ? `<section class="me-head">
         <a class="me-profile" href="#/profiles">
           ${avatarHtml(activeProfile)}
           <strong>${esc(activeProfile.name)}${ICON.caret}</strong>
         </a>
       </section>`
    : `<section class="me-head">
         <div class="me-profile">${avatarHtml(null)}<strong>Guest</strong></div>
         <p>You're browsing as a guest, so nothing is saved. A profile keeps your list, likes and watch history in this browser.</p>
         <a class="solid-btn" href="#/profiles">${profiles.length ? "Choose a profile" : "Create a profile"}</a>
       </section>`;

  const groups = [
    ["TV Shows & Movies You've Liked", saved.likes, "#/liked", {}],
    ["My List", saved.list, "#/my-list", {}],
    ["Continue Watching", saved.resume, null, { card: resumeCard }],
    ["Recently Watched", saved.history, "#/history", {}],
  ];
  let shown = 0;
  for (const [title, items, moreHref, opts] of groups) {
    if (!items.length) continue;
    const section = rowShell(title, moreHref);
    rowsEl.appendChild(section);
    fillRow(section, items, opts);
    shown++;
  }

  if (activeProfile && !shown) {
    rowsEl.insertAdjacentHTML(
      "beforeend",
      `<p class="me-empty">Titles you like, add to My List or watch will show up here.</p>`
    );
  }
}

async function renderSearch(query) {
  ++renderToken;
  const thisSearch = ++searchCount;

  showGrid();
  gridAction.hidden = true;
  gridEmpty.hidden = true;
  if (!query) return renderTopSearches(thisSearch);

  gridTitle.innerHTML = `Results for <em>“${esc(query)}”</em>`;
  gridEl.innerHTML = skeletonCards(14);

  try {
    // one search across movies and shows instead of one per tab
    const data = await tmdb("/search/multi", { query, include_adult: "false" });
    if (thisSearch !== searchCount) return;   // a newer search already started

    const items = (data.results || []).filter(
      (item) => (item.media_type === "movie" || item.media_type === "tv") && item.poster_path
    );
    gridEl.innerHTML = items.map((item) => cardHtml(item)).join("");
    gridEmpty.hidden = items.length > 0;
    gridEmpty.textContent = `No movies or shows match “${query}”.`;
  } catch (err) {
    console.error(err);
    if (thisSearch !== searchCount) return;
    gridEl.innerHTML = "";
    gridEmpty.hidden = false;
    gridEmpty.textContent = "Search failed. Check your connection and try again.";
  }
}

/* =========================================================
   TITLE MODAL
   ========================================================= */
async function openModal(type, id) {
  const token = ++modalToken;
  modalEl.hidden = false;
  modalEl.scrollTop = 0;
  modalBody.innerHTML = `<div class="modal-hero loading"></div><div class="modal-body"></div>`;

  try {
    const item = await details(type, id);
    if (token !== modalToken) return;         // another title was opened meanwhile
    renderModal(item, type);
  } catch (err) {
    console.error(err);
    if (token !== modalToken) return;
    modalBody.innerHTML = `<div class="notice"><p>Couldn't load this title.</p></div>`;
  }
}

function closeModal() {
  if (modalEl.hidden) return;
  ++modalToken;
  episodeKey = "";
  modalEl.hidden = true;
  modalBody.innerHTML = "";
}

function renderModal(item, type) {
  const id = Number(item.id);
  const title = titleOf(item) || "Untitled";
  const seasons = type === "tv" ? realSeasons(item) : [];
  const resume = getResume(type, id);

  const backdrop = item.backdrop_path
    ? `<img src="${esc(image(item.backdrop_path, "w1280"))}" alt="">`
    : "";
  const playLabel = type === "tv" && resume ? `Play S${resume.season} E${resume.episode}` : "Play";

  const length = type === "movie"
    ? runtimeText(item.runtime)
    : seasons.length ? `${seasons.length} Season${seasons.length > 1 ? "s" : ""}` : "";
  const meta = [
    item.vote_average ? `<span class="match">${Math.round(item.vote_average * 10)}% Match</span>` : "",
    yearOf(item) ? `<span>${esc(yearOf(item))}</span>` : "",
    length ? `<span>${esc(length)}</span>` : "",
    `<span class="badge">HD</span>`,
  ].join("");

  const cast = ((item.credits && item.credits.cast) || []).slice(0, 5).map((p) => p.name).join(", ");
  const genres = (item.genres || []).map((g) => g.name).join(", ");
  const makers = type === "tv"
    ? (item.created_by || []).map((p) => p.name).join(", ")
    : ((item.credits && item.credits.crew) || []).filter((p) => p.job === "Director").map((p) => p.name).join(", ");
  const facts = [
    cast ? `<p><span>Cast:</span> ${esc(cast)}</p>` : "",
    genres ? `<p><span>Genres:</span> ${esc(genres)}</p>` : "",
    makers ? `<p><span>${type === "tv" ? "Created by" : "Director"}:</span> ${esc(makers)}</p>` : "",
  ].join("");

  const more = ((item.recommendations && item.recommendations.results) || [])
    .map((x) => ({ ...x, media_type: x.media_type || type }))
    .filter((x) => x.poster_path && (x.media_type === "movie" || x.media_type === "tv"))
    .slice(0, 12);

  const episodesSection = seasons.length
    ? `<div class="section-head">
         <h3>Episodes</h3>
         <select id="season-select" class="season-select" aria-label="Season">
           ${seasons.map((s) => `<option value="${s.season_number}" data-count="${s.episode_count}">Season ${s.season_number}</option>`).join("")}
         </select>
       </div>
       <div id="episode-list"></div>`
    : "";

  modalBody.innerHTML = `
    <div class="modal-hero">
      ${backdrop}
      <div class="modal-head">
        <h2>${esc(title)}</h2>
        <div class="modal-actions">
          <a class="btn btn-play" href="${watchHref(type, id, seasons)}">${ICON.play}${playLabel}</a>
          <button type="button" id="list-toggle" class="icon-btn"></button>
          <button type="button" id="like-toggle" class="icon-btn"></button>
        </div>
      </div>
    </div>
    <div class="modal-body">
      <div class="modal-info">
        <div>
          <div class="meta">${meta}</div>
          ${item.tagline ? `<p class="tagline">${esc(item.tagline)}</p>` : ""}
          <p class="overview">${esc(item.overview || "No description available.")}</p>
        </div>
        <div class="facts">${facts}</div>
      </div>
      ${episodesSection}
      ${more.length ? `<div class="section-head"><h3>More Like This</h3></div>
                       <div class="more-grid">${more.map((x) => cardHtml(x)).join("")}</div>` : ""}
    </div>`;

  // My List button
  const listBtn = $("list-toggle");
  const paintListBtn = (added) => {
    listBtn.innerHTML = `${added ? ICON.check : ICON.plus}<span class="label">My List</span>`;
    listBtn.setAttribute("aria-label", added ? "Remove from My List" : "Add to My List");
    listBtn.title = added ? "Remove from My List" : "Add to My List";
  };
  paintListBtn(isSaved("list", type, id));
  listBtn.addEventListener("click", () => {
    if (needProfile()) paintListBtn(toggleSaved("list", item, type));
  });

  // Thumbs up
  const likeBtn = $("like-toggle");
  const paintLikeBtn = (liked) => {
    likeBtn.innerHTML = `${liked ? ICON.thumbOn : ICON.thumb}<span class="label">${liked ? "Liked" : "Like"}</span>`;
    likeBtn.classList.toggle("on", liked);
    likeBtn.setAttribute("aria-pressed", String(liked));
    likeBtn.setAttribute("aria-label", liked ? "Remove like" : "I like this");
    likeBtn.title = liked ? "Remove like" : "I like this";
  };
  paintLikeBtn(isSaved("likes", type, id));
  likeBtn.addEventListener("click", () => {
    if (needProfile()) paintLikeBtn(toggleSaved("likes", item, type));
  });

  // Seasons → episodes
  if (seasons.length) {
    const seasonSelect = $("season-select");
    const loadSelected = () => {
      const count = Number(seasonSelect.selectedOptions[0].dataset.count);
      loadEpisodes(item, Number(seasonSelect.value), count);
    };
    if (resume && seasons.some((s) => s.season_number === Number(resume.season))) {
      seasonSelect.value = String(resume.season);
    }
    seasonSelect.addEventListener("change", loadSelected);
    loadSelected();
  }
}

/* A season was picked → fill the episode list */
async function loadEpisodes(show, season, count) {
  const key = `${show.id}:${season}`;
  episodeKey = key;

  const listEl = $("episode-list");
  listEl.innerHTML = `<p class="episodes-note">Loading episodes…</p>`;

  // Fallback: plain numbers 1..count, in case the episode-names request fails
  let episodes = [];
  for (let n = 1; n <= count; n++) episodes.push({ number: n, name: "" });

  // Try to get episode names too
  try {
    const data = await cached(`/tv/${show.id}/season/${season}`);
    if (data.episodes && data.episodes.length) {
      episodes = data.episodes.map((ep) => ({
        number: ep.episode_number,
        name: ep.name,
        overview: ep.overview,
        still: ep.still_path,
        runtime: ep.runtime,
      }));
    }
  } catch (err) {
    console.error(err);
  }

  // user changed season, or opened another show, meanwhile
  if (episodeKey !== key || !listEl.isConnected) return;

  const resume = getResume("tv", show.id);
  const history = getHistory("tv", show.id);
  const watched = history && Array.isArray(history.episodes) ? history.episodes : [];
  listEl.innerHTML = episodes
    .map((ep) => {
      const current = resume && Number(resume.season) === season && Number(resume.episode) === ep.number;
      const seen = watched.includes(episodeTag(season, ep.number));
      const still = ep.still
        ? `<img src="${esc(image(ep.still, "w300"))}" alt="" loading="lazy">`
        : "";
      return `
        <a class="episode${current ? " current" : ""}" href="#/watch/tv/${Number(show.id)}/${season}/${Number(ep.number)}">
          <span class="episode-num">${Number(ep.number)}</span>
          <div class="episode-still">${still}<span class="play-dot">${ICON.play}</span></div>
          <div class="episode-text">
            <div class="episode-top">
              <strong>${esc(ep.name || `Episode ${ep.number}`)}</strong>
              <span>${seen ? `<b class="seen">Watched</b>` : ""}${ep.runtime ? ` ${esc(runtimeText(ep.runtime))}` : ""}</span>
            </div>
            ${ep.overview ? `<p>${esc(ep.overview)}</p>` : ""}
          </div>
        </a>`;
    })
    .join("");
}

/* =========================================================
   PLAYER
   ========================================================= */

/* A fresh iframe per title, so the page's Back button isn't hijacked by
   the iframe's own history. */
function play(url) {
  if (url === playingUrl) return;
  playingUrl = url;

  const player = document.createElement("iframe");
  player.id = "player";
  player.allow = "autoplay; fullscreen; picture-in-picture";
  if (PLAYER_SANDBOX) player.setAttribute("sandbox", PLAYER_SANDBOX);
  player.src = url;
  watchFrame.replaceChildren(player);
}

async function openWatch({ type, id, season, episode }) {
  const token = ++watchToken;

  watchEl.hidden = false;
  watchBack.href = `#/title/${type}/${id}`;
  watchTitle.textContent = "";
  watchNext.hidden = true;

  play(type === "movie" ? movieUrl(id) : tvUrl(id, season, episode));

  // The video is already loading; now fetch the name and work out the next episode
  try {
    const item = await details(type, id);
    if (token !== watchToken) return;

    const label = type === "movie" ? titleOf(item) : `${titleOf(item)} · S${season} E${episode}`;
    watchTitle.textContent = label;
    document.title = `${label} · FakeFlix`;
    recordWatch(item, type, season, episode);

    const next = type === "tv" ? nextEpisode(item, season, episode) : null;
    if (next) {
      watchNext.href = `#/watch/tv/${id}/${next.season}/${next.episode}`;
      watchNext.hidden = false;
    }
  } catch (err) {
    console.error(err);
  }
}

function nextEpisode(show, season, episode) {
  const seasons = realSeasons(show);
  const index = seasons.findIndex((s) => s.season_number === season);
  if (index === -1) return null;
  if (episode < seasons[index].episode_count) return { season, episode: episode + 1 };
  if (seasons[index + 1]) return { season: seasons[index + 1].season_number, episode: 1 };
  return null;
}

function closeWatch() {
  if (watchEl.hidden) return;
  ++watchToken;
  playingUrl = "";
  watchFrame.replaceChildren();               // removing the iframe stops playback
  watchEl.hidden = true;
  document.title = "FakeFlix";
}

/* =========================================================
   ROUTING (everything lives in the URL hash)

   #/                       home
   #/movies  #/tv           one type only
   #/my-list                saved titles
   #/search/<query>         search results
   #/title/<type>/<id>      details modal
   #/watch/movie/<id>       player
   #/watch/tv/<id>/<s>/<e>  player
   ========================================================= */
function parseRoute() {
  let parts = [];
  try {
    parts = location.hash.replace(/^#\/?/, "").split("/").filter(Boolean).map(decodeURIComponent);
  } catch {
    /* badly encoded URL → fall through to home */
  }
  const [head, a, b, c, d] = parts;
  const isId = (value) => /^\d+$/.test(value || "");

  if (head === "title" && (a === "movie" || a === "tv") && isId(b)) {
    return { name: "title", type: a, id: b };
  }
  if (head === "watch" && a === "movie" && isId(b)) {
    return { name: "watch", type: "movie", id: b };
  }
  if (head === "watch" && a === "tv" && isId(b) && isId(c) && isId(d)) {
    return { name: "watch", type: "tv", id: b, season: Number(c), episode: Number(d) };
  }
  if (ROWS[head] || SAVED_PAGES[head] || head === "me" || head === "profiles") return { name: head };
  if (head === "search") return { name: "search", query: a || "" };
  if (head === "genre" && CATEGORIES.some((c) => c.slug === a)) {
    return { name: "genre", slug: a, type: b === "movie" || b === "tv" ? b : null };
  }
  return { name: "home" };
}

function route() {
  const r = parseRoute();
  closeProfileMenu();
  closeCategories();
  hideToast();

  if (r.name === "profiles") {
    closeWatch();
    closeModal();
    openProfiles();
  } else if (r.name === "title" || r.name === "watch") {
    // overlays sit on top of whatever page is already there
    closeProfiles();
    lastHash = location.hash;
    if (!baseKey) showBase({ name: "home" }, "#/");
    if (r.name === "title") {
      closeWatch();
      openModal(r.type, r.id);
    } else {
      closeModal();
      openWatch(r);
    }
  } else {
    closeProfiles();
    closeWatch();
    closeModal();
    lastHash = location.hash || "#/";
    showBase(r, lastHash);
  }

  syncLock();
  syncNav();
}

/* The page behind an overlay must not scroll */
function syncLock() {
  const overlayOpen = !modalEl.hidden || !watchEl.hidden || !profilesEl.hidden || !categoriesEl.hidden;
  document.body.classList.toggle("locked", overlayOpen);
}

function showBase(r, hash) {
  let key = r.name;
  if (r.name === "search") key = `search/${r.query}`;
  if (r.name === "genre") key = `genre/${r.slug}/${r.type || ""}`;
  baseHash = hash;

  navLinks.forEach((link) => link.classList.toggle("active", link.dataset.view === r.name));
  syncSearchBox(r);
  paintPhoneChrome(r);

  if (key === baseKey) {
    // same page as before (an overlay was closed): just refresh the saved rows
    if (SAVED_PAGES[r.name]) renderSavedPage(r.name);
    else if (r.name === "me") renderMe();
    else refreshPersonalRows();
    return;
  }

  baseKey = key;
  baseView = r.name;
  window.scrollTo(0, 0);

  if (r.name === "search") renderSearch(r.query);
  else if (r.name === "genre") renderGenre(r.slug, r.type);
  else if (r.name === "me") renderMe();
  else if (SAVED_PAGES[r.name]) renderSavedPage(r.name);
  else renderBrowse(r.name);
}

/* =========================================================
   PHONE LAYOUT: header title, filter chips, tab bar, categories
   (these elements are hidden on wide screens)
   ========================================================= */
function paintPhoneChrome(r) {
  const category = r.name === "genre" ? CATEGORIES.find((c) => c.slug === r.slug) : null;
  mTitle.textContent = category ? category.name : VIEW_TITLES[r.name] || "Home";
  document.body.dataset.view = r.name;

  // What the Categories picker should be limited to on this page
  categoryType = r.name === "genre" ? r.type : VIEW_TYPE[r.name] || null;

  const chip = (label, href, active) =>
    `<a class="chip${active ? " active" : ""}" href="${href}">${label}</a>`;
  const picker = (label, active) =>
    `<button type="button" class="chip${active ? " active" : ""}" data-categories>${esc(label)}${ICON.caret}</button>`;
  const close = `<a class="chip chip-close" href="#/" aria-label="Back to Home">${ICON.x}</a>`;

  let html = "";
  if (r.name === "home") {
    html = chip("Shows", "#/tv") + chip("Movies", "#/movies") + chip("New &amp; Hot", "#/new") + picker("Categories");
  } else if (r.name === "tv") {
    html = close + chip("Shows", "#/tv", true) + picker("Categories");
  } else if (r.name === "movies") {
    html = close + chip("Movies", "#/movies", true) + picker("Categories");
  } else if (r.name === "new") {
    html = close + chip("New &amp; Hot", "#/new", true);
  } else if (category) {
    html = close + picker(category.name, true);
  }
  chipsEl.innerHTML = html;
  chipsEl.hidden = !html;
  nav.classList.remove("chips-away");

  const browsing = ROWS[r.name] || r.name === "genre";
  const tab = browsing ? "home" : r.name === "search" ? "search" : "me";
  tabbar.querySelectorAll("a").forEach((link) => {
    link.classList.toggle("active", link.dataset.tab === tab);
  });
}

function openCategories() {
  const current = baseView === "genre" ? baseKey.split("/")[1] : "";
  const suffix = categoryType ? `/${categoryType}` : "";
  const links = CATEGORIES
    .filter((c) => !categoryType || c[categoryType])
    .map((c) => `<a href="#/genre/${c.slug}${suffix}"${c.slug === current ? ` class="current"` : ""}>${esc(c.name)}</a>`)
    .join("");

  // first entry: the page these categories belong to
  const [parentName, parentHref] =
    categoryType === "tv" ? ["TV Shows", "#/tv"] : categoryType === "movie" ? ["Movies", "#/movies"] : ["Home", "#/"];

  categoriesList.innerHTML = `<a href="${parentHref}"${current ? "" : ` class="current"`}>${parentName}</a>${links}`;
  categoriesEl.hidden = false;
  categoriesEl.scrollTop = 0;
  syncLock();
}

function closeCategories() {
  if (categoriesEl.hidden) return;
  categoriesEl.hidden = true;
  syncLock();
}

chipsEl.addEventListener("click", (e) => {
  if (e.target.closest("[data-categories]")) openCategories();
});

// picking the page you're already on doesn't change the URL, so close by hand
categoriesList.addEventListener("click", closeCategories);
$("categories-close").addEventListener("click", closeCategories);

/* =========================================================
   PROFILES: avatar menu, "Who's watching?" screen, toast
   ========================================================= */
function avatarHtml(profile) {
  if (!profile) {
    return `<span class="avatar guest"><img src="assets/fakeflix-icon.png" alt=""></span>`;
  }
  const color = AVATAR_COLORS[Math.abs(Number(profile.avatar) || 0) % AVATAR_COLORS.length];
  return `<span class="avatar" style="background:${color}">${ICON.face}</span>`;
}

/* The avatar in the nav and the menu under it */
function paintProfileButton() {
  profileBtn.innerHTML = avatarHtml(activeProfile) + ICON.caret;
  tabAvatar.innerHTML = avatarHtml(activeProfile);    // the "My FakeFlix" tab on phones

  if (!activeProfile) {
    profileMenu.innerHTML = `
      <p class="menu-note">You're browsing as a guest. Everything plays, nothing is saved.</p>
      <a href="#/profiles">${profiles.length ? "Choose a profile" : "Create a profile"}</a>`;
    return;
  }

  const others = profiles.filter((p) => p.id !== activeProfile.id);
  profileMenu.innerHTML = `
    <div class="menu-head">${avatarHtml(activeProfile)}<strong>${esc(activeProfile.name)}</strong></div>
    <a href="#/my-list">My List</a>
    <a href="#/liked">Liked</a>
    <a href="#/history">Watch History</a>
    <hr>
    ${others.map((p) => `<button type="button" data-switch="${esc(p.id)}">${avatarHtml(p)}${esc(p.name)}</button>`).join("")}
    <a href="#/profiles">Manage Profiles</a>
    <button type="button" data-guest>Browse as guest</button>`;
}

function closeProfileMenu() {
  profileMenu.hidden = true;
  profileBtn.setAttribute("aria-expanded", "false");
}

profileBtn.addEventListener("click", () => {
  const open = profileMenu.hidden;
  profileMenu.hidden = !open;
  profileBtn.setAttribute("aria-expanded", String(open));
});

profileMenu.addEventListener("click", (e) => {
  const switchBtn = e.target.closest("[data-switch]");
  const guestBtn = e.target.closest("[data-guest]");
  if (switchBtn) setActiveProfile(profiles.find((p) => p.id === switchBtn.dataset.switch) || null);
  else if (guestBtn) setActiveProfile(null);
  else return;                                // a plain link: the hash change handles it
  route();
});

// clicking anywhere else closes the menu
document.addEventListener("click", (e) => {
  if (!e.target.closest(".profile-wrap")) closeProfileMenu();
});

function openProfiles() {
  if (profilesEl.hidden) profileMode = "pick";
  profilesEl.hidden = false;
  renderProfiles();
}

function closeProfiles() {
  profilesEl.hidden = true;
}

/* Leave the profile screen and go back to where the user was */
function leaveProfiles() {
  location.hash = lastHash;
}

function renderProfiles() {
  if (profileMode === "edit") return renderProfileForm();

  const managing = profileMode === "manage";
  const tiles = profiles
    .map((p) => `
      <button type="button" class="profile-tile" data-${managing ? "edit" : "pick"}="${esc(p.id)}">
        <span class="tile-art">${avatarHtml(p)}${managing ? `<span class="tile-edit">${ICON.pencil}</span>` : ""}</span>
        <span class="tile-name">${esc(p.name)}</span>
      </button>`)
    .join("");
  const addTile = profiles.length < MAX_PROFILES
    ? `<button type="button" class="profile-tile" data-add>
         <span class="tile-art"><span class="avatar add">${ICON.plus}</span></span>
         <span class="tile-name">Add Profile</span>
       </button>`
    : "";

  profilesBody.innerHTML = `
    <h1>${managing ? "Manage Profiles" : "Who's watching?"}</h1>
    <div class="profile-tiles">${tiles}${addTile}</div>
    <p class="profiles-note">
      Profiles are optional. Each one keeps its own list, likes, watch history and
      Continue Watching, stored only in this browser.
    </p>
    <div class="profiles-actions">
      ${managing
        ? `<button type="button" class="solid-btn" data-done>Done</button>`
        : `${profiles.length ? `<button type="button" class="ghost-btn" data-manage>Manage Profiles</button>` : ""}
           <button type="button" class="ghost-btn" data-guest>Continue as guest</button>`}
    </div>`;
}

function renderProfileForm() {
  const name = editing ? editing.name : "";
  profilesBody.innerHTML = `
    <h1>${editing ? "Edit Profile" : "Add Profile"}</h1>
    <form id="profile-form" class="profile-form" autocomplete="off">
      <span id="profile-preview" class="tile-art"></span>
      <div class="profile-fields">
        <input id="profile-name" type="text" maxlength="20" placeholder="Name" aria-label="Profile name" value="${esc(name)}">
        <div class="swatches" role="group" aria-label="Avatar colour">
          ${AVATAR_COLORS.map((color, i) => `<button type="button" class="swatch" data-avatar="${i}" style="background:${color}" aria-label="Colour ${i + 1}"></button>`).join("")}
        </div>
        <p id="profile-error" class="profile-error" hidden></p>
      </div>
    </form>
    <div class="profiles-actions">
      <button type="submit" form="profile-form" class="solid-btn">Save</button>
      <button type="button" class="ghost-btn" data-cancel>Cancel</button>
      ${editing ? `<button type="button" class="ghost-btn danger" data-delete>Delete Profile</button>` : ""}
    </div>`;

  paintProfileDraft();
  $("profile-form").addEventListener("submit", saveProfileForm);
  $("profile-name").focus();
}

/* Show the picked colour in the preview and mark its swatch */
function paintProfileDraft() {
  $("profile-preview").innerHTML = avatarHtml({ avatar: draftAvatar });
  profilesBody.querySelectorAll(".swatch").forEach((swatch) => {
    swatch.classList.toggle("on", Number(swatch.dataset.avatar) === draftAvatar);
  });
}

function saveProfileForm(e) {
  e.preventDefault();
  const name = $("profile-name").value.trim();
  const error = $("profile-error");

  const taken = profiles.some((p) => p !== editing && p.name.toLowerCase() === name.toLowerCase());
  if (!name || taken) {
    error.textContent = name ? "There is already a profile with that name." : "Enter a name for this profile.";
    error.hidden = false;
    return;
  }

  if (editing) {
    updateProfile(editing, name, draftAvatar);
    profileMode = "manage";
    renderProfiles();
  } else {
    setActiveProfile(createProfile(name, draftAvatar));   // a new profile is used straight away
    leaveProfiles();
  }
}

profilesBody.addEventListener("click", (e) => {
  const hit = (attr) => e.target.closest(`[data-${attr}]`);
  const byId = (id) => profiles.find((p) => p.id === id) || null;
  let el;

  if ((el = hit("pick"))) {
    setActiveProfile(byId(el.dataset.pick));
    leaveProfiles();
  } else if (hit("guest")) {
    setActiveProfile(null);
    leaveProfiles();
  } else if (hit("add")) {
    editing = null;
    // start on the first colour no other profile is using
    const used = profiles.map((p) => Number(p.avatar));
    const free = AVATAR_COLORS.findIndex((_, i) => !used.includes(i));
    draftAvatar = free === -1 ? 0 : free;
    profileMode = "edit";
    renderProfiles();
  } else if ((el = hit("edit"))) {
    editing = byId(el.dataset.edit);
    draftAvatar = Math.abs(Number(editing && editing.avatar) || 0) % AVATAR_COLORS.length;
    profileMode = editing ? "edit" : "manage";
    renderProfiles();
  } else if (hit("manage")) {
    profileMode = "manage";
    renderProfiles();
  } else if (hit("done")) {
    profileMode = "pick";
    renderProfiles();
  } else if (hit("cancel")) {
    profileMode = editing ? "manage" : "pick";
    renderProfiles();
  } else if (hit("delete")) {
    if (!editing) return;
    if (!confirm(`Delete "${editing.name}" and everything saved on it? This can't be undone.`)) return;
    deleteProfile(editing);
    profileMode = profiles.length ? "manage" : "pick";
    renderProfiles();
  } else if ((el = hit("avatar"))) {
    draftAvatar = Number(el.dataset.avatar);
    paintProfileDraft();
  }
});

function showToast(text, offerProfile) {
  clearTimeout(toastTimer);
  toastText.textContent = text;
  toastAction.hidden = !offerProfile;
  toastAction.textContent = profiles.length ? "Choose profile" : "Create profile";
  toastEl.hidden = false;
  toastTimer = setTimeout(hideToast, 6000);
}

function hideToast() {
  clearTimeout(toastTimer);
  toastEl.hidden = true;
}

/* The nav is see-through over the hero and solid everywhere else */
function syncNav() {
  const y = window.scrollY;
  nav.classList.toggle("solid", y > 10 || !ROWS[baseView]);

  // Phone: the filter chips tuck away while scrolling down and come back on the way up
  if (y > 120 && y > lastScrollY + 6) nav.classList.add("chips-away");
  else if (y <= 120 || y < lastScrollY - 6) nav.classList.remove("chips-away");
  lastScrollY = y;
}

/* =========================================================
   SEARCH BOX
   ========================================================= */
function syncSearchBox(r) {
  const typing = document.activeElement === searchInput;
  if (r.name === "search") {
    if (!typing) searchInput.value = r.query;
    setSearchOpen(true);
  } else if (!typing) {
    searchInput.value = "";
    setSearchOpen(false);
  }
  searchForm.classList.toggle("has-value", searchInput.value !== "");
}

function setSearchOpen(open) {
  searchForm.classList.toggle("open", open);
  nav.classList.toggle("searching", open);
}

function applySearch() {
  clearTimeout(debounceTimer);
  const q = searchInput.value.trim();
  const onSearch = baseView === "search";

  if (q.length < 2) {
    if (!onSearch) return;
    if (isPhone()) {
      // Search is its own tab on a phone: stay there and show Top Searches again
      history.replaceState(null, "", "#/search");
      route();
    } else {
      location.hash = preSearchHash;          // box emptied → back to where we were
    }
    return;
  }

  const target = `#/search/${encodeURIComponent(q)}`;
  if (onSearch) {
    // already searching: replace instead of adding a history entry per keystroke
    history.replaceState(null, "", target);
    route();
  } else {
    preSearchHash = baseHash;
    location.hash = target;
  }
}

searchToggle.addEventListener("click", () => {
  setSearchOpen(true);
  searchInput.focus();
});

searchInput.addEventListener("input", () => {
  searchForm.classList.toggle("has-value", searchInput.value !== "");
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(applySearch, 300);
});

searchInput.addEventListener("blur", () => {
  if (!searchInput.value.trim() && baseView !== "search") setSearchOpen(false);
});

searchClear.addEventListener("click", () => {
  searchInput.value = "";
  searchForm.classList.remove("has-value");
  searchInput.focus();
  applySearch();
});

// Enter key → search straight away instead of waiting for the debounce
searchForm.addEventListener("submit", (e) => {
  e.preventDefault();
  applySearch();
});

/* =========================================================
   GLOBAL EVENTS
   ========================================================= */
modalClose.addEventListener("click", () => { location.hash = baseHash; });

// clicking the dark area around the modal closes it
modalEl.addEventListener("click", (e) => {
  if (e.target === modalEl) location.hash = baseHash;
});

document.addEventListener("keydown", (e) => {
  // Enter / Space on the ✕ of a Continue Watching card
  if ((e.key === "Enter" || e.key === " ") && e.target.matches && e.target.matches("[data-remove]")) {
    e.preventDefault();
    e.target.click();
    return;
  }
  if (e.key !== "Escape") return;
  if (!categoriesEl.hidden) closeCategories();
  else if (!profileMenu.hidden) closeProfileMenu();
  else if (!profilesEl.hidden) leaveProfiles();
  else if (!watchEl.hidden) location.hash = watchBack.getAttribute("href");
  else if (!modalEl.hidden) location.hash = baseHash;
});

/* Redirect guard: while the player is open, the browser asks "Leave site?"
   before this tab goes anywhere else. That catches an ad in the player trying
   to send the whole page to another site. (It also asks if you close or reload
   the tab mid-video.) A page can't block pop-up tabs or the ads inside the
   player itself; that takes a browser-level blocker. */
window.addEventListener("beforeunload", (e) => {
  if (watchEl.hidden) return;
  e.preventDefault();
  e.returnValue = "";
});

window.addEventListener("scroll", syncNav, { passive: true });
window.addEventListener("hashchange", route);

/* =========================================================
   START
   ========================================================= */
paintProfileButton();

// Rows load after the page does, so a scroll position remembered from before a
// reload would land somewhere random. Always start at the top instead.
if ("scrollRestoration" in history) history.scrollRestoration = "manual";

// Shared computer (two or more profiles): ask who's watching once per browser session
let askedThisSession = false;
try {
  askedThisSession = sessionStorage.getItem("fakeflix.asked") === "1";
  sessionStorage.setItem("fakeflix.asked", "1");
} catch {
  /* no sessionStorage: just don't ask */
  askedThisSession = true;
}
const startRoute = parseRoute().name;
if (profiles.length >= 2 && !askedThisSession && startRoute !== "watch" && startRoute !== "profiles") {
  lastHash = location.hash || "#/";
  history.replaceState(null, "", "#/profiles");
  openProfiles();
  document.body.classList.add("locked");
} else {
  route();
}
setTimeout(() => $("splash").classList.add("done"), 1100);
