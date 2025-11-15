// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:load", () => {
  const measurementId = document.querySelector("meta[name='ga-measurement-id']")?.content;
  if (!window.gtag || !measurementId) return;

  window.gtag("config", measurementId, {
    page_path: window.location.pathname + window.location.search,
  });
});
