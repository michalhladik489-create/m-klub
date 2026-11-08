/* M-klub: interaktivita veřejného webu (obsah je vykreslený na serveru, tady se jen oživuje). */
(function () {
  "use strict";
  const $ = (s, r) => (r || document).querySelector(s);
  const $$ = (s, r) => Array.from((r || document).querySelectorAll(s));
  const esc = (s) => String(s == null ? "" : s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  const norm = (s) => String(s).normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
  let cfg = {};
  try { cfg = JSON.parse($("#mk-config").textContent); } catch (e) {}
  const today = new Date().toLocaleDateString("sv-SE", { timeZone: "Europe/Prague" });
  const reduce = matchMedia("(prefers-reduced-motion:reduce)").matches;

  /* ---- menu, přeskočení na obsah ---- */
  const hd = $("#hd"), mb = $("#mb");
  if (mb) mb.addEventListener("click", () => { const o = hd.classList.toggle("open"); mb.setAttribute("aria-expanded", o); });
  $$("#nv a").forEach((a) => a.addEventListener("click", () => hd.classList.remove("open")));
  const sk = $("#sk"); if (sk) sk.addEventListener("click", () => $("#v").focus());

  /* ---- plynulé vynořování a plynulé kolečko myši ---- */
  const io = "IntersectionObserver" in window ? new IntersectionObserver((r) => r.forEach((x) => { if (x.isIntersecting) { x.target.classList.add("in"); io.unobserve(x.target); } }), { threshold: 0.08 }) : null;
  $$("#v .card, #v .cols>div, #v .gal>*, #v .calb, #v .det, #v section:not(.hero), #v .prose").forEach((el) => {
    if (!io || el.getBoundingClientRect().top < innerHeight) return;
    el.classList.add("rv"); io.observe(el);
  });
  if (!matchMedia("(pointer:coarse)").matches && !reduce) {
    let tg = scrollY, raf = 0;
    const de = document.documentElement;
    const inner = (t) => { for (let n = t; n && n !== document.body && n.nodeType === 1; n = n.parentElement) { const o = getComputedStyle(n).overflowY; if ((o === "auto" || o === "scroll") && n.scrollHeight > n.clientHeight + 1) return true; } return false; };
    const step = () => { const c = scrollY, d = tg - c; if (Math.abs(d) < 0.6) { scrollTo({ top: tg, behavior: "instant" }); raf = 0; return; } scrollTo({ top: c + d * 0.14, behavior: "instant" }); raf = requestAnimationFrame(step); };
    addEventListener("wheel", (e) => {
      if (e.ctrlKey || e.defaultPrevented || Math.abs(e.deltaX) > Math.abs(e.deltaY) || inner(e.target) || $("#lb:not([hidden])")) return;
      if (!raf) tg = scrollY;
      e.preventDefault();
      tg = Math.max(0, Math.min(de.scrollHeight - innerHeight, tg + (e.deltaMode === 1 ? e.deltaY * 16 : e.deltaY)));
      if (!raf) raf = requestAnimationFrame(step);
    }, { passive: false });
  }

  /* ---- hlavní nápis s ozvěnou ---- */
  function fit() {
    const fx = $("#fx"); if (!fx) return;
    const W = fx.clientWidth, Hc = fx.clientHeight; if (!W || !Hc) return;
    const word = fx.dataset.word || "M-KLUB";
    const m = document.createElement("span"); m.className = "fxm"; m.textContent = word; m.style.fontSize = "100px";
    fx.innerHTML = ""; fx.appendChild(m);
    const w = m.getBoundingClientRect().width || 400;
    const fs = Math.min((W * 0.97) / w * 100, (Hc * 0.6) / 0.74), Hb = 0.74 * fs, N = 12, R = Math.max(0, (Hc - Hb) / 2);
    let lo = 0.3, hi = 0.93;
    for (let k = 0; k < 20; k++) { const r = (lo + hi) / 2; let s = 0; for (let i = 1; i <= N; i++) s += Math.pow(r, i); s *= Hb; if (s < R * 1.5) lo = r; else hi = r; }
    const r = lo;
    const one = (i, d) => { const s = Math.pow(r, i), hh = Hb * s; if (hh < 1) return ""; return `<div class="fxl o" aria-hidden="true" style="height:${hh.toFixed(2)}px;opacity:${Math.max(0.2, 1 - i * 0.075).toFixed(2)}"><span style="font-size:${fs}px;transform:translate(-50%,-50%) scaleY(${(d * s).toFixed(4)})">${esc(word)}</span></div>`; };
    let h = ""; for (let i = N; i >= 1; i--) h += one(i, 1);
    h += `<div class="fxl" style="height:${Hb}px"><h1 style="font-size:${fs}px">${esc(word)}</h1></div>`;
    for (let i = 1; i <= N; i++) h += one(i, -1);
    fx.innerHTML = h;
  }
  fit(); addEventListener("resize", fit);
  if (document.fonts && document.fonts.ready) document.fonts.ready.then(fit);

  /* ---- posuvník programu na úvodní straně ---- */
  const list = $("#list");
  function pc() { const c = $("#pc"); if (!list || !c) return; const n = list.children.length, i = Math.min(n, Math.round(list.scrollLeft / (list.clientWidth || 1)) + 1); c.textContent = n ? String(i).padStart(2, "0") + " / " + String(n).padStart(2, "0") : ""; }
  if (list) { list.addEventListener("scroll", pc, { passive: true }); pc(); }
  $$("[data-sl]").forEach((b) => b.addEventListener("click", () => list.scrollBy({ left: list.clientWidth * Number(b.dataset.sl), behavior: "smooth" })));

  /* ---- seznam programu: hledání, datum, řazení ---- */
  const pl = $("#pl");
  if (pl) {
    const run = () => {
      const q = norm($("#q").value.trim()), df = $("#df").value, so = $("#so").value;
      let n = 0;
      $$(".card", pl).forEach((c, i) => {
        const ok = c.dataset.iso >= (df || today) && (!q || c.dataset.q.indexOf(q) > -1);
        c.hidden = !ok; if (ok) n++;
        c.style.order = so === "desc" ? String(-i) : "0";
      });
      $("#pn").textContent = n ? "Nalezeno akcí: " + n : "";
      $("#pe").hidden = n > 0;
    };
    ["q", "df", "so"].forEach((id) => $("#" + id).addEventListener("input", run));
    run();
  }

  /* ---- kalendář ---- */
  const root = $("[data-cal-root]"), dataEl = $("#cal-data");
  if (root && dataEl) {
    const evs = JSON.parse(dataEl.textContent), cat = root.dataset.cat, base = root.dataset.base || "", editMode = root.dataset.editMode === "1";
    const MN = ["Leden", "Únor", "Březen", "Duben", "Květen", "Červen", "Červenec", "Srpen", "Září", "Říjen", "Listopad", "Prosinec"];
    const WD = ["neděle", "pondělí", "úterý", "středa", "čtvrtek", "pátek", "sobota"];
    const MO = ["led", "úno", "bře", "dub", "kvě", "čvn", "čvc", "srp", "zář", "říj", "lis", "pro"];
    const fl = evs.filter((e) => !cat || e.c === cat);
    const srt = (a) => a.slice().sort((x, y) => (x.iso + x.t).localeCompare(y.iso + y.t));
    let sd, cy, cm;
    const go = (iso) => { sd = iso; cy = +iso.slice(0, 4); cm = +iso.slice(5, 7) - 1; };
    const pd = new URLSearchParams(location.search).get("d");
    const first = srt(fl.filter((e) => e.iso >= today))[0];
    go(/^\d{4}-\d{2}-\d{2}$/.test(pd || "") ? pd : first ? first.iso : today);
    const tkb = (e, l) => e.av === "sold" ? `<span class="b sold">Vyprodáno</span>` : e.av === "soon" ? `<span class="b sold">Prodej připravujeme</span>` : `<a class="b p" href="${esc(e.tk)}">${l} <span>→</span></a>`;
    const cal = () => {
      const first = (new Date(cy, cm, 1).getDay() + 6) % 7, len = new Date(cy, cm + 1, 0).getDate(), by = {};
      fl.forEach((e) => (by[e.iso] = (by[e.iso] || 0) + 1));
      let h = ["Po", "Út", "St", "Čt", "Pá", "So", "Ne"].map((d) => `<div class="wd">${d}</div>`).join("") + '<div class="c"></div>'.repeat(first);
      for (let d = 1; d <= len; d++) {
        const iso = `${cy}-${String(cm + 1).padStart(2, "0")}-${String(d).padStart(2, "0")}`, n = by[iso] || 0;
        const cl = "c" + (n ? " on" : "") + (iso === today ? " td" : "") + (iso === sd ? " sel" : "");
        h += n || editMode ? `<button class="${cl}" data-sd="${iso}" aria-label="${d}. ${MN[cm]}${n ? ", akcí: " + n : ""}">${d}${n ? `<em>${"■".repeat(Math.min(n, 4))}</em>` : ""}</button>` : `<div class="${cl}">${d}</div>`;
      }
      $("#cal").innerHTML = h; $("#mn").textContent = MN[cm] + " " + cy; day();
    };
    const day = () => {
      const dt = new Date(sd + "T12:00"), L = srt(fl.filter((e) => e.iso === sd));
      $("#day").innerHTML = `<div class="m">${WD[dt.getDay()]} ${dt.getDate()}. ${MO[dt.getMonth()]}. ${dt.getFullYear()}</div>` +
        (L.length ? L.map((e) => `<div class="di"><div class="m">${esc(e.t)} · ${esc(e.c)}</div><b>${esc(e.title)}</b><div class="row">${tkb(e, "Vstupenky")}<a class="b" href="${esc(base)}/akce/${esc(e.id)}">Více informací <span>→</span></a></div></div>`).join("") : '<p class="m">Žádná akce.</p>') +
        (editMode ? `<div class="row"><a class="b p" href="#" data-edit="/admin/edit/akce/new?iso=${sd}">+ Přidat akci</a></div>` : "");
    };
    root.addEventListener("click", (e) => {
      const t = e.target.closest("[data-sd]"); if (t) { sd = t.dataset.sd; cal(); return; }
      if (e.target.closest("#pv")) { cm--; if (cm < 0) { cm = 11; cy--; } cal(); }
      else if (e.target.closest("#nx")) { cm++; if (cm > 11) { cm = 0; cy++; } cal(); }
    });
    cal();
  }

  /* ---- fotogalerie: zvětšení, šipky, klávesnice ---- */
  const lb = $("#lb");
  const shots = $$("[data-lb]");
  let li = 0;
  const lbClose = () => { lb.hidden = true; lb.innerHTML = ""; };
  const lbShow = (i) => {
    const n = shots.length; if (!n) return; li = (i + n) % n;
    const im = shots[li].querySelector("img");
    lb.innerHTML = `<button class="lbx b" data-lbc aria-label="Zavřít">✕</button><button class="lbn l b" data-lbn="-1" aria-label="Předchozí fotografie">←</button><img src="${esc(shots[li].dataset.src)}" alt="${esc(im ? im.alt : "")}"><button class="lbn r b" data-lbn="1" aria-label="Další fotografie">→</button><span class="m lbc">${li + 1} / ${n}</span>`;
    lb.hidden = false; $("[data-lbc]", lb).focus();
  };
  shots.forEach((b, i) => b.addEventListener("click", () => lbShow(i)));
  if (lb) {
    lb.addEventListener("click", (e) => { if (e.target === lb || e.target.closest("[data-lbc]")) lbClose(); else { const n = e.target.closest("[data-lbn]"); if (n) lbShow(li + Number(n.dataset.lbn)); } });
    addEventListener("keydown", (e) => { if (lb.hidden) return; if (e.key === "Escape") lbClose(); else if (e.key === "ArrowLeft") lbShow(li - 1); else if (e.key === "ArrowRight") lbShow(li + 1); });
  }

  /* ---- sdílení ---- */
  const toast = (s) => { const d = document.createElement("div"); d.className = "ts m"; d.textContent = s; d.setAttribute("role", "status"); document.body.appendChild(d); setTimeout(() => d.remove(), 2600); };
  $$("[data-share]").forEach((b) => b.addEventListener("click", () => {
    const url = location.origin + location.pathname, title = document.title;
    if (navigator.share) navigator.share({ title, url }).catch(() => {});
    else if (navigator.clipboard) navigator.clipboard.writeText(url).then(() => toast("Odkaz zkopírován"), () => toast(url));
    else toast(url);
  }));

  /* ---- cookies a měření návštěvnosti (až po souhlasu) ---- */
  const getCC = () => { try { return localStorage.getItem("mk_cc"); } catch (e) { return null; } };
  const setCC = (v) => { try { v ? localStorage.setItem("mk_cc", v) : localStorage.removeItem("mk_cc"); } catch (e) {} };
  const analytics = () => {
    const id = cfg.ga;
    if (!id || !/^G-[A-Z0-9]+$/i.test(id) || getCC() !== "all" || window.gtag) return;
    const s = document.createElement("script"); s.async = true; s.src = "https://www.googletagmanager.com/gtag/js?id=" + id; document.head.appendChild(s);
    window.dataLayer = window.dataLayer || []; window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag("js", new Date()); window.gtag("config", id, { anonymize_ip: true });
  };
  const cc = $("#cc"); if (cc) cc.hidden = getCC() !== null;
  document.addEventListener("click", (e) => {
    const t = e.target.closest("[data-cc]"); if (!t) return;
    if (t.dataset.cc === "reset") { setCC(null); if (cc) cc.hidden = false; } else { setCC(t.dataset.cc); if (cc) cc.hidden = true; analytics(); }
  });
  analytics();

  /* ---- formuláře (kontakt, poptávka): ukládají se do databáze ---- */
  const t0 = Date.now();
  const EM = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
  const pre = $("#pre"); const sel = $("[name=type]"); if (pre && sel) $$("option", sel).forEach((o) => { if (o.text === pre.textContent.trim()) sel.value = o.value; });
  $$("form[data-kind]").forEach((f) => f.addEventListener("submit", async (e) => {
    e.preventDefault();
    const d = Object.fromEntries(new FormData(f)), err = $(".fe", f), btn = $("button[type=submit]", f);
    if (d.web || Date.now() - t0 < 2500) { err.textContent = "Odeslání se nepodařilo. Zkuste to prosím znovu."; return; }
    const bad = [];
    if (!String(d.name || "").trim()) bad.push("jméno");
    if (!EM.test(String(d.email || "").trim())) bad.push("platný e-mail");
    if (f.dataset.kind === "rental" && !d.type) bad.push("typ prostoru");
    if (!String(d.message || "").trim()) bad.push("zprávu");
    if (d.count && Number(d.count) < 1) bad.push("počet účastníků (číslo od 1)");
    if (bad.length) { err.textContent = "Vyplňte prosím: " + bad.join(", ") + "."; return; }
    err.textContent = ""; btn.disabled = true; btn.textContent = "Odesílám…";
    try {
      const r = await fetch("/api/inquiry", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ kind: f.dataset.kind, name: d.name, email: d.email, phone: d.phone || "", space: d.type || "", eventDate: d.date || "", headcount: d.count || "", message: d.message, web: d.web || "" }) });
      const j = await r.json().catch(() => ({}));
      if (!r.ok) throw new Error(j.error || "Zprávu se nepodařilo odeslat.");
      f.outerHTML = '<div class="fm ok" role="status" style="max-width:640px"><b>Děkujeme, zpráva byla odeslána.</b><p>Ozveme se vám co nejdříve na zadaný e-mail.</p></div>';
    } catch (x) { err.textContent = x.message || "Zprávu se nepodařilo odeslat. Zkuste to prosím později."; btn.disabled = false; btn.textContent = "Odeslat"; }
  }));
})();
