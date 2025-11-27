/**
 * Resource: police_system
 * File: nui/src/app.js
 * Purpose: JavaScript application for Police MDT UI
 * 
 * Handles:
 * - NUI message communication
 * - Case management interface
 * - Person and vehicle lookups
 * - Evidence management
 * - Prosecution workflow
 */

// Global state
let cases = [];
let stats = null;
let currentCase = null;
let config = {};
let userJob = 'police';

// DOM Elements
const app = document.getElementById('app');

// =====================================
// NUI MESSAGE HANDLER
// =====================================

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'open':
            openUI();
            if (data.config) config = data.config;
            if (data.job) {
                userJob = data.job;
                document.getElementById('user-job').textContent = 
                    data.job === 'police' ? 'Police Department' : 'Department of Justice';
            }
            break;
        case 'close':
            closeUI();
            break;
        case 'setCases':
            setCases(data.cases, data.total);
            break;
        case 'setStats':
            setStats(data.stats);
            break;
        case 'setCaseDetails':
            setCaseDetails(data.caseData);
            break;
        case 'vehicleCheckResult':
            showVehicleResult(data.result);
            break;
        case 'personLookupResult':
            showPersonResults(data.persons);
            break;
    }
});

// =====================================
// UI FUNCTIONS
// =====================================

function openUI() {
    app.classList.remove('hidden');
}

