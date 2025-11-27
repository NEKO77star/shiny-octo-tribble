/**
 * Resource: org_system
 * File: nui/src/app.js
 * Purpose: JavaScript application for Organization Management UI
 * 
 * Handles:
 * - NUI message communication with client
 * - Tab navigation
 * - Modal management
 * - Data display and updates
 */

// Global state
let currentOrganization = null;
let currentMembers = [];
let currentAssets = [];
let currentHiddenAccounts = [];
let currentTerritories = [];
let currentLogs = [];
let selectedMember = null;
let config = {};

// DOM Elements
const app = document.getElementById('app');
const noOrgView = document.getElementById('no-org-view');
const orgView = document.getElementById('org-view');

// =====================================
// NUI MESSAGE HANDLER
// =====================================

window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'open':
            openUI();
            if (data.config) {
                config = data.config;
            }
            break;
        case 'close':
            closeUI();
            break;
        case 'setOrganization':
            setOrganization(data.organization);
            break;
        case 'setMembers':
            setMembers(data.members);
            break;
        case 'setAssets':
            setAssets(data.assets);
            break;
        case 'setHiddenAccounts':
            setHiddenAccounts(data.accounts);
            break;
        case 'setTerritories':
            setTerritories(data.territories);
            break;
        case 'setLogs':
            setLogs(data.logs);
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

function setOrganization(org) {
    currentOrganization = org;
    
    if (org) {
        noOrgView.classList.add('hidden');
        orgView.classList.remove('hidden');
        
        document.getElementById('org-title').textContent = org.name;
        document.getElementById('org-name').textContent = org.name;
        document.getElementById('org-type').textContent = capitalizeFirst(org.type);
        document.getElementById('org-role').textContent = capitalizeFirst(org.playerRole);
        
        // Show/hide boss controls
        const bossControls = document.getElementById('boss-controls');
        if (org.playerRole === 'boss') {
            bossControls.classList.remove('hidden');
        } else {
            bossControls.classList.add('hidden');
        }
        
        // Show/hide invite button based on permission
        const inviteBtn = document.getElementById('invite-btn');
        if (hasPermission('invite')) {
            inviteBtn.classList.remove('hidden');
        } else {
            inviteBtn.classList.add('hidden');
        }
    } else {
        noOrgView.classList.remove('hidden');
        orgView.classList.add('hidden');
        document.getElementById('org-title').textContent = 'Organization Management';
    }
}

function setMembers(members) {
    currentMembers = members || [];
    renderMembers();
}

function setAssets(assets) {
    currentAssets = assets || [];
    
    // Calculate treasury amount
    let treasury = 0;
    for (const asset of currentAssets) {
        if (asset.asset_type === 'cash' && asset.identifier === 'main_treasury') {
            treasury = asset.amount;
            break;
        }
    }
    
    document.getElementById('treasury-amount').textContent = '¥' + formatNumber(treasury);
}

function setHiddenAccounts(accounts) {
    currentHiddenAccounts = accounts || [];
    renderHiddenAccounts();
}

function setTerritories(territories) {
    currentTerritories = territories || [];
    renderTerritories();
}

function setLogs(logs) {
    currentLogs = logs || [];
    renderLogs();
}

// =====================================
// RENDER FUNCTIONS
// =====================================

function renderMembers() {
    const list = document.getElementById('members-list');
    list.innerHTML = '';
    
    for (const member of currentMembers) {
        const item = document.createElement('div');
        item.className = 'member-item';
        item.onclick = () => showMemberActions(member);
        
        item.innerHTML = `
            <div class="member-info-left">
                <div class="member-avatar">
                    <i class="fas fa-user"></i>
                </div>
                <div class="member-details">
                    <h4>${member.name || member.citizenid}</h4>
                    <span>Salary: ¥${formatNumber(member.salary)} | Share: ${member.share_percent}%</span>
                </div>
            </div>
            <div class="member-status">
                <span class="badge badge-${member.role}">${capitalizeFirst(member.role)}</span>
                <div class="online-indicator ${member.online ? 'online' : ''}"></div>
            </div>
        `;
        
        list.appendChild(item);
    }
    
    if (currentMembers.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888;">No members found</p>';
    }
}

