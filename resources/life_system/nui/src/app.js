/**
 * Resource: life_system
 * File: nui/src/app.js
 * Purpose: JavaScript application for Phone UI
 * 
 * Handles:
 * - Phone app navigation
 * - Messages and conversations
 * - SNS feed
 * - Bank data display
 * - Contacts management
 * - Insurance management
 */

// Global state
let conversations = [];
let contacts = [];
let snsFeed = [];
let bankData = null;
let insurances = [];
let currentConversation = null;
let currentMessages = [];
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
            openPhone();
            if (data.config) config = data.config;
            break;
        case 'close':
            closePhone();
            break;
        case 'setConversations':
            setConversations(data.conversations);
            break;
        case 'setContacts':
            setContacts(data.contacts);
            break;
        case 'setSNSFeed':
            setSNSFeed(data.posts);
            break;
        case 'setBankData':
            setBankData(data.bankData);
            break;
        case 'setInsurances':
            setInsurances(data.insurances);
            break;
    }
});

// =====================================
// PHONE FUNCTIONS
// =====================================

function openPhone() {
    app.classList.remove('hidden');
    updateTime();
}

function closePhone() {
    app.classList.add('hidden');
    closeAllModals();
    goHome();
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function goHome() {
    document.querySelectorAll('.screen').forEach(s => s.classList.add('hidden'));
    document.getElementById('home-screen').classList.remove('hidden');
    document.getElementById('home-screen').classList.add('active');
}

function openApp(appId) {
    document.querySelectorAll('.screen').forEach(s => {
        s.classList.add('hidden');
        s.classList.remove('active');
    });
    
    const screen = document.getElementById(appId + '-screen');
    if (screen) {
        screen.classList.remove('hidden');
        screen.classList.add('active');
    }
}

// =====================================
// DATA SETTERS
// =====================================

function setConversations(data) {
    conversations = data || [];
    renderConversations();
    
    // Update badge
    let unread = 0;
    for (const conv of conversations) {
        unread += conv.unread_count || 0;
    }
    
    const badge = document.getElementById('messages-badge');
    if (unread > 0) {
        badge.textContent = unread;
        badge.classList.remove('hidden');
    } else {
        badge.classList.add('hidden');
    }
}

function setContacts(data) {
    contacts = data || [];
    renderContacts();
}

function setSNSFeed(data) {
    snsFeed = data || [];
    renderSNSFeed();
}

function setBankData(data) {
    bankData = data;
    renderBankData();
}

function setInsurances(data) {
    insurances = data || [];
    renderInsurances();
}

// =====================================
// RENDER FUNCTIONS
// =====================================

function renderConversations() {
    const list = document.getElementById('conversations-list');
    list.innerHTML = '';
    
    for (const conv of conversations) {
        const item = document.createElement('div');
        item.className = 'conversation-item';
        item.onclick = () => openConversation(conv.other_cid, conv.name);
        
        item.innerHTML = `
            <div class="conversation-avatar">
                <i class="fas fa-user"></i>
            </div>
            <div class="conversation-info">
                <div class="conversation-name">${conv.name}</div>
                <div class="conversation-preview">${conv.phone}</div>
            </div>
            <div class="conversation-meta">
                ${conv.unread_count > 0 ? `<div class="unread-badge">${conv.unread_count}</div>` : ''}
            </div>
        `;
        
        list.appendChild(item);
    }
    
    if (conversations.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888; padding: 30px;">No conversations</p>';
    }
}

function renderContacts() {
    const list = document.getElementById('contacts-list');
    list.innerHTML = '';
    
    for (const contact of contacts) {
        const item = document.createElement('div');
        item.className = 'contact-item';
        
        item.innerHTML = `
            <div class="contact-avatar">
                <i class="fas fa-user"></i>
            </div>
            <div class="contact-info">
                <div class="contact-name">${contact.contact_name}</div>
                <div class="contact-number">${contact.contact_number}</div>
            </div>
            <div class="contact-actions">
                <button class="contact-action-btn" onclick="startConversation('${contact.contact_cid}', '${contact.contact_name}')">
                    <i class="fas fa-comment"></i>
                </button>
            </div>
        `;
        
        list.appendChild(item);
    }
    
    if (contacts.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888; padding: 30px;">No contacts</p>';
    }
}

function renderSNSFeed() {
    const feed = document.getElementById('sns-feed');
    feed.innerHTML = '';
    
    for (const post of snsFeed) {
        const item = document.createElement('div');
        item.className = 'sns-post';
        
        const timeAgo = getTimeAgo(post.created_at);
        
        item.innerHTML = `
            <div class="sns-post-header">
                <div class="sns-avatar">
                    <i class="fas fa-user"></i>
                </div>
                <div class="sns-author">
                    <div class="sns-author-name">${post.author_name}</div>
                    <div class="sns-post-time">${timeAgo}</div>
                </div>
            </div>
            <div class="sns-post-content">${post.content}</div>
            <div class="sns-post-actions">
                <div class="sns-action" onclick="likePost(${post.id})">
                    <i class="fas fa-heart"></i>
                    <span>${post.likes}</span>
                </div>
                <div class="sns-action">
                    <i class="fas fa-comment"></i>
                    <span>0</span>
                </div>
            </div>
        `;
        
        feed.appendChild(item);
    }
    
    if (snsFeed.length === 0) {
        feed.innerHTML = '<p style="text-align: center; color: #888; padding: 30px;">No posts yet</p>';
    }
}

function renderBankData() {
    if (!bankData) return;
    
    document.getElementById('cash-balance').textContent = '¥' + formatNumber(bankData.cash || 0);
    document.getElementById('bank-balance').textContent = '¥' + formatNumber(bankData.bank || 0);
    
    const hiddenContainer = document.getElementById('hidden-accounts');
    hiddenContainer.innerHTML = '';
    
    if (bankData.hiddenAccounts && bankData.hiddenAccounts.length > 0) {
        hiddenContainer.innerHTML = '<h4>HIDDEN ACCOUNTS</h4>';
        
        for (const acc of bankData.hiddenAccounts) {
            const symbol = acc.currency === 'crypto' ? '₿' : '¥';
            
            hiddenContainer.innerHTML += `
                <div class="hidden-account-item">
                    <span>${acc.currency === 'crypto' ? 'Crypto' : 'Hidden'}</span>
                    <span>${symbol}${formatNumber(acc.balance)}</span>
                </div>
            `;
        }
    }
}

function renderInsurances() {
    const list = document.getElementById('insurance-list');
    list.innerHTML = '';
    
    for (const ins of insurances) {
        const item = document.createElement('div');
        item.className = 'insurance-item';
        
        const validUntil = new Date(ins.valid_until).toLocaleDateString();
        
        item.innerHTML = `
            <div class="insurance-item-header">
                <span class="insurance-type">${capitalizeFirst(ins.type)} Insurance</span>
                <span class="insurance-status">Active</span>
            </div>
            <div class="insurance-details">
                <span>Coverage: ¥${formatNumber(ins.coverage)}</span>
                <span>Valid until: ${validUntil}</span>
            </div>
        `;
        
        list.appendChild(item);
    }
    
    if (insurances.length === 0) {
        list.innerHTML = '<p style="text-align: center; color: #888; padding: 20px;">No active insurance policies</p>';
    }
}

function renderMessages() {
    const container = document.getElementById('chat-messages');
    container.innerHTML = '';
    
    for (const msg of currentMessages) {
        const isSent = msg.sender_cid !== currentConversation;
        
        const bubble = document.createElement('div');
        bubble.className = 'message-bubble ' + (isSent ? 'sent' : 'received');
        
        const time = new Date(msg.created_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
        
        bubble.innerHTML = `
            ${msg.message}
            <div class="message-time">${time}</div>
        `;
        
        container.appendChild(bubble);
    }
    
    container.scrollTop = container.scrollHeight;
}

// =====================================
// CONVERSATIONS
// =====================================

function openConversation(otherCid, name) {
    currentConversation = otherCid;
    document.getElementById('chat-title').textContent = name;
    
    // Fetch messages
    fetch(`https://${GetParentResourceName()}/getConversation`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ otherCid })
    })
    .then(response => response.json())
    .then(messages => {
        currentMessages = messages || [];
        renderMessages();
    });
    
    // Mark as read
    fetch(`https://${GetParentResourceName()}/markMessagesRead`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ otherCid })
    });
    
    openApp('chat');
}

