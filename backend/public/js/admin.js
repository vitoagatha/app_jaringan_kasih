'use strict';

document.querySelectorAll('[data-toggle-password]').forEach((button) => {
    button.addEventListener('click', () => {
        const input = document.getElementById(button.dataset.togglePassword);
        if (!input) return;
        const show = input.type === 'password';
        input.type = show ? 'text' : 'password';
        button.textContent = show ? 'Sembunyikan' : 'Lihat';
        button.setAttribute('aria-pressed', String(show));
    });
});

const deletionModal = document.getElementById('delete-category-modal');
if (deletionModal) {
    deletionModal.addEventListener('show.bs.modal', (event) => {
        const trigger = event.relatedTarget;
        const form = document.getElementById('delete-category-form');
        const name = document.getElementById('delete-category-name');
        if (!trigger?.dataset.categoryUrl || !form || !name) return;
        form.action = trigger.dataset.categoryUrl;
        name.textContent = trigger.dataset.categoryName;
    });
}

const statusModal = document.getElementById('user-status-modal');
if (statusModal) {
    statusModal.addEventListener('show.bs.modal', (event) => {
        const form = document.getElementById('user-status-form');
        if (!form?.reportValidity()) event.preventDefault();
    });
}