function closeUI() {
    app.classList.add('hidden');
    closeAllModals();
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function setCases(data, total) {
    cases = data || [];
    renderCases();
}

function setStats(data) {
    stats = data;
    if (stats) {
        document.getElementById('stat-open').textContent = stats.openCases || 0;
        document.getElementById('stat-pending').textContent = stats.pendingCases || 0;
        document.getElementById('stat-closed').textContent = stats.closedCases || 0;
        document.getElementById('stat-my-cases').textContent = stats.myCases || 0;
    }
}

function setCaseDetails(data) {
    currentCase = data;
    if (data) {
        showCaseDetails();
    }
}

// =====================================
// RENDER FUNCTIONS
// =====================================

function renderCases() {
    const list = document.getElementById('cases-list');
    list.innerHTML = '';
    
    for (const c of cases) {
        const item = document.createElement('div');
        item.className = 'case-item';
        item.onclick = () => loadCaseDetails(c.id);
        
        item.innerHTML = `
            <div class="case-left">
                <h4>${c.case_number}: ${c.title}</h4>
                <span>Lead: ${c.lead_officer_name || 'Unknown'}</span>
            </div>
            <div class="case-right">
                <span class="status-badge ${c.status}">${formatStatus(c.status)}</span>
                <div class="case-meta">${c.person_count} persons | ${c.evidence_count} evidence</div>
            </div>
        `;
        
        list.appendChild(item);
    }
    
    if (cases.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888; padding: 30px;">No cases found</p>';
    }
}

function showCaseDetails() {
    if (!currentCase) return;
    
    document.getElementById('case-title').textContent = currentCase.case_number + ': ' + currentCase.title;
    document.getElementById('case-status').textContent = formatStatus(currentCase.status);
    document.getElementById('case-status').className = 'status-badge ' + currentCase.status;
    document.getElementById('case-number').textContent = currentCase.case_number;
    document.getElementById('case-officer').textContent = currentCase.lead_officer_name || '-';
    document.getElementById('case-prosecutor').textContent = currentCase.prosecutor_name || '-';
    document.getElementById('case-created').textContent = formatDate(currentCase.created_at);
    document.getElementById('case-description').textContent = currentCase.description || 'No description';
    
    // Render persons
    renderCasePersons();
    
    // Render evidence
    renderCaseEvidence();
    
    // Render action buttons
    renderCaseActions();
    
    // Show panel
    document.getElementById('case-details-panel').classList.remove('hidden');
}

function renderCasePersons() {
    const list = document.getElementById('case-persons-list');
    list.innerHTML = '';
    
    for (const person of (currentCase.persons || [])) {
        const item = document.createElement('div');
        item.className = 'person-item';
        item.innerHTML = `
            <div class="person-item-left">
                <span class="role-badge ${person.role}">${capitalizeFirst(person.role)}</span>
                <span>${person.name || person.citizenid}</span>
            </div>
            <button class="btn btn-small btn-danger" onclick="removePerson(${person.id})">
                <i class="fas fa-times"></i>
            </button>
        `;
        list.appendChild(item);
    }
    
    if (!currentCase.persons || currentCase.persons.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888;">No persons added</p>';
    }
}

function renderCaseEvidence() {
    const list = document.getElementById('case-evidence-list');
    list.innerHTML = '';
    
    for (const ev of (currentCase.evidence || [])) {
        const item = document.createElement('div');
        item.className = 'evidence-item';
        item.innerHTML = `
            <div class="evidence-item-left">
                <div class="evidence-icon">
                    <i class="fas ${getEvidenceIcon(ev.evidence_type)}"></i>
                </div>
                <div>
                    <div style="color: #fff;">${capitalizeFirst(ev.evidence_type)}</div>
                    <div style="color: #888; font-size: 0.85rem;">${ev.description.substring(0, 50)}...</div>
                </div>
            </div>
            <button class="btn btn-small btn-danger" onclick="removeEvidence(${ev.id})">
                <i class="fas fa-times"></i>
            </button>
        `;
        list.appendChild(item);
    }
    
    if (!currentCase.evidence || currentCase.evidence.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888;">No evidence added</p>';
    }
}

function renderCaseActions() {
    const container = document.getElementById('case-action-buttons');
    container.innerHTML = '';
    
    // Police actions
    if (userJob === 'police') {
        if (currentCase.status === 'open') {
            container.innerHTML += `
                <button class="btn btn-warning" onclick="updateCaseStatus('pending_prosecution')">
                    <i class="fas fa-gavel"></i> Send to Prosecution
                </button>
            `;
        }
    }
    
    // DOJ actions
    if (userJob === 'doj') {
        if (currentCase.status === 'pending_prosecution') {
            if (!currentCase.prosecutor_cid) {
                container.innerHTML += `
                    <button class="btn btn-primary" onclick="acceptProsecution()">
                        <i class="fas fa-user-check"></i> Accept Case
                    </button>
                `;
            }
            
            container.innerHTML += `
                <button class="btn btn-success" onclick="showSentenceModal()">
                    <i class="fas fa-balance-scale"></i> Issue Sentence
                </button>
                <button class="btn btn-danger" onclick="dismissCase()">
                    <i class="fas fa-times-circle"></i> Dismiss Case
                </button>
            `;
        }
    }
    
    if (container.innerHTML === '') {
        container.innerHTML = '<p style="color: #888;">No actions available for this case</p>';
    }
}

function showVehicleResult(result) {
    const container = document.getElementById('vehicle-result');
    
    if (!result.found) {
        container.innerHTML = `
            <div class="vehicle-card">
                <div class="vehicle-header">
                    <h3>Plate: ${result.plate}</h3>
                    <span class="status-badge dismissed">Not Found</span>
                </div>
                <p style="color: #888;">No vehicle found with this plate number</p>
            </div>
        `;
        return;
    }
    
    let casesHtml = '';
    if (result.cases && result.cases.length > 0) {
        casesHtml = '<div class="criminal-history"><h4>Related Cases</h4>';
        for (const c of result.cases) {
            casesHtml += `<div class="history-item">${c.case_number}: ${c.title} (${formatStatus(c.status)})</div>`;
        }
        casesHtml += '</div>';
    }
    
    container.innerHTML = `
        <div class="vehicle-card">
            <div class="vehicle-header">
                <h3>Plate: ${result.plate}</h3>
                <span class="status-badge open">Found</span>
            </div>
            <div class="vehicle-info">
                <div class="info-item">
                    <label>Owner Name</label>
                    <span>${result.owner ? result.owner.name : 'Unknown'}</span>
                </div>
                <div class="info-item">
                    <label>Citizen ID</label>
                    <span>${result.owner ? result.owner.citizenid : 'Unknown'}</span>
                </div>
                <div class="info-item">
                    <label>Vehicle Model</label>
                    <span>${result.model || 'Unknown'}</span>
                </div>
            </div>
            ${casesHtml}
        </div>
    `;
}

function showPersonResults(persons) {
    const container = document.getElementById('lookup-results');
    container.innerHTML = '';
    
    if (!persons || persons.length === 0) {
        container.innerHTML = '<p style="text-align: center; color: #888; padding: 30px;">No results found</p>';
        return;
    }
    
    for (const person of persons) {
        let warrantsHtml = '';
        if (person.activeWarrants && person.activeWarrants.length > 0) {
            warrantsHtml = '<div class="active-warrants"><h4><i class="fas fa-exclamation-triangle"></i> Active Warrants</h4>';
            for (const w of person.activeWarrants) {
                warrantsHtml += `<div class="warrant-item">${w.type.toUpperCase()} WARRANT: ${w.reason}</div>`;
            }
            warrantsHtml += '</div>';
        }
        
        let historyHtml = '';
        if (person.criminalHistory && person.criminalHistory.length > 0) {
            historyHtml = '<div class="criminal-history"><h4>Criminal History</h4>';
            for (const h of person.criminalHistory) {
                historyHtml += `<div class="history-item">${h.offense} - ${h.sentence || 'No sentence'}</div>`;
            }
            historyHtml += '</div>';
        }
        
        container.innerHTML += `
            <div class="person-card">
                <div class="person-header">
                    <h3>${person.name}</h3>
                    ${person.activeWarrants && person.activeWarrants.length > 0 ? '<span class="status-badge dismissed">WANTED</span>' : ''}
                </div>
                <div class="person-info">
                    <div class="info-item">
                        <label>Citizen ID</label>
                        <span>${person.citizenid}</span>
                    </div>
                    <div class="info-item">
                        <label>Phone</label>
                        <span>${person.phone}</span>
                    </div>
                    <div class="info-item">
                        <label>Date of Birth</label>
                        <span>${person.birthdate}</span>
                    </div>
                    <div class="info-item">
                        <label>Active Cases</label>
                        <span>${person.activeCases ? person.activeCases.length : 0}</span>
                    </div>
                </div>
                ${warrantsHtml}
                ${historyHtml}
            </div>
        `;
    }
}

// =====================================
// TAB NAVIGATION
// =====================================

document.querySelectorAll('.nav-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        switchTab(this.dataset.tab);
    });
});