function startConversation(citizenid, name) {
    openConversation(citizenid, name);
}

function sendMessage() {
    const input = document.getElementById('message-input');
    const message = input.value.trim();
    
    if (!message || !currentConversation) return;
    
    fetch(`https://${GetParentResourceName()}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            receiverCid: currentConversation,
            message: message
        })
    });
    
    // Add to local messages
    currentMessages.push({
        sender_cid: 'self',
        message: message,
        created_at: new Date().toISOString()
    });
    renderMessages();
    
    input.value = '';
}

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

function showNewMessageModal() {
    showModal('new-message-modal');
}

function showNewPostModal() {
    showModal('new-post-modal');
}

function showAddContactModal() {
    showModal('add-contact-modal');
}

function showPurchaseInsuranceModal() {
    showModal('purchase-insurance-modal');
}

// =====================================
// ACTION FUNCTIONS
// =====================================

function sendNewMessage() {
    const recipient = document.getElementById('new-msg-recipient').value.trim();
    const content = document.getElementById('new-msg-content').value.trim();
    
    if (!recipient || !content) {
        alert('Please fill in all fields');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            receiverCid: recipient,
            message: content
        })
    });
    
    closeModal('new-message-modal');
    document.getElementById('new-msg-recipient').value = '';
    document.getElementById('new-msg-content').value = '';
}

function createPost() {
    const content = document.getElementById('post-content').value.trim();
    const visibility = document.getElementById('post-visibility').value;
    
    if (!content) {
        alert('Please enter some content');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/postSNS`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            content,
            visibility,
            imageUrl: null
        })
    });
    
    closeModal('new-post-modal');
    document.getElementById('post-content').value = '';
}

