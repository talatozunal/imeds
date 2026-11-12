/* =========================================================
   imeds — site betiği
   - İki dilli arayüz (Türkçe, İngilizce)
   - Mobil menü, dil menüsü, kaydırma efektleri, SSS akordeonu
   ========================================================= */

(function () {
  "use strict";

  var I18N = {
    tr: {
      "meta.title": "imeds — Telefonunuzdan Apple TV'ye, internetsiz aktarım",
      "meta.description": "iPhone veya iPad'den Apple TV'ye fotoğraf, video, müzik ve dosya gönderin. Aynı yerel ağ yeterli; hesap, bulut ve internet gerekmez.",
      "a11y.skip": "İçeriğe geç",
      "nav.features": "Özellikler",
      "nav.screens": "Ekranlar",
      "nav.privacy": "Gizlilik",
      "nav.faq": "S.S.S.",
      "nav.cta": "GitHub",
      "hero.badge": "Yerel ağ · İnternetsiz",
      "hero.title": "Telefonunuzdan Apple TV'ye,",
      "hero.titleAccent": "kablosuz ve çevrimdışı.",
      "hero.lead": "Fotoğraf, video, müzik ve dosyaları aynı Wi-Fi ağındaki Apple TV'ye doğrudan gönderin. Sunucu, bulut veya hesap yok; aktarım şifreli bir cihazdan cihaza oturumda gerçekleşir.",
      "hero.cta1": "Kaynak kodu gör",
      "hero.cta2": "Özellikleri gör",
      "hero.chip1": "İnternetsiz",
      "hero.chip2": "Şifreli oturum",
      "hero.chip3": "Sıfır bağımlılık",
      "hero.note": "iOS 17+ · tvOS 17+ · iPhone, iPad ve Apple TV",
      "float.group": "Şifreli oturum",
      "float.groupSub": "MCSession · zorunlu şifreleme",
      "float.badge": "Canlı hız",
      "float.badgeSub": "Yüzde ve boyut",
      "float.lang": "5 dil",
      "stats.1": "uygulama",
      "stats.2": "sunucu",
      "stats.3": "bağımlılık",
      "stats.4": "dil",
      "stats.5": "medya türü",
      "features.eyebrow": "Özellikler",
      "features.title": "Doğrudan aktarım için her şey",
      "features.lead": "İki uygulama, tek yerel ağ; arada bulut yok.",
      "f1.title": "İnternetsiz Aktarım",
      "f1.text": "Aynı Wi-Fi ağı veya yakın Bluetooth yeterli; internet bağlantısı gerekmez.",
      "f2.title": "Şifreli Oturum",
      "f2.text": "Aktarım, encryptionPreference: .required ile kurulan bir MCSession üzerinden yapılır.",
      "f3.title": "Her Türlü Dosya",
      "f3.text": "Sistem fotoğraf/video seçicisi veya Files uygulamasından her tür dosyayı gönderin.",
      "f4.title": "Canlı İlerleme ve İptal",
      "f4.text": "Yüzde, aktarılan/toplam boyut ve anlık MB/sn; aktarım iki taraftan da iptal edilebilir.",
      "f5.title": "Kalıcı Arşiv",
      "f5.text": "Alınan dosyalar Documents/Received altında kalır, Files'ta görünür; fotoğraf ve videolar isteğe bağlı galeriye eklenir.",
      "f6.title": "Apple TV'de Oynatma",
      "f6.text": "Görsel, video ve ses için ayrı arayüzler; Geri tuşu uygulamadan çıkarmaz, son medya altta kalır.",
      "apps.eyebrow": "İki uygulama",
      "apps.title": "Bir gönderici, bir alıcı",
      "apps.lead": "Telefona imeds'i, Apple TV'ye imedtv'yi kurun.",
      "app1.platform": "iOS 17+ · iPhone ve iPad",
      "app1.text": "Gönderici arayüzü: cihazları bulur, dosya seçer ve canlı ilerlemeyle gönderir.",
      "app2.platform": "tvOS 17+ · Apple TV",
      "app2.text": "Alıcı ve oynatıcı: gelen dosyayı arşivler, görsel/video/ses olarak oynatır.",
      "screens.eyebrow": "Ekranlar",
      "screens.title": "İki cihaz, tek akış",
      "screens.lead": "Telefonda seçin, televizyonda izleyin.",
      "group1": "iPhone · gönderim",
      "group2": "Apple TV · oynatma",
      "s1": "Gönderim ekranı",
      "s2": "Ses oynatma",
      "s3": "Video oynatma",
      "s4": "Son medya şeridi",
      "how.eyebrow": "Nasıl çalışır",
      "how.title": "Üç adımda oynatma",
      "how.1t": "Aynı ağa bağlanın",
      "how.1d": "İki cihazı aynı Wi-Fi ağına alın ve ilk açılışta Yerel Ağ iznini verin.",
      "how.2t": "Apple TV'yi seçin",
      "how.2d": "Uygulamalar aynı anda yayın yapar ve tarar; şifreli oturum kendiliğinden kurulur.",
      "how.3t": "Gönderin ve oynatın",
      "how.3d": "İlerleme yüzdesini ve hızı izleyin. İş bitince Apple TV ana ekranda kalır, son medya altta durur.",
      "privacy.eyebrow": "Gizlilik",
      "privacy.title": "İnternet yok, hesap yok, bulut yok.",
      "privacy.lead": "Aktarım doğrudan iki cihaz arasında gerçekleşir; hiçbir veri dışarıya gönderilmez.",
      "privacy.1": "Sunucu, bulut, hesap, analitik veya reklam SDK'sı yok.",
      "privacy.2": "Oturum MCSession'ın zorunlu şifrelemesiyle korunur; Bonjour yalnızca yerel ağda keşif yapar.",
      "privacy.3": "Alınan dosyalar cihazda Documents/Received altında kalır; galeriye kayıt yalnızca siz isterseniz yapılır.",
      "privacy.link": "Kaynak kodunu inceleyin",
      "privacy.badge": "Sunucu yok",
      "faq.eyebrow": "S.S.S.",
      "faq.title": "Sık sorulan sorular",
      "faq.1q": "İnternet bağlantısı gerekiyor mu?",
      "faq.1a": "Hayır. Cihazların aynı Wi-Fi ağında olması veya Bluetooth menzilinde bulunması yeterli.",
      "faq.2q": "Hangi cihazlar destekleniyor?",
      "faq.2a": "iOS 17+ iPhone ve iPad (imeds) ile tvOS 17+ Apple TV (imedtv).",
      "faq.3q": "Hangi dosyaları gönderebilirim?",
      "faq.3a": "Sistem seçicisinden fotoğraf ve video, Files'tan her tür dosya. Apple TV görsel, video ve ses dosyalarını oynatır; diğerlerini simge ve adıyla gösterir.",
      "faq.4q": "Apple TV'de video oynamıyor, neden?",
      "faq.4a": "Oynatma dosyanın codec desteğine bağlıdır. .avi ve .mkv tanınsa bile DivX/Xvid gibi codec'ler AVFoundation tarafından çalınamaz; uygulama nedeni ekranda yazar.",
      "faq.5q": "Alınan dosyalar nerede?",
      "faq.5a": "Documents/Received altında saklanır ve Files uygulamasından erişilebilir. Fotoğraf ve videoları isterseniz galeriye de ekleyebilirsiniz.",
      "faq.6q": "Ücretli mi?",
      "faq.6a": "Hayır. Proje açık kaynak ve geliştirme aşamasında; App Store sürümü henüz yayınlanmadı.",
      "dl.title": "Kaynak kodu GitHub'da",
      "dl.lead": "Xcode 16 ile imeds ve imedtv hedeflerini derleyin.",
      "dl.github": "GitHub'da görüntüle",
      "dl.docs": "Kullanım kılavuzu",
      "dl.note": "Proje geliştirme aşamasındadır; App Store sürümü henüz yayınlanmadı.",
      "footer.tagline": "İki Apple cihazı arasında, internetsiz ve şifreli dosya aktarımı.",
      "footer.by": "Talat Özünal"
    },
    en: {
      "meta.title": "imeds — Phone to Apple TV, no internet required",
      "meta.description": "Send photos, videos, music and files from iPhone or iPad to Apple TV. The same local network is enough; no account, cloud or internet.",
      "a11y.skip": "Skip to content",
      "nav.features": "Features",
      "nav.screens": "Screens",
      "nav.privacy": "Privacy",
      "nav.faq": "FAQ",
      "nav.cta": "GitHub",
      "hero.badge": "Local network · No internet",
      "hero.title": "From your phone to Apple TV,",
      "hero.titleAccent": "wireless and offline.",
      "hero.lead": "Send photos, videos, music and files straight to an Apple TV on the same Wi-Fi network. No server, cloud or account; transfers run in an encrypted device-to-device session.",
      "hero.cta1": "View source code",
      "hero.cta2": "See features",
      "hero.chip1": "No internet",
      "hero.chip2": "Encrypted session",
      "hero.chip3": "Zero dependencies",
      "hero.note": "iOS 17+ · tvOS 17+ · iPhone, iPad and Apple TV",
      "float.group": "Encrypted session",
      "float.groupSub": "MCSession · encryption required",
      "float.badge": "Live speed",
      "float.badgeSub": "Percentage and size",
      "float.lang": "5 languages",
      "stats.1": "apps",
      "stats.2": "servers",
      "stats.3": "dependencies",
      "stats.4": "languages",
      "stats.5": "media types",
      "features.eyebrow": "Features",
      "features.title": "Everything for a direct transfer",
      "features.lead": "Two apps, one local network; no cloud in between.",
      "f1.title": "No Internet",
      "f1.text": "The same Wi-Fi network or nearby Bluetooth is enough; no internet connection needed.",
      "f2.title": "Encrypted Session",
      "f2.text": "Transfers run over an MCSession created with encryptionPreference: .required.",
      "f3.title": "Any File Type",
      "f3.text": "Send photos and videos with the system picker, or any file from the Files app.",
      "f4.title": "Live Progress and Cancel",
      "f4.text": "Percentage, transferred/total size and live MB/s; either side can cancel.",
      "f5.title": "Persistent Archive",
      "f5.text": "Received files stay in Documents/Received, visible in Files; photos and videos can optionally be added to Photos.",
      "f6.title": "Apple TV Playback",
      "f6.text": "Dedicated interfaces for images, video and audio; Back does not quit, the last media stays below.",
      "apps.eyebrow": "Two apps",
      "apps.title": "One sender, one receiver",
      "apps.lead": "Install imeds on the phone and imedtv on the Apple TV.",
      "app1.platform": "iOS 17+ · iPhone and iPad",
      "app1.text": "Sender UI: discovers devices, picks files and sends them with live progress.",
      "app2.platform": "tvOS 17+ · Apple TV",
      "app2.text": "Receiver and player: archives incoming files and plays images, video and audio.",
      "screens.eyebrow": "Screens",
      "screens.title": "Two devices, one flow",
      "screens.lead": "Pick on the phone, watch on the TV.",
      "group1": "iPhone · sending",
      "group2": "Apple TV · playback",
      "s1": "Sender screen",
      "s2": "Audio playback",
      "s3": "Video playback",
      "s4": "Last media bar",
      "how.eyebrow": "How it works",
      "how.title": "Three steps to play",
      "how.1t": "Join the same network",
      "how.1d": "Put both devices on the same Wi-Fi network and allow Local Network access on first launch.",
      "how.2t": "Pick the Apple TV",
      "how.2d": "Both apps advertise and browse at once; the encrypted session forms automatically.",
      "how.3t": "Send and play",
      "how.3d": "Watch the percentage and speed. When it finishes, Apple TV stays on its main screen with the last media pinned below.",
      "privacy.eyebrow": "Privacy",
      "privacy.title": "No internet, no account, no cloud.",
      "privacy.lead": "Transfers happen directly between the two devices; no data is sent anywhere else.",
      "privacy.1": "No server, cloud, account, analytics or ad SDK.",
      "privacy.2": "The session is protected by MCSession's required encryption; Bonjour only discovers devices on the local network.",
      "privacy.3": "Received files stay on device under Documents/Received; saving to Photos only happens if you ask for it.",
      "privacy.link": "Explore the source code",
      "privacy.badge": "No server",
      "faq.eyebrow": "FAQ",
      "faq.title": "Frequently asked questions",
      "faq.1q": "Does it need an internet connection?",
      "faq.1a": "No. The devices only need to be on the same Wi-Fi network or within Bluetooth range.",
      "faq.2q": "Which devices are supported?",
      "faq.2a": "iOS 17+ iPhone and iPad (imeds) and tvOS 17+ Apple TV (imedtv).",
      "faq.3q": "Which files can I send?",
      "faq.3a": "Photos and videos from the system picker, and any file from the Files app. Apple TV plays images, video and audio; other files are shown with an icon and name.",
      "faq.4q": "Why won't a video play on Apple TV?",
      "faq.4a": "Playback depends on codec support. Even when .avi and .mkv containers are recognised, codecs such as DivX/Xvid cannot be played by AVFoundation; the app shows the reason on screen.",
      "faq.5q": "Where are received files stored?",
      "faq.5a": "Under Documents/Received, accessible from the Files app. You can also add photos and videos to Photos if you want.",
      "faq.6q": "Is it paid?",
      "faq.6a": "No. The project is open source and in development; the App Store version has not been released yet.",
      "dl.title": "Source code on GitHub",
      "dl.lead": "Build the imeds and imedtv targets with Xcode 16.",
      "dl.github": "View on GitHub",
      "dl.docs": "User guide",
      "dl.note": "The project is in development; the App Store version has not been released yet.",
      "footer.tagline": "Encrypted, internet-free file transfer between two Apple devices.",
      "footer.by": "Talat Özünal"
    }
  };

  var STORAGE_KEY = "imeds.lang";
  var DEFAULT_LANG = "tr";
  var SUPPORTED = ["tr", "en"];
  var CODES = { tr: "TR", en: "EN" };

  var root = document.documentElement;
  var langBox = document.getElementById("lang");
  var langButton = document.getElementById("langButton");
  var langMenu = document.getElementById("langMenu");
  var langCode = document.getElementById("langCode");
  var burger = document.getElementById("burger");
  var nav = document.getElementById("nav");
  var header = document.getElementById("header");

  function normalize(code) {
    if (!code) return null;
    var base = String(code).toLowerCase().split("-")[0];
    return SUPPORTED.indexOf(base) >= 0 ? base : null;
  }

  function storedLang() {
    try { return normalize(localStorage.getItem(STORAGE_KEY)); } catch (e) { return null; }
  }

  function browserLang() {
    var list = navigator.languages || [navigator.language || ""];
    for (var i = 0; i < list.length; i++) {
      var found = normalize(list[i]);
      if (found) return found;
    }
    return null;
  }

  function translate(code) {
    var dict = I18N[code] || I18N[DEFAULT_LANG];
    var nodes = document.querySelectorAll("[data-i18n]");
    for (var i = 0; i < nodes.length; i++) {
      var key = nodes[i].getAttribute("data-i18n");
      if (Object.prototype.hasOwnProperty.call(dict, key)) {
        nodes[i].textContent = dict[key];
      }
    }
    document.title = dict["meta.title"] || document.title;
    var desc = document.querySelector('meta[name="description"]');
    if (desc && dict["meta.description"]) desc.setAttribute("content", dict["meta.description"]);
    root.setAttribute("lang", code);
    if (langCode) langCode.textContent = CODES[code] || code.toUpperCase();

    var items = document.querySelectorAll(".lang__item");
    for (var j = 0; j < items.length; j++) {
      var active = items[j].getAttribute("data-lang") === code;
      items[j].classList.toggle("is-active", active);
      items[j].setAttribute("aria-current", active ? "true" : "false");
    }
  }

  function setLang(code, remember) {
    var safe = SUPPORTED.indexOf(code) >= 0 ? code : DEFAULT_LANG;
    translate(safe);
    if (remember) {
      try { localStorage.setItem(STORAGE_KEY, safe); } catch (e) { /* yoksay */ }
    }
  }

  /* --- dil menüsü --- */
  function openLang(open) {
    if (!langBox || !langButton) return;
    langBox.classList.toggle("is-open", open);
    langButton.setAttribute("aria-expanded", open ? "true" : "false");
  }

  if (langButton) {
    langButton.addEventListener("click", function (event) {
      event.stopPropagation();
      openLang(!langBox.classList.contains("is-open"));
    });
  }

  if (langMenu) {
    langMenu.addEventListener("click", function (event) {
      var button = event.target.closest(".lang__item");
      if (!button) return;
      setLang(button.getAttribute("data-lang"), true);
      openLang(false);
      if (langButton) langButton.focus();
    });
  }

  document.addEventListener("click", function (event) {
    if (langBox && !langBox.contains(event.target)) openLang(false);
  });

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
      openLang(false);
      closeNav();
    }
  });

  /* --- mobil menü --- */
  function closeNav() {
    if (!nav || !burger) return;
    nav.classList.remove("is-open");
    burger.setAttribute("aria-expanded", "false");
  }

  if (burger) {
    burger.addEventListener("click", function () {
      var open = !nav.classList.contains("is-open");
      nav.classList.toggle("is-open", open);
      burger.setAttribute("aria-expanded", open ? "true" : "false");
    });
  }

  if (nav) {
    nav.addEventListener("click", function (event) {
      if (event.target.closest("a")) closeNav();
    });
  }

  /* --- kaydırma durumu --- */
  function onScroll() {
    if (!header) return;
    header.classList.toggle("is-scrolled", window.scrollY > 8);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* --- görünürlük animasyonu --- */
  var revealItems = document.querySelectorAll("[data-reveal]");
  if ("IntersectionObserver" in window) {
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-in");
          observer.unobserve(entry.target);
        }
      });
    }, { rootMargin: "0px 0px -8% 0px", threshold: 0.08 });

    for (var r = 0; r < revealItems.length; r++) {
      revealItems[r].classList.add("will-reveal");
      observer.observe(revealItems[r]);
    }
  } else {
    for (var s = 0; s < revealItems.length; s++) revealItems[s].classList.add("is-in");
  }

  /* --- SSS: aynı anda tek soru açık kalsın --- */
  var faqItems = document.querySelectorAll(".faq__item");
  for (var f = 0; f < faqItems.length; f++) {
    faqItems[f].addEventListener("toggle", function () {
      if (!this.open) return;
      for (var k = 0; k < faqItems.length; k++) {
        if (faqItems[k] !== this) faqItems[k].open = false;
      }
    });
  }

  /* --- başlangıç dili --- */
  var initial = storedLang() || DEFAULT_LANG;
  setLang(initial, false);
  if (!storedLang()) {
    var detected = browserLang();
    if (detected && detected !== DEFAULT_LANG) setLang(detected, false);
  }
})();
