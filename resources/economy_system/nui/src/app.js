/**
 * Resource: economy_system
 * File: nui/src/app.js
 * Purpose: JavaScript application for Criminal Economy UI
 * 
 * Handles:
 * - NUI message communication
 * - Activity display and filtering
 * - Market data visualization
 * - Money laundering interface
 * - Player stats display
 */

// Global state
let activities = [];
let marketData = [];
let playerStats = null;
let selectedActivity = null;
let currentFilter = 'all';
let config = {};

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
            if (data.config) {
                config = data.config;
            }
            break;
        case 'close':
            closeUI();
            break;
        case 'setActivities':
            setActivities(data.activities);
            break;
        case 'setMarketData':
            setMarketData(data.marketData);
            break;
        case 'setPlayerStats':
            setPlayerStats(data.stats);
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

function setActivities(data) {
    activities = data || [];
    renderActivities();
}

function setMarketData(data) {
    marketData = data || [];
    renderMarket();
}

function setPlayerStats(data) {
    playerStats = data;
    renderStats();
}

// =====================================
// RENDER FUNCTIONS
// =====================================

function renderActivities() {
    const list = document.getElementById('activities-list');
    list.innerHTML = '';
    
    const filtered = currentFilter === 'all' 
        ? activities 
        : activities.filter(a => a.type === currentFilter);
    
    for (const activity of filtered) {
        const item = document.createElement('div');
        item.className = 'activity-item' + (activity.onCooldown ? ' on-cooldown' : '');
        item.onclick = () => showActivityDetails(activity);
        
        const riskDots = getRiskDots(activity.riskLevel);
        
        item.innerHTML = `
            <div class="activity-left">
                <div class="activity-icon ${activity.type}">
                    <i class="fas ${getActivityIcon(activity.type)}"></i>
                </div>
                <div class="activity-info">
                    <h4>${activity.name}</h4>
                    <span>${activity.location}</span>
                </div>
            </div>
            <div class="activity-right">
                <div class="activity-reward">¥${formatNumber(activity.estimatedRewardMin)} - ¥${formatNumber(activity.estimatedRewardMax)}</div>
                ${activity.onCooldown ? `<div class="activity-cooldown">${formatTime(activity.cooldownRemaining)}</div>` : ''}
                <div class="risk-indicator">${riskDots}</div>
            </div>
        `;
        
        list.appendChild(item);
    }
    
    if (filtered.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888; padding: 30px;">No activities available</p>';
    }
}

function renderMarket() {
    const grid = document.getElementById('market-grid');
    grid.innerHTML = '';
    
    for (const item of marketData) {
        const priceChange = ((item.priceIndex - 1) * 100).toFixed(1);
        const isUp = item.priceIndex >= 1;
        
        const card = document.createElement('div');
        card.className = 'market-item';
        card.innerHTML = `
            <div class="market-item-header">
                <h4>${formatCommodityName(item.commodity)}</h4>
                <span class="price-change ${isUp ? 'up' : 'down'}">${isUp ? '+' : ''}${priceChange}%</span>
            </div>
            <div class="market-price">¥${formatNumber(item.currentPrice)}</div>
            <div class="market-stats">
                <span>Supply: ${item.serverSupply}</span>
                <span>Seized: ${item.confiscatedAmount}</span>
            </div>
        `;
        
        grid.appendChild(card);
    }
    
    if (marketData.length === 0) {
        grid.innerHTML = '<p style="text-align: center; color: #888; grid-column: span 2;">No market data available</p>';
    }
}

function renderStats() {
    if (!playerStats) return;
    
    // Update overview cards
    document.getElementById('total-earned').textContent = '¥' + formatNumber(playerStats.totals.total_earned || 0);
    document.getElementById('org-contribution').textContent = '¥' + formatNumber(playerStats.totals.total_org_contribution || 0);
    document.getElementById('total-activities').textContent = playerStats.totals.total_activities || 0;
    
    // Render breakdown by type
    const breakdown = document.getElementById('stats-breakdown');
    breakdown.innerHTML = '<h4 style="color: #888; margin-bottom: 15px;">Activity Breakdown</h4>';
    
    for (const stat of (playerStats.byType || [])) {
        const item = document.createElement('div');
        item.className = 'breakdown-item';
        item.innerHTML = `
            <div class="breakdown-left">
                <div class="breakdown-icon activity-icon ${stat.activity_type}">
                    <i class="fas ${getActivityIcon(stat.activity_type)}"></i>
                </div>
                <div>
                    <div style="color: #fff;">${formatCommodityName(stat.activity_type)}</div>
                    <div style="color: #888; font-size: 0.85rem;">${stat.successful}/${stat.total_activities} successful</div>
                </div>
            </div>
            <div style="text-align: right;">
                <div style="color: #4caf50; font-weight: bold;">¥${formatNumber(stat.total_earned || 0)}</div>
            </div>
        `;
        breakdown.appendChild(item);
    }
    
    if (!playerStats.byType || playerStats.byType.length === 0) {
        breakdown.innerHTML += '<p style="text-align: center; color: #888; padding: 20px;">No activities completed yet</p>';
    }
}