function renderHiddenAccounts() {
    const list = document.getElementById('hidden-accounts-list');
    list.innerHTML = '';
    
    for (const account of currentHiddenAccounts) {
        const currencySymbol = account.currency === 'crypto' ? '₿' : '¥';
        
        const item = document.createElement('div');
        item.className = 'account-item';
        item.innerHTML = `
            <span>${account.ownerName} (${capitalizeFirst(account.currency)})</span>
            <span class="account-balance">${currencySymbol}${formatNumber(account.balance)}</span>
        `;
        
        list.appendChild(item);
    }
    
    if (currentHiddenAccounts.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888; font-size: 0.85rem;">No hidden accounts</p>';
    }
}

function renderTerritories() {
    const list = document.getElementById('territories-list');
    list.innerHTML = '';
    
    for (const territory of currentTerritories) {
        const item = document.createElement('div');
        item.className = 'territory-item';
        item.innerHTML = `
            <div class="territory-info">
                <h4>${territory.name}</h4>
                <span>Zone: ${territory.zone_id}</span>
            </div>
            <div class="territory-bonus">+${((territory.base_bonus - 1) * 100).toFixed(0)}%</div>
        `;
        
        list.appendChild(item);
    }
    
    if (currentTerritories.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888;">No territories controlled</p>';
    }
}

function renderLogs() {
    const list = document.getElementById('logs-list');
    list.innerHTML = '';
    
    for (const log of currentLogs) {
        const item = document.createElement('div');
        item.className = 'log-item';
        
        const date = new Date(log.created_at);
        const timeStr = date.toLocaleString();
        
        item.innerHTML = `
            <span class="log-action">${formatLogAction(log.action_type)}</span>
            <span class="log-time">${timeStr}</span>
        `;
        
        list.appendChild(item);
    }
    
    if (currentLogs.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888;">No logs available</p>';
    }
}

// =====================================
// TAB NAVIGATION
// =====================================

document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        const tabName = this.dataset.tab;
        
        // Update button states
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        
        // Update content visibility
        document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
        document.getElementById(tabName + '-tab').classList.remove('hidden');
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

function showCreateOrgModal() {
    showModal('create-org-modal');
}

function showInviteModal() {
    showModal('invite-modal');
}

function showAddAssetModal() {
    showModal('add-asset-modal');
}

function showCreateHiddenAccountModal() {
    showModal('create-hidden-account-modal');
}

function showMemberActions(member) {
    selectedMember = member;
    
    document.getElementById('selected-member-name').textContent = member.name || member.citizenid;
    document.getElementById('selected-member-role').textContent = capitalizeFirst(member.role);
    document.getElementById('selected-member-role').className = 'badge badge-' + member.role;
    document.getElementById('member-salary').value = member.salary;
    document.getElementById('member-share').value = member.share_percent;
    
    // Show/hide action buttons based on permissions
    const promoteBtn = document.getElementById('promote-btn');
    const demoteBtn = document.getElementById('demote-btn');
    const kickBtn = document.getElementById('kick-btn');
    
    promoteBtn.style.display = hasPermission('promote') ? 'inline-flex' : 'none';
    demoteBtn.style.display = hasPermission('demote') ? 'inline-flex' : 'none';
    kickBtn.style.display = hasPermission('kick') ? 'inline-flex' : 'none';
    
    showModal('member-actions-modal');
}

// =====================================
// ACTION FUNCTIONS
// =====================================

function createOrganization() {
    const name = document.getElementById('new-org-name').value.trim();
    const type = document.getElementById('new-org-type').value;
    
    if (!name) {
        alert('Please enter an organization name');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/createOrganization`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, type })
    });
    
    closeModal('create-org-modal');
    document.getElementById('new-org-name').value = '';
}

function confirmDisband() {
    if (confirm('Are you sure you want to disband this organization? This action cannot be undone.')) {
        fetch(`https://${GetParentResourceName()}/disbandOrganization`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ orgId: currentOrganization.id })
        });
    }
}

