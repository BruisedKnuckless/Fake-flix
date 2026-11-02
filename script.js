/* =========================================================
   CONFIG
   ========================================================= */
const API_BASE = "https://vidsrc.mov";
const movieUrl = (id) => `${API_BASE}/embed/movie/${id}`;
const tvUrl = (id, season, ep) => `${API_BASE}/embed/tv/${id}/${season}/${ep}`;

const TMDB_KEY = "67efa981973baa37ef02e529456ba057";
const TMDB = "https://api.themoviedb.org/3";
const POSTER = "https://image.tmdb.org/t/p/w92";

/* ---------- Elements ---------- */
const tabs          = document.querySelectorAll(".tab");
const form          = document.getElementById("search-form");
const input         = document.getElementById("search-input");
const resultsEl     = document.getElementById("results");
const tvControls    = document.getElementById("tv-controls");
const seasonSelect  = document.getElementById("season-select");
const episodeSelect = document.getElementById("episode-select");
const playBtn       = document.getElementById("play-btn");
const player        = document.getElementById("player");
const emptyEl       = document.getElementById("empty");
const nowPlaying    = document.getElementById("now-playing");

/* ---------- State ---------- */
let mode = "movie";          // "movie" or "tv", matches TMDB's URL paths
let lastResults = [];
let selectedShow = null;     // the TV show picked from the dropdown
let debounceTimer;
let searchCount = 0;         // used to ignore old, slow search responses

/* Movies use "title" + "release_date", TV shows use "name" + "first_air_date" */
const titleOf = (item) => item.title || item.name;
const dateOf  = (item) => item.release_date || item.first_air_date || "No date";

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

/* =========================================================
   TABS
   ========================================================= */
tabs.forEach((tab) => {
  tab.addEventListener("click", () => setMode(tab.dataset.mode));
});

function setMode(newMode) {
  if (newMode === mode) return;
  mode = newMode;

  tabs.forEach((t) => t.classList.toggle("active", t.dataset.mode === mode));
  input.value = "";
  input.placeholder = mode === "movie" ? "Search movies…" : "Search TV shows…";
  lastResults = [];
  resultsEl.hidden = true;
  resetTvControls();
  tvControls.hidden = mode !== "tv";
  input.focus();
}

/* =========================================================
   SEARCH (works for both tabs)
   ========================================================= */
async function search(query) {
  const thisSearch = ++searchCount;
  try {
    // mode is "movie" or "tv", so this calls /search/movie or /search/tv
    const data = await tmdb(`/search/${mode}`, { query });
    if (thisSearch !== searchCount) return;   // a newer search already started
    lastResults = data.results.slice(0, 8);
    renderResults(lastResults);
  } catch (err) {
    console.error(err);
    showInfo("Search failed");
  }
}

function renderResults(items) {
  if (!items.length) return showInfo("No results");

  resultsEl.innerHTML = "";
  for (const item of items) {
    const li = document.createElement("li");
    const poster = item.poster_path
      ? `<img src="${POSTER}${item.poster_path}" alt="">`
      : `<div class="no-poster"></div>`;

    li.innerHTML = `
      ${poster}
      <div>
        <strong>${titleOf(item)}</strong>
        <span>${dateOf(item)} · ID ${item.id}</span>
      </div>`;

    li.addEventListener("mousedown", (e) => {
      e.preventDefault();
      selectItem(item);
    });
    resultsEl.appendChild(li);
  }
  resultsEl.hidden = false;
}

function showInfo(text) {
  resultsEl.innerHTML = `<li class="info">${text}</li>`;
  resultsEl.hidden = false;
}

function selectItem(item) {
  resultsEl.hidden = true;
  input.value = titleOf(item);
  input.blur();

  if (mode === "movie") {
    play(movieUrl(item.id), titleOf(item));   // movies play straight away
  } else {
    loadShow(item);                           // TV shows need season + episode first
  }
}

/* =========================================================
   TV: SEASONS → EPISODES → PLAY
   ========================================================= */
