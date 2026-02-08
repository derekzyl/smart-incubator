// Global State
let socket;
let chart;
let maxDataPoints = 60; // 60 data points (2 mins roughly if 2s update, or more likely we store history)

function init() {
    initWebSocket();
    initChart();
    loadStatus(); // Initial fetch
    // loadSettings happens when tab opens to save bandwidth? Or load all now?
    loadSettings(); 
    loadSchedules();
}

// --- WebSocket ---
function initWebSocket() {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const gateway = `${protocol}//${window.location.host}/ws`;
    
    socket = new WebSocket(gateway);
    
    socket.onopen = function(event) {
        document.getElementById('connection-status').innerText = 'Connected';
        document.getElementById('connection-status').classList.remove('disconnected');
        document.getElementById('connection-status').classList.add('connected');
    };
    
    socket.onclose = function(event) {
        document.getElementById('connection-status').innerText = 'Disconnected';
        document.getElementById('connection-status').classList.remove('connected');
        document.getElementById('connection-status').classList.add('disconnected');
        setTimeout(initWebSocket, 2000);
    };
    
    socket.onmessage = function(event) {
        const data = JSON.parse(event.data);
        updateDashboard(data);
    };
}

// --- Dashboard ---
function updateDashboard(data) {
    // Values
    document.getElementById('temp-value').innerText = data.temp.toFixed(1);
    document.getElementById('humid-value').innerText = data.humid.toFixed(1);
    
    // Status
    updateStatus('fan', data.fan);
    updateStatus('heater', data.heater);
    updateStatus('humid', data.humidifier); // ID mismatch fixed
    
    if (data.stepperPos !== undefined) {
        document.getElementById('stepper-pos').innerText = data.stepperPos;
    }
    
    if (data.time) {
        document.getElementById('system-time').innerText = data.time.split(' ')[1]; // Just time
    }

    // Controls sync
    if(document.getElementById('controls').classList.contains('active')) {
        // Only update toggles if we are not actively interacting? 
        // Or simple: set toggle state.
        document.getElementById('ctrl-fan').checked = data.fan;
        document.getElementById('ctrl-heater').checked = data.heater;
        document.getElementById('ctrl-humidifier').checked = data.humidifier;
    }

    // Chart
    addDataToChart(data.time ? data.time.split(' ')[1] : new Date().toLocaleTimeString(), data.temp, data.humid);
}

function updateStatus(idPrefix, state) {
    const el = document.getElementById(`${idPrefix}-status`);
    if(state) {
        el.innerText = 'ON';
        el.classList.remove('off');
        el.classList.add('on');
    } else {
        el.innerText = 'OFF';
        el.classList.remove('on');
        el.classList.add('off');
    }
}

// --- Controls ---
function toggleDevice(device, state) {
    const payload = {};
    payload[device] = state;
    fetch('/api/control', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(payload)
    });
}

function moveStepper(val) {
    document.getElementById('ctrl-stepper-val').innerText = val;
    // Debounce this in real app, but for now:
    fetch('/api/control', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({stepper: parseInt(val)})
    });
}

// --- Settings ---
function loadSettings() {
    fetch('/api/config')
        .then(res => res.json())
        .then(data => {
            document.getElementById('set-tempMin').value = data.tempMin;
            document.getElementById('set-tempMax').value = data.tempMax;
            document.getElementById('set-humidMin').value = data.humidMin;
            document.getElementById('set-humidMax').value = data.humidMax;
            document.getElementById('set-hysteresis').value = data.hysteresis;
        });
}

function saveSettings(e) {
    e.preventDefault();
    const data = {
        tempMin: parseFloat(document.getElementById('set-tempMin').value),
        tempMax: parseFloat(document.getElementById('set-tempMax').value),
        humidMin: parseFloat(document.getElementById('set-humidMin').value),
        humidMax: parseFloat(document.getElementById('set-humidMax').value),
        hysteresis: parseFloat(document.getElementById('set-hysteresis').value)
    };
    
    fetch('/api/config', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(data)
    }).then(res => {
        if(res.ok) alert('Settings Saved');
    });
}