function likePost(postId) {
    fetch(`https://${GetParentResourceName()}/likeSNSPost`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ postId })
    });
}

function addContact() {
    const citizenid = document.getElementById('contact-citizenid').value.trim();
    const name = document.getElementById('contact-name').value.trim();
    
    if (!citizenid || !name) {
        alert('Please fill in all fields');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/addContact`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ citizenid, name })
    });
    
    closeModal('add-contact-modal');
    document.getElementById('contact-citizenid').value = '';
    document.getElementById('contact-name').value = '';
}

function purchaseInsurance() {
    const insuranceType = document.getElementById('insurance-type').value;
    const targetId = document.getElementById('insurance-target').value.trim();
    const premium = parseInt(document.getElementById('insurance-premium').value) || 0;
    
    if (!targetId) {
        alert('Please enter a target ID');
        return;
    }
    
    if (premium < 200) {
        alert('Minimum premium is ¥200');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/purchaseInsurance`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ insuranceType, targetId, premium })
    });
    
    closeModal('purchase-insurance-modal');
    document.getElementById('insurance-target').value = '';
    document.getElementById('insurance-premium').value = '';
}

// Insurance premium preview
document.getElementById('insurance-premium').addEventListener('input', function() {
    const premium = parseInt(this.value) || 0;
    const coverage = premium * 100;
    document.getElementById('insurance-coverage').textContent = '¥' + formatNumber(coverage);
});

// =====================================
// HELPER FUNCTIONS
// =====================================

function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function capitalizeFirst(str) {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1);
}

function getTimeAgo(dateStr) {
    const date = new Date(dateStr);
    const now = new Date();
    const diff = Math.floor((now - date) / 1000);
    
    if (diff < 60) return 'Just now';
    if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
    if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
    return Math.floor(diff / 86400) + 'd ago';
}

function updateTime() {
    const now = new Date();
    const time = now.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
    document.getElementById('current-time').textContent = time;
}

// Update time every minute
setInterval(updateTime, 60000);

// =====================================
// KEYBOARD HANDLER
// =====================================

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closePhone();
    }
    
    if (event.key === 'Enter' && currentConversation) {
        const input = document.getElementById('message-input');
        if (document.activeElement === input) {
            sendMessage();
        }
    }
});