function resetTvControls() {
  selectedShow = null;
  seasonSelect.innerHTML = `<option value="">Season</option>`;
  episodeSelect.innerHTML = `<option value="">Episode</option>`;
  seasonSelect.disabled = true;
  episodeSelect.disabled = true;
  playBtn.disabled = true;
}

// Step 1: a show was picked → fetch its seasons
async function loadShow(show) {
  resetTvControls();
  selectedShow = show;
  seasonSelect.innerHTML = `<option value="">Loading…</option>`;

  try {
    const details = await tmdb(`/tv/${show.id}`);
    if (selectedShow !== show) return;        // user picked another show meanwhile

    // season 0 is usually "Specials", so skip it and any empty seasons
    const seasons = details.seasons.filter((s) => s.season_number > 0 && s.episode_count > 0);

    seasonSelect.innerHTML = `<option value="">Season</option>`;
    for (const s of seasons) {
      seasonSelect.innerHTML +=
        `<option value="${s.season_number}" data-count="${s.episode_count}">Season ${s.season_number}</option>`;
    }
    seasonSelect.disabled = false;
  } catch (err) {
    console.error(err);
    seasonSelect.innerHTML = `<option value="">Couldn't load seasons</option>`;
  }
}

// Step 2: a season was picked → fill the episode list
seasonSelect.addEventListener("change", async () => {
  episodeSelect.innerHTML = `<option value="">Episode</option>`;
  episodeSelect.disabled = true;
  updatePlayBtn();

  const season = seasonSelect.value;
  if (!season) return;

  // Fallback: plain numbers 1..count, in case the episode-names request fails
  const count = Number(seasonSelect.selectedOptions[0].dataset.count);
  let episodes = [];
  for (let n = 1; n <= count; n++) episodes.push({ number: n, name: "" });

  // Try to get episode names too
  try {
    const data = await tmdb(`/tv/${selectedShow.id}/season/${season}`);
    if (data.episodes && data.episodes.length) {
      episodes = data.episodes.map((ep) => ({ number: ep.episode_number, name: ep.name }));
    }
  } catch (err) {
    console.error(err);
  }

  if (seasonSelect.value !== season) return;  // user changed season meanwhile

  for (const ep of episodes) {
    const label = ep.name ? `E${ep.number} · ${ep.name}` : `Episode ${ep.number}`;
    episodeSelect.innerHTML += `<option value="${ep.number}">${label}</option>`;
  }
  episodeSelect.disabled = false;
});

// Step 3: an episode was picked → enable the Play button
episodeSelect.addEventListener("change", updatePlayBtn);

function updatePlayBtn() {
  playBtn.disabled = !(selectedShow && seasonSelect.value && episodeSelect.value);
}

// Step 4: Play
playBtn.addEventListener("click", () => {
  const s = seasonSelect.value;
  const e = episodeSelect.value;
  play(tvUrl(selectedShow.id, s, e), `${titleOf(selectedShow)} · S${s} E${e}`);
});

/* =========================================================
   PLAYER
   ========================================================= */
function play(url, label) {
  player.src = url;
  emptyEl.hidden = true;
  nowPlaying.textContent = `Playing: ${label}`;
}

/* =========================================================
   INPUT EVENTS
   ========================================================= */
input.addEventListener("input", () => {
  clearTimeout(debounceTimer);
  if (mode === "tv") resetTvControls();       // typing a new show clears old season/episode

  const q = input.value.trim();
  if (q.length < 2) { resultsEl.hidden = true; return; }
  debounceTimer = setTimeout(() => search(q), 300);
});

// Enter key → pick the top result
form.addEventListener("submit", (e) => {
  e.preventDefault();
  if (lastResults.length) selectItem(lastResults[0]);
});

input.addEventListener("blur", () => { resultsEl.hidden = true; });
input.addEventListener("focus", () => {
  if (lastResults.length && input.value.trim()) resultsEl.hidden = false;
});