// =====================================
// TAB NAVIGATION
// =====================================

document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        const tabName = this.dataset.tab;
        
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        
        document.querySelectorAll('.tab-content').forEach(c => c.classList.add('hidden'));
        document.getElementById(tabName + '-tab').classList.remove('hidden');
    });
});

// =====================================
// FILTER BUTTONS
// =====================================

document.querySelectorAll('.filter-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        currentFilter = this.dataset.filter;
        
        document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        
        renderActivities();
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

function showActivityDetails(activity) {
    selectedActivity = activity;
    
    document.getElementById('modal-activity-name').textContent = activity.name;
    document.getElementById('modal-activity-desc').textContent = activity.description;
    document.getElementById('modal-location').textContent = activity.location;
    document.getElementById('modal-players').textContent = activity.requiredPlayers;
    document.getElementById('modal-equipment').textContent = 
        activity.requiredEquipment && activity.requiredEquipment.length > 0 
            ? activity.requiredEquipment.join(', ') 
            : 'None';
    document.getElementById('modal-risk').textContent = activity.riskLevel + '/10';
    document.getElementById('modal-cooldown').textContent = formatTime(activity.cooldown);
    document.getElementById('modal-reward').textContent = 
        `¥${formatNumber(activity.estimatedRewardMin)} - ¥${formatNumber(activity.estimatedRewardMax)}`;
    
    const startBtn = document.getElementById('start-activity-btn');
    if (activity.onCooldown) {
        startBtn.disabled = true;
        startBtn.innerHTML = `<i class="fas fa-clock"></i> Cooldown: ${formatTime(activity.cooldownRemaining)}`;
    } else {
        startBtn.disabled = false;
        startBtn.innerHTML = '<i class="fas fa-play"></i> Start Activity';
    }
    
    showModal('activity-modal');
}

// =====================================
// ACTION FUNCTIONS
// =====================================

function startSelectedActivity() {
    if (!selectedActivity || selectedActivity.onCooldown) return;
    
    fetch(`https://${GetParentResourceName()}/startActivity`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ activityId: selectedActivity.id })
    });
    
    closeModal('activity-modal');
    closeUI();
}

function launderMoney() {
    const amount = parseInt(document.getElementById('launder-amount').value) || 0;
    
    if (amount < 5000) {
        alert('Minimum amount is ¥5,000');
        return;
    }
    
    if (amount > 500000) {
        alert('Maximum amount is ¥500,000');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/launderMoney`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ amount })
    });
    
    document.getElementById('launder-amount').value = '';
    updateLaunderPreview();
}

function refreshData() {
    fetch(`https://${GetParentResourceName()}/refreshData`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// =====================================
// LAUNDER PREVIEW
// =====================================

document.getElementById('launder-amount').addEventListener('input', updateLaunderPreview);

function updateLaunderPreview() {
    const amount = parseInt(document.getElementById('launder-amount').value) || 0;
    const fee = Math.floor(amount * 0.15);
    const clean = amount - fee;
    
    document.getElementById('preview-amount').textContent = '¥' + formatNumber(amount);
    document.getElementById('preview-fee').textContent = '-¥' + formatNumber(fee);
    document.getElementById('preview-clean').textContent = '¥' + formatNumber(clean);
}

// =====================================
// HELPER FUNCTIONS
// =====================================

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatTime(seconds) {
    if (seconds < 60) return seconds + 's';
    if (seconds < 3600) return Math.floor(seconds / 60) + 'm';
    return Math.floor(seconds / 3600) + 'h ' + Math.floor((seconds % 3600) / 60) + 'm';
}

function formatCommodityName(name) {
    return name.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

function getActivityIcon(type) {
    const icons = {
        'drug': 'fa-cannabis',
        'weapon': 'fa-gun',
        'loan_shark': 'fa-hand-holding-dollar',
        'fraud': 'fa-credit-card',
        'laundry': 'fa-money-bill-wave',
        'human_traffic': 'fa-user-shield'
    };
    return icons[type] || 'fa-skull-crossbones';
}

function getRiskDots(level) {
    let dots = '';
    for (let i = 1; i <= 10; i++) {
        dots += `<div class="risk-dot ${i <= level ? 'active' : ''}"></div>`;
    }
    return dots;
}

// =====================================
// KEYBOARD HANDLER
// =====================================

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeUI();
    }
});
