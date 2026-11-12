(function () {
  "use strict";

  // Mobile menu toggle
  var boton = document.querySelector(".menu-movil");
  var navMovil = document.getElementById("nav-movil");
  if (boton && navMovil) {
    boton.addEventListener("click", function () {
      var abierto = navMovil.hidden === false;
      navMovil.hidden = abierto;
      boton.setAttribute("aria-expanded", String(!abierto));
    });
    navMovil.querySelectorAll("a").forEach(function (a) {
      a.addEventListener("click", function () {
        navMovil.hidden = true;
        boton.setAttribute("aria-expanded", "false");
      });
    });
  }

  // Progress bars fill once when they enter the viewport
  var barras = document.querySelectorAll("[data-avance-barra]");
  var reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (reduce || !("IntersectionObserver" in window)) {
    barras.forEach(function (b) { b.classList.add("es-visible"); });
    return;
  }

  var obs = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add("es-visible");
        obs.unobserve(entry.target);
      }
    });
  }, { threshold: 0.4 });

  barras.forEach(function (b) { obs.observe(b); });
})();
