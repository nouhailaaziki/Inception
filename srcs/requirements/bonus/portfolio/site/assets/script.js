(function () {
  "use strict";

  document.documentElement.classList.add("js");

  // ---------- dynamic year ----------
  var yearEl = document.getElementById("year");
  if (yearEl) {
    yearEl.textContent = String(new Date().getFullYear());
  }

  // ---------- active nav section ----------
  var navLinks = Array.prototype.slice.call(
    document.querySelectorAll("[data-nav]")
  );

  var sections = navLinks
    .map(function (link) {
      var id = link.getAttribute("href");

      if (!id || id.charAt(0) !== "#") {
        return null;
      }

      var el = document.querySelector(id);

      return el ? { link: link, el: el } : null;
    })
    .filter(Boolean);

  var activeLink = null;
  var clickedTarget = null;

  var setActive = function (link) {
    if (activeLink === link) {
      return;
    }

    navLinks.forEach(function (l) {
      l.classList.remove("is-active");
      l.removeAttribute("aria-current");
    });

    if (link) {
      link.classList.add("is-active");
      link.setAttribute("aria-current", "true");
      activeLink = link;
    } else {
      activeLink = null;
    }
  };

  var getCurrentSection = function () {
    var scrollPosition = window.scrollY + 140;
    var current = sections[0];

    sections.forEach(function (section) {
      var sectionTop =
        section.el.getBoundingClientRect().top + window.scrollY;

      if (sectionTop <= scrollPosition) {
        current = section;
      }
    });

    return current;
  };

  if (sections.length) {
    // Set the clicked item immediately.
    navLinks.forEach(function (link) {
      link.addEventListener("click", function () {
        var id = link.getAttribute("href");

        var target = sections.find(function (section) {
          return section.el.id === id.substring(1);
        });

        if (!target) {
          return;
        }

        clickedTarget = target;
        setActive(target.link);

        // Release the click lock after the smooth scroll has finished.
        window.setTimeout(function () {
          clickedTarget = null;
          setActive(getCurrentSection().link);
        }, 800);
      });
    });

    var onScroll = function () {
      // While following a clicked navigation link,
      // don't let intermediate scroll events change the active item.
      if (clickedTarget) {
        return;
      }

      var current = getCurrentSection();
      setActive(current.link);
    };

    window.addEventListener("scroll", onScroll, { passive: true });

    // Correct active item on initial page load.
    setActive(getCurrentSection().link);
  }

  // ---------- reveal on scroll ----------
  var revealEls = Array.prototype.slice.call(document.querySelectorAll("[data-reveal]"));
  if (revealEls.length && "IntersectionObserver" in window) {
    var revealObserver = new IntersectionObserver(
      function (entries, obs) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("in-view");
            obs.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.15 }
    );
    revealEls.forEach(function (el) { revealObserver.observe(el); });
  } else {
    revealEls.forEach(function (el) { el.classList.add("in-view"); });
  }

  // ---------- project filter ----------
  var filterButtons = Array.prototype.slice.call(document.querySelectorAll(".filter-btn"));
  var projects = Array.prototype.slice.call(document.querySelectorAll(".project"));

  filterButtons.forEach(function (btn) {
    btn.addEventListener("click", function () {
      var filter = btn.getAttribute("data-filter");

      filterButtons.forEach(function (b) {
        b.classList.remove("is-active");
        b.setAttribute("aria-pressed", "false");
      });
      btn.classList.add("is-active");
      btn.setAttribute("aria-pressed", "true");

      projects.forEach(function (project) {
        var cats = (project.getAttribute("data-category") || "").split(" ");
        var show = filter === "all" || cats.indexOf(filter) !== -1;
        project.hidden = !show;
      });
    });
  });

  // ---------- header shadow state on scroll ----------
  var header = document.querySelector(".site-header");
  if (header) {
    var onScroll = function () {
      header.style.borderBottomColor = window.scrollY > 8
        ? "rgba(237, 238, 235, 0.20)"
        : "rgba(237, 238, 235, 0.10)";
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }
})();