// --- Schedule ---
function loadSchedules() {
    fetch('/api/schedule')
        .then(res => res.json())
        .then(data => {
            const list = document.getElementById('schedule-list');
            list.innerHTML = '';
            data.forEach(s => {
                const deviceName = s.deviceType === 0 ? 'Fan' : (s.deviceType === 1 ? 'Heater' : 'Humidifier');
                const badgeClass = s.deviceType === 0 ? 'badge-fan' : (s.deviceType === 1 ? 'badge-heater' : 'badge-humid');
                const timeStart = `${String(s.startHour).padStart(2,'0')}:${String(s.startMinute).padStart(2,'0')}`;
                const timeEnd = `${String(s.endHour).padStart(2,'0')}:${String(s.endMinute).padStart(2,'0')}`;
                
                const html = `
                    <div class="schedule-item">
                        <div class="schedule-details">
                            <span class="badge ${badgeClass}">${deviceName}</span>
                            <strong>${timeStart} - ${timeEnd}</strong>
                            <br>
                            <small>${getDaysString(s.daysMask)}</small>
                        </div>
                        <button class="btn btn-danger" style="background:#e74c3c; padding:5px 10px;" onclick="deleteSchedule(${s.id})"><i class="fas fa-trash"></i></button>
                    </div>
                `;
                list.insertAdjacentHTML('beforeend', html);
            });
        });
}

function getDaysString(mask) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    let str = [];
    for(let i=0; i<7; i++) {
        if((mask >> i) & 1) str.push(days[i]);
    }
    return str.join(', ');
}

function openAddScheduleModal() {
    document.getElementById('schedule-modal').style.display = 'block';
}

function closeAddScheduleModal() {
    document.getElementById('schedule-modal').style.display = 'none';
}

function saveSchedule(e) {
    e.preventDefault();
    
    const device = parseInt(document.getElementById('sch-device').value);
    const startParts = document.getElementById('sch-start').value.split(':');
    const endParts = document.getElementById('sch-end').value.split(':');
    
    if(!startParts[0] || !endParts[0]) {
        alert('Please select times');
        return;
    }
    
    let daysMask = 0;
    document.querySelectorAll('.days-selector input:checked').forEach(cb => {
        daysMask |= (1 << parseInt(cb.value));
    });
    
    const data = {
        deviceType: device,
        startHour: parseInt(startParts[0]),
        startMinute: parseInt(startParts[1]),
        endHour: parseInt(endParts[0]),
        endMinute: parseInt(endParts[1]),
        daysMask: daysMask,
        activeState: true,
        enabled: true
    };
    
    fetch('/api/schedule', {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify(data)
    }).then(res => {
        if(res.ok) {
            closeAddScheduleModal();
            loadSchedules();
        }
    });
}

function deleteSchedule(id) {
    if(confirm('Delete rule?')) {
        fetch(`/api/schedule?id=${id}`, { method: 'DELETE' })
            .then(res => loadSchedules());
    }
}

// --- Chart ---
function initChart() {
    const ctx = document.getElementById('envChart').getContext('2d');
    chart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: 'Temperature (°C)',
                borderColor: '#e94560',
                data: [],
                yAxisID: 'y'
            }, {
                label: 'Humidity (%)',
                borderColor: '#3498db',
                data: [],
                yAxisID: 'y1'
            }]
        },
        options: {
            responsive: true,
            scales: {
                y: {
                    type: 'linear',
                    display: true,
                    position: 'left',
                },
                y1: {
                    type: 'linear',
                    display: true,
                    position: 'right',
                    grid: { drawOnChartArea: false },
                },
                x: {
                    display: false // Hide x axis labels to save space or limit
                }
            }
        }
    });
}

function addDataToChart(label, temp, humid) {
    if(!chart) return;
    
    if (chart.data.labels.length > maxDataPoints) {
        chart.data.labels.shift();
        chart.data.datasets[0].data.shift();
        chart.data.datasets[1].data.shift();
    }
    
    chart.data.labels.push(label);
    chart.data.datasets[0].data.push(temp);
    chart.data.datasets[1].data.push(humid);
    chart.update();
}

// --- Utils ---
function showTab(tabId) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.nav-btn').forEach(el => el.classList.remove('active'));
    
    document.getElementById(tabId).classList.add('active');
    // Find the button that calls this function (quick hack)
    // Actually we can just select by index or proper logic.
    // Let's iterate tabs to find index.
    const buttons = document.querySelectorAll('.nav-btn');
    const tabs = ['dashboard', 'controls', 'schedule', 'settings'];
    const idx = tabs.indexOf(tabId);
    if(idx >= 0) buttons[idx].classList.add('active');
}

function loadStatus() {
    fetch('/api/status')
        .then(res => res.json())
        .then(data => updateDashboard(data));
}

// Start
window.addEventListener('load', init);
