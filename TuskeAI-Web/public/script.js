const header = document.querySelector('[data-elevate]');
const revealItems = document.querySelectorAll('.reveal');

const setHeader = () => {
  header?.classList.toggle('is-elevated', window.scrollY > 18);
};

const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add('is-visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.16 });

revealItems.forEach((item) => observer.observe(item));
window.addEventListener('scroll', setHeader, { passive: true });
setHeader();