function switchTab(tabName) {
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`.nav-btn[data-tab="${tabName}"]`).classList.add('active');
    
    document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
    document.getElementById(tabName + '-tab').classList.remove('hidden');
    
    // Hide case details panel when switching tabs
    document.getElementById('case-details-panel').classList.add('hidden');
}

// Case sub-tabs
document.querySelectorAll('.case-tab-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        const tabName = this.dataset.caseTab;
        
        document.querySelectorAll('.case-tab-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        
        document.querySelectorAll('.case-tab-content').forEach(c => c.classList.add('hidden'));
        document.getElementById(tabName + '-case-tab').classList.remove('hidden');
    });
});

// =====================================
// MODAL FUNCTIONS
// =====================================

function showModal(modalId) {
    document.getElementById(modalId).classList.remove('hidden');
}

function closeModal(modalId) {
    document.getElementById(modalId).classList.add('hidden');
}

function closeAllModals() {
    document.querySelectorAll('.modal').forEach(m => m.classList.add('hidden'));
}

function showCreateCaseModal() {
    showModal('create-case-modal');
}

function showAddPersonModal() {
    showModal('add-person-modal');
}

function showAddEvidenceModal() {
    showModal('add-evidence-modal');
}

function showSentenceModal() {
    showModal('sentence-modal');
}

// =====================================
// ACTION FUNCTIONS
// =====================================

function loadCaseDetails(caseId) {
    fetch(`https://${GetParentResourceName()}/getCaseDetails`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ caseId })
    });
}

function closeCaseDetails() {
    document.getElementById('case-details-panel').classList.add('hidden');
    currentCase = null;
}

function createCase() {
    const title = document.getElementById('new-case-title').value.trim();
    const description = document.getElementById('new-case-desc').value.trim();
    
    if (!title) {
        alert('Please enter a case title');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/createCase`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ title, description })
    });
    
    closeModal('create-case-modal');
    document.getElementById('new-case-title').value = '';
    document.getElementById('new-case-desc').value = '';
}

function updateCaseStatus(status) {
    if (!currentCase) return;
    
    fetch(`https://${GetParentResourceName()}/updateCaseStatus`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ caseId: currentCase.id, status })
    });
}