function inviteMember() {
    const citizenid = document.getElementById('invite-citizenid').value.trim();
    
    if (!citizenid) {
        alert('Please enter a citizen ID');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/inviteMember`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ citizenid })
    });
    
    closeModal('invite-modal');
    document.getElementById('invite-citizenid').value = '';
}

function kickMember() {
    if (!selectedMember) return;
    
    if (confirm(`Are you sure you want to kick ${selectedMember.name || selectedMember.citizenid}?`)) {
        fetch(`https://${GetParentResourceName()}/kickMember`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ citizenid: selectedMember.citizenid })
        });
        
        closeModal('member-actions-modal');
    }
}

function promoteMember() {
    if (!selectedMember) return;
    
    fetch(`https://${GetParentResourceName()}/promoteMember`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ citizenid: selectedMember.citizenid })
    });
    
    closeModal('member-actions-modal');
}

function demoteMember() {
    if (!selectedMember) return;
    
    fetch(`https://${GetParentResourceName()}/demoteMember`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ citizenid: selectedMember.citizenid })
    });
    
    closeModal('member-actions-modal');
}

function updateCompensation() {
    if (!selectedMember) return;
    
    const salary = parseInt(document.getElementById('member-salary').value) || 0;
    const sharePercent = parseInt(document.getElementById('member-share').value) || 0;
    
    fetch(`https://${GetParentResourceName()}/updateCompensation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            citizenid: selectedMember.citizenid,
            salary,
            sharePercent
        })
    });
    
    closeModal('member-actions-modal');
}

function addAsset() {
    const amount = parseInt(document.getElementById('asset-amount').value) || 0;
    
    if (amount <= 0) {
        alert('Please enter a valid amount');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/addAsset`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            assetType: 'cash',
            identifier: 'main_treasury',
            amount,
            hidden: false
        })
    });
    
    closeModal('add-asset-modal');
    document.getElementById('asset-amount').value = '';
}

function createHiddenAccount() {
    const ownerType = document.getElementById('hidden-account-type').value;
    const currency = document.getElementById('hidden-account-currency').value;
    
    let ownerId = '';
    if (ownerType === 'organization' && currentOrganization) {
        ownerId = currentOrganization.id.toString();
    }
    
    fetch(`https://${GetParentResourceName()}/createHiddenAccount`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ownerType, ownerId, currency })
    });
    
    closeModal('create-hidden-account-modal');
}

function refreshData() {
    fetch(`https://${GetParentResourceName()}/refreshData`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// =====================================
// HELPER FUNCTIONS
// =====================================

function capitalizeFirst(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatLogAction(action) {
    const actions = {
        'create_organization': 'Organization Created',
        'invite_member': 'Member Invited',
        'kick_member': 'Member Kicked',
        'promote_member': 'Member Promoted',
        'demote_member': 'Member Demoted',
        'update_compensation': 'Compensation Updated',
        'add_asset': 'Asset Added',
        'remove_asset': 'Asset Removed',
        'start_conflict': 'Conflict Started',
        'resolve_conflict': 'Conflict Resolved',
        'revenue': 'Revenue Received'
    };
    return actions[action] || action;
}

function hasPermission(permission) {
    if (!currentOrganization || !currentOrganization.playerRole) return false;
    
    const rolePermissions = {
        'boss': ['invite', 'kick', 'promote', 'demote', 'manageAssets', 'manageTerritories', 'editSettings', 'viewLogs'],
        'executive': ['invite', 'kick', 'promote', 'demote', 'manageAssets', 'manageTerritories', 'viewLogs'],
        'member': [],
        'associate': []
    };
    
    const perms = rolePermissions[currentOrganization.playerRole] || [];
    return perms.includes(permission);
}

// =====================================
// KEYBOARD HANDLER
// =====================================

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeUI();
    }
});
