/**
 * app.js
 * Lógica de interfaz y orquestación de SkinDiary.
 * Depende de SkinStore (storage.js).
 */
(function (global) {
  'use strict';

  const CONDITION_LABELS = {
    1: { label: 'Mala', emoji: '😣' },
    2: { label: 'Regular', emoji: '😕' },
    3: { label: 'Normal', emoji: '😐' },
    4: { label: 'Buena', emoji: '🙂' },
    5: { label: 'Excelente', emoji: '😄' },
  };

  // --- Referencias al DOM ---
  const el = {};
  function cacheDom() {
    el.newEntryBtn = document.getElementById('newEntryBtn');
    el.entriesList = document.getElementById('entriesList');
    el.emptyState = document.getElementById('emptyState');
    el.searchInput = document.getElementById('searchInput');
    el.conditionFilter = document.getElementById('conditionFilter');

    el.statTotal = document.getElementById('statTotal');
    el.statStreak = document.getElementById('statStreak');
    el.statAvg = document.getElementById('statAvg');
    el.statLast = document.getElementById('statLast');

    el.modal = document.getElementById('modal');
    el.modalTitle = document.getElementById('modalTitle');
    el.form = document.getElementById('entryForm');
    el.entryId = document.getElementById('entryId');
    el.entryDate = document.getElementById('entryDate');
    el.entryCondition = document.getElementById('entryCondition');
    el.conditionPicker = document.getElementById('conditionPicker');
    el.entryProducts = document.getElementById('entryProducts');
    el.entryTags = document.getElementById('entryTags');
    el.entryNotes = document.getElementById('entryNotes');
    el.entryPhoto = document.getElementById('entryPhoto');
    el.photoPreviewWrap = document.getElementById('photoPreviewWrap');
    el.photoPreview = document.getElementById('photoPreview');

    el.toast = document.getElementById('toast');
  }

  // Estado temporal de la foto en el formulario.
  let currentPhoto = null;

  // --- Utilidades ---
  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function parseList(value) {
    if (!value) return [];
    return value
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
  }

  function todayKey() {
    const d = new Date();
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  function formatDate(key) {
    // key: 'YYYY-MM-DD'
    const [y, m, d] = key.split('-').map(Number);
    const date = new Date(y, m - 1, d);
    return date.toLocaleDateString('es-ES', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  }

  let toastTimer = null;
  function showToast(message) {
    el.toast.textContent = message;
    el.toast.hidden = false;
    el.toast.classList.add('toast--visible');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
      el.toast.classList.remove('toast--visible');
      setTimeout(() => {
        el.toast.hidden = true;
      }, 300);
    }, 2400);
  }

  // --- Render ---
  function renderStats() {
    const stats = SkinStore.getStats();
    el.statTotal.textContent = stats.total;
    el.statStreak.textContent = stats.streak;
    el.statAvg.textContent =
      stats.average != null
        ? `${CONDITION_LABELS[Math.round(stats.average)].emoji} ${stats.average.toFixed(1)}`
        : '–';
    el.statLast.textContent = stats.lastDate
      ? new Date(stats.lastDate + 'T00:00:00').toLocaleDateString('es-ES', {
          day: 'numeric',
          month: 'short',
        })
      : '–';
  }

  function getFilteredEntries() {
    const query = el.searchInput.value.trim().toLowerCase();
    const condition = el.conditionFilter.value;
    let entries = SkinStore.getAll();

    if (condition) {
      entries = entries.filter((e) => String(e.condition) === condition);
    }
    if (query) {
      entries = entries.filter((e) => {
        const haystack = [
          e.notes,
          (e.products || []).join(' '),
          (e.tags || []).join(' '),
        ]
          .join(' ')
          .toLowerCase();
        return haystack.includes(query);
      });
    }
    return entries;
  }

  function entryCardHtml(entry) {
    const cond = CONDITION_LABELS[entry.condition] || CONDITION_LABELS[3];
    const products = (entry.products || [])
      .map((p) => `<span class="chip">${escapeHtml(p)}</span>`)
      .join('');
    const tags = (entry.tags || [])
      .map((t) => `<span class="chip chip--tag">#${escapeHtml(t)}</span>`)
      .join('');

    const photoHtml = entry.photo
      ? `<img class="entry-photo" src="${entry.photo}" alt="Foto de la entrada del ${escapeHtml(entry.date)}" loading="lazy" />`
      : '';

    return `
      <article class="entry-card" data-id="${entry.id}">
        ${photoHtml}
        <div class="entry-body">
          <div class="entry-top">
            <div class="entry-date">
              <span class="entry-condition" title="${cond.label}">${cond.emoji}</span>
              <div>
                <h3>${escapeHtml(formatDate(entry.date))}</h3>
                <span class="entry-condition-label">${cond.label}</span>
              </div>
            </div>
            <div class="entry-actions">
              <button class="icon-btn" type="button" data-action="edit" data-id="${entry.id}" aria-label="Editar">✏️</button>
              <button class="icon-btn" type="button" data-action="delete" data-id="${entry.id}" aria-label="Eliminar">🗑️</button>
            </div>
          </div>
          ${entry.notes ? `<p class="entry-notes">${escapeHtml(entry.notes)}</p>` : ''}
          ${products ? `<div class="chips"><span class="chips-label">Productos:</span>${products}</div>` : ''}
          ${tags ? `<div class="chips">${tags}</div>` : ''}
        </div>
      </article>
    `;
  }

  function render() {
    renderStats();
    const entries = getFilteredEntries();
    const hasAny = SkinStore.getAll().length > 0;

    if (!hasAny) {
      el.entriesList.innerHTML = '';
      el.emptyState.hidden = false;
      return;
    }
    el.emptyState.hidden = true;

    if (entries.length === 0) {
      el.entriesList.innerHTML =
        '<p class="no-results">No hay entradas que coincidan con el filtro.</p>';
      return;
    }
    el.entriesList.innerHTML = entries.map(entryCardHtml).join('');
  }

  // --- Modal ---
  function setCondition(value) {
    el.entryCondition.value = String(value);
    Array.from(el.conditionPicker.querySelectorAll('.condition-option')).forEach((btn) => {
      btn.classList.toggle('is-active', btn.dataset.value === String(value));
    });
  }

  function setPhoto(dataUrl) {
    currentPhoto = dataUrl || null;
    if (currentPhoto) {
      el.photoPreview.src = currentPhoto;
      el.photoPreviewWrap.hidden = false;
    } else {
      el.photoPreview.removeAttribute('src');
      el.photoPreviewWrap.hidden = true;
      el.entryPhoto.value = '';
    }
  }

  function openModal(entry) {
    el.form.reset();
    setPhoto(null);

    if (entry) {
      el.modalTitle.textContent = 'Editar entrada';
      el.entryId.value = entry.id;
      el.entryDate.value = entry.date;
      setCondition(entry.condition);
      el.entryProducts.value = (entry.products || []).join(', ');
      el.entryTags.value = (entry.tags || []).join(', ');
      el.entryNotes.value = entry.notes || '';
      setPhoto(entry.photo || null);
    } else {
      el.modalTitle.textContent = 'Nueva entrada';
      el.entryId.value = '';
      el.entryDate.value = todayKey();
      setCondition(3);
    }

    el.modal.hidden = false;
    document.body.classList.add('modal-open');
    el.entryDate.focus();
  }

  function closeModal() {
    el.modal.hidden = true;
    document.body.classList.remove('modal-open');
  }

  function readPhotoFile(file) {
    if (!file) return;
    if (!file.type.startsWith('image/')) {
      showToast('El archivo debe ser una imagen.');
      return;
    }
    // Límite razonable para localStorage (~2.5MB).
    if (file.size > 2.5 * 1024 * 1024) {
      showToast('La imagen es muy grande (máx. 2.5 MB).');
      el.entryPhoto.value = '';
      return;
    }
    const reader = new FileReader();
    reader.onload = (e) => setPhoto(e.target.result);
    reader.onerror = () => showToast('No se pudo leer la imagen.');
    reader.readAsDataURL(file);
  }

  function handleSubmit(e) {
    e.preventDefault();
    const id = el.entryId.value;
    const payload = {
      date: el.entryDate.value || todayKey(),
      condition: Number(el.entryCondition.value) || 3,
      products: parseList(el.entryProducts.value),
      tags: parseList(el.entryTags.value),
      notes: el.entryNotes.value.trim(),
      photo: currentPhoto,
    };

    if (id) {
      SkinStore.update(id, payload);
      showToast('Entrada actualizada.');
    } else {
      SkinStore.create(payload);
      showToast('Entrada guardada.');
    }
    closeModal();
    render();
  }

  function handleListClick(e) {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;
    const action = btn.dataset.action;
    const id = btn.dataset.id;

    if (action === 'edit') {
      const entry = SkinStore.getById(id);
      if (entry) openModal(entry);
    } else if (action === 'delete') {
      if (confirm('¿Eliminar esta entrada? Esta acción no se puede deshacer.')) {
        SkinStore.remove(id);
        showToast('Entrada eliminada.');
        render();
      }
    }
  }

  function handleGlobalClick(e) {
    const target = e.target.closest('[data-action]');
    if (!target) return;
    const action = target.dataset.action;
    if (action === 'close-modal') closeModal();
    else if (action === 'open-new') openModal(null);
    else if (action === 'remove-photo') setPhoto(null);
  }

  function bindEvents() {
    el.newEntryBtn.addEventListener('click', () => openModal(null));
    el.form.addEventListener('submit', handleSubmit);
    el.entriesList.addEventListener('click', handleListClick);
    el.emptyState.addEventListener('click', handleGlobalClick);
    el.modal.addEventListener('click', handleGlobalClick);

    el.conditionPicker.addEventListener('click', (e) => {
      const opt = e.target.closest('.condition-option');
      if (opt) setCondition(opt.dataset.value);
    });

    el.entryPhoto.addEventListener('change', (e) => {
      const file = e.target.files && e.target.files[0];
      readPhotoFile(file);
    });

    el.searchInput.addEventListener('input', render);
    el.conditionFilter.addEventListener('change', render);

    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && !el.modal.hidden) closeModal();
    });
  }

  function init() {
    cacheDom();
    bindEvents();
    render();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})(window);