function addPerson() {
    if (!currentCase) return;
    
    const citizenid = document.getElementById('person-citizenid').value.trim();
    const role = document.getElementById('person-role').value;
    const notes = document.getElementById('person-notes').value.trim();
    
    if (!citizenid) {
        alert('Please enter a citizen ID');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/addPerson`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ caseId: currentCase.id, citizenid, role, notes })
    });
    
    closeModal('add-person-modal');
    document.getElementById('person-citizenid').value = '';
    document.getElementById('person-notes').value = '';
}

function removePerson(personId) {
    if (!currentCase) return;
    
    if (confirm('Remove this person from the case?')) {
        fetch(`https://${GetParentResourceName()}/removePerson`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ caseId: currentCase.id, personId })
        });
    }
}

function addEvidence() {
    if (!currentCase) return;
    
    const evidenceType = document.getElementById('evidence-type').value;
    const referenceId = document.getElementById('evidence-ref').value.trim();
    const description = document.getElementById('evidence-desc').value.trim();
    
    if (!description) {
        alert('Please enter an evidence description');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/addEvidence`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ caseId: currentCase.id, evidenceType, referenceId, description })
    });
    
    closeModal('add-evidence-modal');
    document.getElementById('evidence-ref').value = '';
    document.getElementById('evidence-desc').value = '';
}

function removeEvidence(evidenceId) {
    if (!currentCase) return;
    
    if (confirm('Remove this evidence?')) {
        fetch(`https://${GetParentResourceName()}/removeEvidence`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ caseId: currentCase.id, evidenceId })
        });
    }
}

function acceptProsecution() {
    if (!currentCase) return;
    
    fetch(`https://${GetParentResourceName()}/acceptProsecution`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ caseId: currentCase.id })
    });
}

function sentenceCase() {
    if (!currentCase) return;
    
    const jailTime = parseInt(document.getElementById('sentence-jail').value) || 0;
    const fine = parseInt(document.getElementById('sentence-fine').value) || 0;
    const notes = document.getElementById('sentence-notes').value.trim();
    
    fetch(`https://${GetParentResourceName()}/sentenceCase`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ caseId: currentCase.id, jailTime, fine, notes })
    });
    
    closeModal('sentence-modal');
    closeCaseDetails();
}

function dismissCase() {
    if (!currentCase) return;
    
    const reason = prompt('Enter reason for dismissal:');
    if (reason) {
        fetch(`https://${GetParentResourceName()}/dismissCase`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ caseId: currentCase.id, reason })
        });
        closeCaseDetails();
    }
}

function filterCases() {
    const status = document.getElementById('case-filter').value;
    
    fetch(`https://${GetParentResourceName()}/filterCases`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status, page: 1, perPage: 50 })
    });
}

function vehicleCheck() {
    const plate = document.getElementById('plate-search').value.trim().toUpperCase();
    
    if (!plate) {
        alert('Please enter a license plate');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/vehicleCheck`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ plate })
    });
}

function personLookup() {
    const query = document.getElementById('person-search').value.trim();
    
    if (!query) {
        alert('Please enter a search query');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/personLookup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query })
    });
}

// =====================================
// HELPER FUNCTIONS
// =====================================

function capitalizeFirst(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

function formatStatus(status) {
    const labels = {
        'open': 'Open',
        'pending_prosecution': 'Pending Prosecution',
        'closed': 'Closed',
        'dismissed': 'Dismissed'
    };
    return labels[status] || status;
}

function formatDate(dateStr) {
    if (!dateStr) return '-';
    const date = new Date(dateStr);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
}

function getEvidenceIcon(type) {
    const icons = {
        'item': 'fa-box',
        'weapon': 'fa-gun',
        'photo': 'fa-camera',
        'audio': 'fa-microphone',
        'log': 'fa-file-alt',
        'dna': 'fa-dna',
        'fingerprint': 'fa-fingerprint'
    };
    return icons[type] || 'fa-file';
}

// =====================================
// KEYBOARD HANDLER
// =====================================

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeUI();
    }
});
