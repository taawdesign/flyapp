/* ============================================
   Fly Webapp - JavaScript Interactions
   Premium Download Experience
   ============================================ */

// State management
const state = {
    step1Complete: false,
    step2Complete: false
};

// DOM Elements
const elements = {
    step1: document.getElementById('step1'),
    step2: document.getElementById('step2'),
    step1Status: document.getElementById('step1-status'),
    step2Status: document.getElementById('step2-status'),
    btnStep1: document.getElementById('btn-step1'),
    btnStep2: document.getElementById('btn-step2'),
    lineProgress: document.getElementById('line-progress'),
    noteLineProgress: document.getElementById('note-line-progress'),
    modal: document.getElementById('successModal'),
    modalMessage: document.getElementById('modalMessage'),
    versionText: document.getElementById('version-text')
};

// GitHub configuration
const GITHUB_USERNAME = 'taawdesign';
const REPO_NAME = 'fly';
const GITHUB_PAGES_URL = `https://${GITHUB_USERNAME}.github.io/${REPO_NAME}`;

// File paths configuration
const FILES = {
    'DNS.mobileconfig': {
        path: `${GITHUB_PAGES_URL}/DNS.mobileconfig`,
        type: 'profile',
        message: 'DNS Profile is downloading. After download, go to Settings → General → VPN & Device Management to install it.'
    },
    'Fly.ipa': {
        path: `${GITHUB_PAGES_URL}/manifest.plist`,
        type: 'ota',
        message: 'Installing Fly App... After installation, go to Settings → General → VPN & Device Management to trust the profile.'
    }
};

/**
 * Initialize the webapp
 */
function init() {
    // Fetch latest version from GitHub releases
    fetchLatestVersion();
    
    // Add subtle parallax effect on mouse move (desktop)
    if (window.matchMedia('(pointer: fine)').matches) {
        initParallax();
    }

    // Add touch feedback for mobile
    addTouchFeedback();
}

/**
 * Fetch latest release version from GitHub API
 */
async function fetchLatestVersion() {
    try {
        const response = await fetch(`https://api.github.com/repos/${GITHUB_USERNAME}/${REPO_NAME}/releases/latest`);
        if (!response.ok) throw new Error('Failed to fetch version');
        
        const data = await response.json();
        const version = data.tag_name || data.name || '1.8';
        
        // Update the version text with the release tag directly
        if (elements.versionText) {
            elements.versionText.textContent = version;
        }
    } catch (error) {
        console.error('Error fetching version:', error);
        // Keep the default version if fetch fails
    }
}

/**
 * Download file handler
 * @param {string} filename - Name of the file to download
 * @param {number} step - Step number (1 or 2)
 */
function downloadFile(filename, step) {
    const fileConfig = FILES[filename];
    if (!fileConfig) {
        console.error('File not found:', filename);
        return;
    }

    // Handle different file types
    if (fileConfig.type === 'profile') {
        // For mobileconfig, navigate to it for iOS to handle
        window.location.href = fileConfig.path;
    } else if (fileConfig.type === 'ota') {
        // For OTA app installation, use itms-services protocol
        const manifestUrl = encodeURIComponent(fileConfig.path);
        const otaUrl = `itms-services://?action=download-manifest&url=${manifestUrl}`;
        window.location.href = otaUrl;
    } else {
        // Fallback for other files
        const link = document.createElement('a');
        link.href = fileConfig.path;
        link.download = filename;
        link.click();
    }

    // Update UI
    markStepComplete(step);

    // Add haptic feedback if available
    if (navigator.vibrate) {
        navigator.vibrate(50);
    }
}

/**
 * Mark a step as complete
 * @param {number} step - Step number to mark complete
 */
function markStepComplete(step) {
    const stepElement = step === 1 ? elements.step1 : elements.step2;
    const statusElement = step === 1 ? elements.step1Status : elements.step2Status;
    const btnElement = step === 1 ? elements.btnStep1 : elements.btnStep2;

    // Update state
    if (step === 1) {
        state.step1Complete = true;
    } else {
        state.step2Complete = true;
    }

    // Add completed class to card
    stepElement.classList.add('completed');

    // Update status icon
    statusElement.innerHTML = `
        <svg class="icon-complete" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="rgba(52, 199, 89, 0.2)"/>
            <path d="M8 12L11 15L16 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
    `;

    // Update button
    btnElement.classList.add('downloaded');
    btnElement.querySelector('.btn-text').textContent = step === 1 ? 'Installed' : 'Downloaded';

    // Animate connection line if step 1 is complete
    if (step === 1) {
        setTimeout(() => {
            elements.lineProgress.classList.add('active');
        }, 300);
    }
    
    // Animate note connector line if step 2 is complete
    if (step === 2) {
        setTimeout(() => {
            elements.noteLineProgress.classList.add('active');
        }, 300);
    }
}

/**
 * Show success modal
 * @param {string} message - Message to display
 */
function showModal(message) {
    elements.modalMessage.textContent = message;
    elements.modal.classList.add('active');

    // Prevent body scroll
    document.body.style.overflow = 'hidden';
}

/**
 * Close modal
 */
function closeModal() {
    elements.modal.classList.remove('active');
    document.body.style.overflow = '';
}

/**
 * Save state to localStorage
 */
function saveState() {
    try {
        localStorage.setItem('flyAppState', JSON.stringify(state));
    } catch (e) {
        // localStorage not available
    }
}

/**
 * Load state from localStorage
 */
function loadState() {
    try {
        const saved = localStorage.getItem('flyAppState');
        if (saved) {
            const parsed = JSON.parse(saved);
            if (parsed.step1Complete) {
                markStepComplete(1);
            }
            if (parsed.step2Complete) {
                markStepComplete(2);
            }
        }
    } catch (e) {
        // localStorage not available
    }
}

/**
 * Initialize parallax effect for background orbs
 */
function initParallax() {
    const orbs = document.querySelectorAll('.gradient-orb');

    document.addEventListener('mousemove', (e) => {
        const x = (e.clientX / window.innerWidth - 0.5) * 2;
        const y = (e.clientY / window.innerHeight - 0.5) * 2;

        orbs.forEach((orb, index) => {
            const factor = (index + 1) * 10;
            const translateX = x * factor;
            const translateY = y * factor;
            orb.style.transform = `translate(${translateX}px, ${translateY}px)`;
        });
    });
}

/**
 * Add touch feedback for mobile buttons
 */
function addTouchFeedback() {
    const buttons = document.querySelectorAll('.download-btn, .modal-btn');

    buttons.forEach(btn => {
        btn.addEventListener('touchstart', () => {
            btn.style.transform = 'scale(0.97)';
        }, { passive: true });

        btn.addEventListener('touchend', () => {
            btn.style.transform = '';
        }, { passive: true });
    });
}

/**
 * Handle escape key to close modal
 */
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && elements.modal.classList.contains('active')) {
        closeModal();
    }
});

/**
 * Handle modal backdrop click
 */
elements.modal.addEventListener('click', (e) => {
    if (e.target === elements.modal) {
        closeModal();
    }
});

// Initialize on DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}

// Service Worker registration for PWA (optional)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
        // Uncomment to enable service worker
        // navigator.serviceWorker.register('/fly/sw.js');
    });
}
