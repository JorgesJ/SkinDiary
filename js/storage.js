/**
 * storage.js
 * Capa de persistencia de SkinDiary basada en localStorage.
 * Expone un objeto global `SkinStore` con la API de datos del MVP.
 *
 * Modelo de una entrada (entry):
 * {
 *   id: string,            // identificador único
 *   date: string,          // 'YYYY-MM-DD'
 *   condition: number,     // 1..5 (estado de la piel)
 *   products: string[],    // productos usados
 *   tags: string[],        // etiquetas
 *   notes: string,         // notas libres
 *   photo: string|null,    // dataURL (base64) o null
 *   createdAt: string,     // ISO timestamp
 *   updatedAt: string      // ISO timestamp
 * }
 */
(function (global) {
  'use strict';

  const STORAGE_KEY = 'skindiary.entries.v1';

  function safeParse(raw) {
    try {
      const data = JSON.parse(raw);
      return Array.isArray(data) ? data : [];
    } catch (err) {
      console.error('SkinDiary: error al leer los datos guardados', err);
      return [];
    }
  }

  function readAll() {
    if (!global.localStorage) return [];
    const raw = global.localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    return safeParse(raw);
  }

  function writeAll(entries) {
    if (!global.localStorage) return false;
    try {
      global.localStorage.setItem(STORAGE_KEY, JSON.stringify(entries));
      return true;
    } catch (err) {
      console.error('SkinDiary: error al guardar los datos', err);
      return false;
    }
  }

  function generateId() {
    if (global.crypto && typeof global.crypto.randomUUID === 'function') {
      return global.crypto.randomUUID();
    }
    return 'e-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 8);
  }

  const SkinStore = {
    /** Devuelve todas las entradas ordenadas por fecha descendente. */
    getAll() {
      return readAll().sort((a, b) => {
        if (a.date === b.date) {
          return (b.createdAt || '').localeCompare(a.createdAt || '');
        }
        return b.date.localeCompare(a.date);
      });
    },

    /** Devuelve una entrada por id, o null. */
    getById(id) {
      return readAll().find((e) => e.id === id) || null;
    },

    /** Crea una nueva entrada. Devuelve la entrada creada. */
    create(data) {
      const entries = readAll();
      const now = new Date().toISOString();
      const entry = {
        id: generateId(),
        date: data.date,
        condition: Number(data.condition) || 3,
        products: Array.isArray(data.products) ? data.products : [],
        tags: Array.isArray(data.tags) ? data.tags : [],
        notes: data.notes || '',
        photo: data.photo || null,
        createdAt: now,
        updatedAt: now,
      };
      entries.push(entry);
      writeAll(entries);
      return entry;
    },

    /** Actualiza una entrada existente. Devuelve la entrada o null. */
    update(id, data) {
      const entries = readAll();
      const idx = entries.findIndex((e) => e.id === id);
      if (idx === -1) return null;
      const prev = entries[idx];
      const updated = {
        ...prev,
        date: data.date != null ? data.date : prev.date,
        condition: data.condition != null ? Number(data.condition) : prev.condition,
        products: Array.isArray(data.products) ? data.products : prev.products,
        tags: Array.isArray(data.tags) ? data.tags : prev.tags,
        notes: data.notes != null ? data.notes : prev.notes,
        photo: data.photo !== undefined ? data.photo : prev.photo,
        updatedAt: new Date().toISOString(),
      };
      entries[idx] = updated;
      writeAll(entries);
      return updated;
    },

    /** Elimina una entrada por id. Devuelve true si se eliminó. */
    remove(id) {
      const entries = readAll();
      const next = entries.filter((e) => e.id !== id);
      if (next.length === entries.length) return false;
      writeAll(next);
      return true;
    },

    /** Calcula estadísticas para el panel de resumen. */
    getStats() {
      const entries = this.getAll();
      const total = entries.length;
      let avg = null;
      if (total > 0) {
        const sum = entries.reduce((acc, e) => acc + (Number(e.condition) || 0), 0);
        avg = sum / total;
      }
      return {
        total,
        average: avg,
        streak: computeStreak(entries),
        lastDate: total > 0 ? entries[0].date : null,
      };
    },
  };

  /**
   * Calcula la racha de días consecutivos con registro, terminando hoy o ayer.
   */
  function computeStreak(entries) {
    if (!entries.length) return 0;
    const dates = new Set(entries.map((e) => e.date));
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    function toKey(d) {
      const y = d.getFullYear();
      const m = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      return `${y}-${m}-${day}`;
    }

    // La racha puede empezar hoy o ayer (si aún no se ha registrado hoy).
    let cursor = new Date(today);
    if (!dates.has(toKey(cursor))) {
      cursor.setDate(cursor.getDate() - 1);
      if (!dates.has(toKey(cursor))) return 0;
    }

    let streak = 0;
    while (dates.has(toKey(cursor))) {
      streak += 1;
      cursor.setDate(cursor.getDate() - 1);
    }
    return streak;
  }

  global.SkinStore = SkinStore;
})(window);
