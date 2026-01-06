(function () {
  const menuButton = document.querySelector("[data-menu]");
  const links = document.querySelector("[data-links]");
  if (!menuButton || !links) return;

  menuButton.addEventListener("click", () => {
    links.classList.toggle("open");
    const expanded = links.classList.contains("open");
    menuButton.setAttribute("aria-expanded", String(expanded));
  });

  window.addEventListener("resize", () => {
    if (window.innerWidth > 760) {
      links.classList.remove("open");
      menuButton.setAttribute("aria-expanded", "false");
    }
  });
})();

// Theme Toggle (Dark/Light Mode)
(function () {
  const THEME_KEY = 'in-institution-theme';

  // Apply theme immediately (before DOM ready to prevent flash)
  function getPreferredTheme() {
    const stored = localStorage.getItem(THEME_KEY);
    if (stored) return stored;
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function applyTheme(theme) {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }

  // Apply immediately
  applyTheme(getPreferredTheme());

  // Setup toggle button after DOM loads
  document.addEventListener('DOMContentLoaded', function () {
    const toggleBtn = document.getElementById('themeToggle');
    if (!toggleBtn) return;

    toggleBtn.addEventListener('click', function () {
      const isDark = document.documentElement.classList.contains('dark');
      const newTheme = isDark ? 'light' : 'dark';
      localStorage.setItem(THEME_KEY, newTheme);
      applyTheme(newTheme);
    });
  });

  // Listen for system preference changes
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem(THEME_KEY)) {
      applyTheme(e.matches ? 'dark' : 'light');
    }
  });
})();

// Language Switcher
document.addEventListener('DOMContentLoaded', function () {
  const LANG_KEY = 'in-institution-lang';
  const langSwitcher = document.getElementById('langSwitcher');
  const langBtn = document.getElementById('langBtn');
  const langDropdown = document.getElementById('langDropdown');

  if (!langSwitcher || !langBtn || !langDropdown) {
    console.log('Language switcher elements not found');
    return;
  }

  const langLabels = { en: 'EN', fr: 'FR', ar: 'AR' };
  const langOptions = langDropdown.querySelectorAll('.lang-option');

  // Apply saved language
  const savedLang = localStorage.getItem(LANG_KEY) || 'en';
  updateLangDisplay(savedLang);

  // Toggle dropdown on click
  langBtn.addEventListener('click', function (e) {
    e.preventDefault();
    e.stopPropagation();
    const isOpen = langSwitcher.classList.toggle('open');
    langBtn.setAttribute('aria-expanded', String(isOpen));
    console.log('Language dropdown toggled:', isOpen);
  });

  // Handle language selection
  langOptions.forEach(option => {
    option.addEventListener('click', function (e) {
      e.preventDefault();
      e.stopPropagation();
      const lang = this.dataset.lang;
      localStorage.setItem(LANG_KEY, lang);
      updateLangDisplay(lang);
      langSwitcher.classList.remove('open');
      langBtn.setAttribute('aria-expanded', 'false');

      // Update active state
      langOptions.forEach(opt => opt.classList.remove('active'));
      this.classList.add('active');
    });
  });

  // Close on outside click
  document.addEventListener('click', function (e) {
    if (!langSwitcher.contains(e.target)) {
      langSwitcher.classList.remove('open');
      langBtn.setAttribute('aria-expanded', 'false');
    }
  });

  function updateLangDisplay(lang) {
    const currentLangEl = langBtn.querySelector('.current-lang');
    if (currentLangEl) {
      currentLangEl.textContent = langLabels[lang] || 'EN';
    }
    // Set active state on correct option
    langOptions.forEach(opt => {
      opt.classList.toggle('active', opt.dataset.lang === lang);
    });
  }

  console.log('Language switcher initialized');
});


// Stories Carousel
document.addEventListener('DOMContentLoaded', function () {
  const track = document.getElementById('storyTrack');
  const prevBtn = document.getElementById('prevStory');
  const nextBtn = document.getElementById('nextStory');
  const dotsContainer = document.getElementById('storyDots');

  if (!track || !prevBtn || !nextBtn || !dotsContainer) return;

  const slides = track.querySelectorAll('.story-slide');
  const dots = dotsContainer.querySelectorAll('.dot');
  let currentIndex = 0;
  let startX = 0;
  let isDragging = false;
  let autoPlayInterval = null;

  function updateCarousel() {
    track.style.transform = `translateX(-${currentIndex * 100}%)`;

    // Update dots
    dots.forEach((dot, i) => {
      dot.classList.toggle('active', i === currentIndex);
    });
  }

  function goToSlide(index) {
    currentIndex = Math.max(0, Math.min(index, slides.length - 1));
    updateCarousel();
  }

  function nextSlide() {
    currentIndex = (currentIndex + 1) % slides.length;
    updateCarousel();
  }

  function prevSlide() {
    currentIndex = (currentIndex - 1 + slides.length) % slides.length;
    updateCarousel();
  }

  // Button handlers
  nextBtn.addEventListener('click', function () {
    nextSlide();
    resetAutoPlay();
  });

  prevBtn.addEventListener('click', function () {
    prevSlide();
    resetAutoPlay();
  });

  // Dot handlers
  dots.forEach((dot) => {
    dot.addEventListener('click', () => {
      const slideIndex = parseInt(dot.dataset.slide, 10);
      goToSlide(slideIndex);
      resetAutoPlay();
    });
  });

  // Touch/Swipe support
  track.addEventListener('touchstart', (e) => {
    startX = e.touches[0].clientX;
    isDragging = true;
    pauseAutoPlay();
  }, { passive: true });

  track.addEventListener('touchmove', (e) => {
    if (!isDragging) return;
  }, { passive: true });

  track.addEventListener('touchend', (e) => {
    if (!isDragging) return;
    const endX = e.changedTouches[0].clientX;
    const diff = startX - endX;

    if (Math.abs(diff) > 50) {
      if (diff > 0) {
        nextSlide();
      } else {
        prevSlide();
      }
    }

    isDragging = false;
    resetAutoPlay();
  });

  // Mouse drag support
  track.addEventListener('mousedown', (e) => {
    startX = e.clientX;
    isDragging = true;
    track.style.cursor = 'grabbing';
    pauseAutoPlay();
  });

  track.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
  });

  track.addEventListener('mouseup', (e) => {
    if (!isDragging) return;
    const diff = startX - e.clientX;

    if (Math.abs(diff) > 50) {
      if (diff > 0) {
        nextSlide();
      } else {
        prevSlide();
      }
    }

    isDragging = false;
    track.style.cursor = 'grab';
    resetAutoPlay();
  });

  track.addEventListener('mouseleave', () => {
    isDragging = false;
    track.style.cursor = 'grab';
  });

  // Auto-play functions
  function startAutoPlay() {
    if (autoPlayInterval) clearInterval(autoPlayInterval);
    autoPlayInterval = setInterval(nextSlide, 4000);
  }

  function pauseAutoPlay() {
    if (autoPlayInterval) {
      clearInterval(autoPlayInterval);
      autoPlayInterval = null;
    }
  }

  function resetAutoPlay() {
    pauseAutoPlay();
    startAutoPlay();
  }

  // Pause on hover
  const carouselContainer = document.getElementById('storiesCarousel');
  if (carouselContainer) {
    carouselContainer.addEventListener('mouseenter', pauseAutoPlay);
    carouselContainer.addEventListener('mouseleave', startAutoPlay);
  }

  // Initialize: Start auto-play immediately
  startAutoPlay();
  console.log('Carousel initialized with', slides.length, 'slides');
});

// Android Smart App Banner
(function () {
  const BANNER_DISMISSED_KEY = 'in-institution-android-banner-dismissed';

  // Check if user is on Android (not iOS, not desktop)
  function isAndroid() {
    const ua = navigator.userAgent || navigator.vendor || window.opera;
    // Check for Android but NOT iOS devices
    return /android/i.test(ua) && !/iPhone|iPad|iPod/i.test(ua);
  }

  // Check if banner was already dismissed this session
  function wasDismissed() {
    return sessionStorage.getItem(BANNER_DISMISSED_KEY) === 'true';
  }

  // Mark banner as dismissed
  function dismissBanner() {
    sessionStorage.setItem(BANNER_DISMISSED_KEY, 'true');
  }

  // Show the banner
  function showBanner() {
    const banner = document.getElementById('androidAppBanner');
    if (banner) {
      banner.style.display = 'flex';
      // Prevent body scroll when banner is open
      document.body.style.overflow = 'hidden';
    }
  }

  // Hide the banner
  function hideBanner() {
    const banner = document.getElementById('androidAppBanner');
    if (banner) {
      banner.style.display = 'none';
      document.body.style.overflow = '';
    }
    dismissBanner();
  }

  // Initialize on DOM ready
  document.addEventListener('DOMContentLoaded', function () {
    const banner = document.getElementById('androidAppBanner');
    const closeBtn = document.getElementById('closeBanner');
    const skipBtn = document.getElementById('skipBanner');
    const overlay = document.getElementById('bannerOverlay');

    if (!banner) return;

    // Only show for Android users who haven't dismissed
    if (isAndroid() && !wasDismissed()) {
      showBanner();
    }

    // Close button handler
    if (closeBtn) {
      closeBtn.addEventListener('click', hideBanner);
    }

    // Skip/Continue button handler
    if (skipBtn) {
      skipBtn.addEventListener('click', hideBanner);
    }

    // Clicking overlay also closes (optional UX improvement)
    if (overlay) {
      overlay.addEventListener('click', hideBanner);
    }
  });

  console.log('Android banner module loaded, isAndroid:', isAndroid());
})();

