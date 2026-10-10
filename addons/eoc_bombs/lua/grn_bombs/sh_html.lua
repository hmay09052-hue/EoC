GRN_Bombs = GRN_Bombs or {}
GRN_Bombs.MenuHTML = [[
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>GMOD – Bomb Creator</title>
<link href="https://fonts.googleapis.com/css2?family=Rajdhani:wght@400;500;600;700&family=Exo+2:wght@300;400;600;700&display=swap" rel="stylesheet">
<style>
@import url('https://fonts.googleapis.com/css2?family=Rajdhani:wght@400;500;600;700&family=Exo+2:wght@300;400;600;700&display=swap');
:root{
  --bg-dark:#0a0c10;--bg-panel:#111420;--bg-card:#161a27;--bg-hover:#1e2436;
  --accent-blue:#1e6ec8;--accent-blue-light:#3a8fdf;--accent-cyan:#00cfcf;
  --accent-gold:#f0c040;--accent-green:#2ecc71;--accent-red:#e74c3c;--accent-orange:#e67e22;
  --accent-purple:#9b59b6;
  --text-primary:#e8eaf0;--text-secondary:#8a93b0;--text-dim:#555e7a;
  --border-color:#252d45;--border-accent:#2a4070;--transition:0.18s ease;
}
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
html,body{
  height:100%;
  font-family:'Exo 2',sans-serif;
  color:var(--text-primary);
  background: transparent; /* Ahora es transparente */
}
body{display:flex;align-items:center;justify-content:center;min-height:100vh;overflow:hidden}

/* ─── WINDOW ─── */
.gmod-window{
  width:min(99vw,1160px);height:min(96vh,880px);
  background:var(--bg-panel);border:1px solid var(--border-color);
  box-shadow:0 8px 60px rgba(0,0,0,.85),inset 0 1px 0 rgba(255,255,255,.04);
  display:flex;flex-direction:column;overflow:hidden;position:relative;
}

/* ─── TITLE BAR ─── */
.title-bar{
  height:38px;background:linear-gradient(90deg,#0d1525,#121b30 60%,#0d1525);
  border-bottom:1px solid var(--border-accent);display:flex;align-items:center;
  padding:0 10px;gap:8px;flex-shrink:0;user-select:none;
}
.title-bar .server-name{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:12px;letter-spacing:.14em;text-transform:uppercase;color:var(--accent-cyan)}
.title-bar .sep{color:var(--text-dim);font-size:11px}
.breadcrumb{font-size:11px;color:var(--text-secondary);flex:1}
.breadcrumb span{color:var(--text-primary)}
.lang-btn{
  padding:4px 10px;background:rgba(255,255,255,.04);border:1px solid rgba(255,255,255,.1);
  border-radius:3px;font-family:'Rajdhani',sans-serif;font-weight:700;font-size:10px;
  letter-spacing:.1em;text-transform:uppercase;color:var(--text-dim);cursor:pointer;
  transition:all .15s;display:flex;align-items:center;gap:5px;
}
.lang-btn:hover{background:rgba(240,192,64,.1);border-color:rgba(240,192,64,.35);color:var(--accent-gold)}
.win-btn{width:22px;height:22px;border-radius:3px;border:1px solid rgba(255,255,255,.08);display:grid;place-items:center;cursor:pointer;font-size:12px;transition:background var(--transition);background:rgba(255,255,255,.04);color:var(--text-secondary)}
.win-btn.close{border-color:rgba(231,76,60,.3);color:#e74c3c}.win-btn.close:hover{background:#e74c3c;color:#fff}

/* ─── MAIN LAYOUT ─── */
.main-layout{display:flex;flex:1;min-height:0;overflow:hidden}

/* ─── SIDEBAR ─── */
.sidebar{
  width:270px;flex-shrink:0;background:var(--bg-dark);border-right:1px solid var(--border-color);
  display:flex;flex-direction:column;overflow:hidden;
}
.sidebar-hdr{
  padding:10px 12px;border-bottom:1px solid var(--border-color);
  display:flex;align-items:center;justify-content:space-between;flex-shrink:0;
}
.sidebar-hdr-title{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:11px;letter-spacing:.12em;text-transform:uppercase;color:var(--text-dim)}
.btn-new{
  padding:5px 12px;background:rgba(0,207,207,.1);border:1px solid rgba(0,207,207,.3);
  color:var(--accent-cyan);font-family:'Rajdhani',sans-serif;font-weight:700;font-size:11px;
  letter-spacing:.07em;text-transform:uppercase;cursor:pointer;border-radius:3px;
  transition:all .15s;white-space:nowrap;
}
.btn-new:hover{background:rgba(0,207,207,.22);border-color:var(--accent-cyan)}

.sidebar-search{padding:8px 10px;border-bottom:1px solid var(--border-color)}
.sidebar-search input{
  width:100%;background:#0e1220;border:1px solid var(--border-color);
  padding:7px 10px;color:#fff;outline:none;font-family:'Exo 2',sans-serif;font-size:12px;
  border-radius:3px;transition:border-color .15s;
}
.sidebar-search input:focus{border-color:var(--accent-cyan)}
.sidebar-search input::placeholder{color:var(--text-dim)}

.sidebar-list{overflow-y:auto;flex:1}
.sidebar-list::-webkit-scrollbar{width:5px}
.sidebar-list::-webkit-scrollbar-track{background:var(--bg-dark)}
.sidebar-list::-webkit-scrollbar-thumb{background:var(--border-accent);border-radius:3px}

.cat-header{
  padding:6px 12px;font-family:'Rajdhani',sans-serif;font-weight:700;font-size:10px;
  letter-spacing:.12em;text-transform:uppercase;color:var(--text-dim);
  background:rgba(0,0,0,.25);border-bottom:1px solid var(--border-color);
  border-top:1px solid var(--border-color);display:flex;align-items:center;gap:6px;cursor:pointer;
  user-select:none;
}
.cat-header .cat-count{background:rgba(255,255,255,.07);padding:1px 6px;border-radius:999px;font-size:9px}
.cat-header .cat-arr{margin-left:auto;font-size:10px;transition:transform .15s}
.cat-header.collapsed .cat-arr{transform:rotate(-90deg)}

.bomb-item{
  padding:9px 12px;border-bottom:1px solid rgba(37,45,69,.5);cursor:pointer;
  display:flex;align-items:center;gap:10px;transition:background var(--transition);
  position:relative;
}
.bomb-item:hover{background:var(--bg-hover)}
.bomb-item.active{background:var(--bg-hover);border-left:3px solid var(--accent-cyan)}
.bomb-item.active .bi-name{color:#fff}

.bi-icon{
  width:36px;height:36px;border-radius:3px;border:1px solid var(--border-accent);
  background:var(--bg-card);flex-shrink:0;display:flex;align-items:center;justify-content:center;
  font-size:18px;
}
.bi-icon.type-explosive{border-color:rgba(231,76,60,.4);background:rgba(231,76,60,.07)}
.bi-icon.type-training{border-color:rgba(30,110,200,.4);background:rgba(30,110,200,.07)}
.bi-icon.type-gas{border-color:rgba(46,204,113,.4);background:rgba(46,204,113,.07)}

.bi-info{flex:1;min-width:0}
.bi-name{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:13px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.bi-meta{font-size:10px;color:var(--text-dim);margin-top:1px}
.bi-badge{
  font-size:9px;padding:2px 6px;border-radius:2px;font-family:'Rajdhani',sans-serif;
  font-weight:700;letter-spacing:.04em;flex-shrink:0;
}
.badge-explosive{background:rgba(231,76,60,.15);color:#e74c3c;border:1px solid rgba(231,76,60,.3)}
.badge-training{background:rgba(30,110,200,.15);color:var(--accent-blue-light);border:1px solid rgba(30,110,200,.3)}
.badge-gas{background:rgba(46,204,113,.15);color:#2ecc71;border:1px solid rgba(46,204,113,.3)}

/* ─── MAIN CONTENT ─── */
.main-content{flex:1;min-width:0;display:flex;flex-direction:column;overflow:hidden}

/* ─── EMPTY STATE ─── */
.empty-state{
  flex:1;display:flex;flex-direction:column;align-items:center;justify-content:center;
  gap:12px;text-align:center;padding:32px;
}
.empty-icon{font-size:56px;opacity:.25}
.empty-title{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:22px;color:var(--text-secondary)}
.empty-sub{font-size:13px;color:var(--text-dim);max-width:340px;line-height:1.6}
.btn-empty-new{
  margin-top:8px;padding:10px 28px;background:var(--accent-cyan);color:#000;
  font-family:'Rajdhani',sans-serif;font-weight:700;font-size:14px;letter-spacing:.1em;
  text-transform:uppercase;border:none;border-radius:3px;cursor:pointer;
  transition:background .15s;
}
.btn-empty-new:hover{background:#00a8a8}

/* ─── DETAIL VIEW ─── */
.detail-view{flex:1;display:flex;flex-direction:column;overflow:hidden}

/* Bomb header banner */
.bomb-banner{
  padding:16px;border-bottom:1px solid var(--border-color);
  display:flex;align-items:center;gap:16px;flex-shrink:0;
  background:linear-gradient(90deg,var(--bg-card),var(--bg-panel));
}
.bomb-banner-icon{
  width:72px;height:72px;border-radius:5px;flex-shrink:0;
  display:flex;align-items:center;justify-content:center;font-size:36px;
  border:2px solid var(--border-accent);
}
.bomb-banner-info{flex:1;min-width:0}
.bomb-banner-name{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:clamp(18px,4vw,30px);color:#fff;line-height:1.1}
.bomb-banner-sub{font-size:12px;color:var(--text-secondary);margin-top:4px;line-height:1.5}
.bomb-banner-actions{display:flex;gap:8px;flex-wrap:wrap;align-items:flex-start}

.action-btn{
  font-family:'Rajdhani',sans-serif;font-weight:700;font-size:12px;letter-spacing:.08em;
  text-transform:uppercase;padding:7px 18px;border-radius:3px;cursor:pointer;
  border:1px solid transparent;transition:all var(--transition);white-space:nowrap;
}
.btn-spawn{background:var(--accent-green);color:#fff;border-color:var(--accent-green)}.btn-spawn:hover{background:#27ae60}
.btn-edit{background:var(--bg-card);border-color:var(--border-accent);color:var(--text-primary)}.btn-edit:hover{background:var(--accent-blue);border-color:var(--accent-blue-light)}
.btn-delete{background:var(--bg-card);border-color:rgba(231,76,60,.3);color:#e74c3c}.btn-delete:hover{background:var(--accent-red);color:#fff;border-color:var(--accent-red)}

/* Bomb stats grid */
.bomb-stats-grid{
  display:grid;grid-template-columns:repeat(auto-fill,minmax(180px,1fr));
  gap:10px;padding:14px 16px;border-bottom:1px solid var(--border-color);flex-shrink:0;
}
.stat-card{
  background:var(--bg-card);border:1px solid var(--border-color);border-radius:4px;
  padding:10px 12px;
}
.stat-label{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:10px;letter-spacing:.1em;text-transform:uppercase;color:var(--text-dim);margin-bottom:4px}
.stat-value{font-size:14px;font-weight:600;color:var(--text-primary)}
.stat-value.cyan{color:var(--accent-cyan)}
.stat-value.red{color:var(--accent-red)}
.stat-value.green{color:var(--accent-green)}
.stat-value.gold{color:var(--accent-gold)}
.stat-value.orange{color:var(--accent-orange)}

/* Config tables */
.detail-scroll{overflow-y:auto;flex:1;padding:16px}
.detail-scroll::-webkit-scrollbar{width:6px}
.detail-scroll::-webkit-scrollbar-track{background:var(--bg-dark)}
.detail-scroll::-webkit-scrollbar-thumb{background:var(--border-accent);border-radius:3px}

.detail-section{border:1px solid var(--border-color);border-radius:4px;margin-bottom:14px;overflow:hidden}
.detail-section-hdr{
  padding:9px 12px;background:var(--bg-card);font-family:'Rajdhani',sans-serif;
  font-weight:700;font-size:11px;letter-spacing:.1em;text-transform:uppercase;
  color:var(--text-secondary);border-bottom:1px solid var(--border-color);
  display:flex;align-items:center;gap:8px;
}
.detail-section-hdr .ds-icon{font-size:13px}
.detail-kv{padding:8px 12px;border-bottom:1px solid rgba(37,45,69,.5);display:flex;align-items:center;gap:10px;font-size:12px}
.detail-kv:last-child{border-bottom:none}
.dk{color:var(--text-secondary);flex:0 0 160px;font-weight:600}
.dv{color:var(--text-primary);flex:1}
.dv-tag{display:inline-block;padding:2px 8px;border-radius:2px;font-size:11px;font-family:'Rajdhani',sans-serif;font-weight:700;background:rgba(0,207,207,.1);border:1px solid rgba(0,207,207,.2);color:var(--accent-cyan)}

/* ─── FORM (CREATE / EDIT) ─── */
.form-view{flex:1;display:flex;flex-direction:column;overflow:hidden}
.form-hdr{
  padding:14px 16px;border-bottom:1px solid var(--border-color);
  display:flex;align-items:center;gap:12px;flex-shrink:0;
  background:linear-gradient(90deg,var(--bg-card),var(--bg-panel));
}
.form-hdr-title{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:20px;color:#fff}
.form-hdr-sub{font-size:12px;color:var(--text-dim);margin-top:2px}
.form-scroll{overflow-y:auto;flex:1;padding:16px}
.form-scroll::-webkit-scrollbar{width:6px}
.form-scroll::-webkit-scrollbar-track{background:var(--bg-dark)}
.form-scroll::-webkit-scrollbar-thumb{background:var(--border-accent);border-radius:3px}

.form-section{border:1px solid var(--border-color);border-radius:4px;margin-bottom:14px;overflow:hidden}
.form-section-hdr{
  padding:9px 12px;background:var(--bg-card);font-family:'Rajdhani',sans-serif;
  font-weight:700;font-size:11px;letter-spacing:.1em;text-transform:uppercase;
  color:var(--accent-cyan);border-bottom:1px solid var(--border-color);
  display:flex;align-items:center;gap:8px;cursor:pointer;user-select:none;
}
.form-section-hdr .fs-arr{margin-left:auto;font-size:10px;transition:transform .15s;color:var(--text-dim)}
.form-section-hdr.open .fs-arr{transform:rotate(90deg);color:var(--accent-cyan)}
.form-section-body{padding:14px;display:none}
.form-section-body.open{display:block}

.frow{display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:12px}
.frow.full{grid-template-columns:1fr}
.frow.trio{grid-template-columns:1fr 1fr 1fr}
.frow.quad{grid-template-columns:1fr 1fr 1fr 1fr}

.ffield{display:flex;flex-direction:column;gap:5px}
.ffield label{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:10px;letter-spacing:.1em;text-transform:uppercase;color:var(--text-secondary)}
.ffield .hint{font-size:10px;color:var(--text-dim);line-height:1.4}
.finput{
  background:var(--bg-dark);border:1px solid var(--border-color);color:var(--text-primary);
  font-family:'Exo 2',sans-serif;font-size:13px;padding:8px 10px;outline:none;
  border-radius:3px;width:100%;transition:border-color var(--transition);
}
.finput:focus{border-color:var(--accent-cyan)}
select.finput{cursor:pointer} select.finput option{background:#111420}

/* Type selector */
.type-selector{display:flex;gap:8px;flex-wrap:wrap}
.type-card{
  flex:1;min-width:120px;padding:12px 10px;border:2px solid var(--border-color);
  border-radius:4px;background:var(--bg-card);cursor:pointer;text-align:center;
  transition:all .15s;
}
.type-card:hover{border-color:var(--text-dim)}
.type-card.selected-explosive{border-color:#e74c3c;background:rgba(231,76,60,.1)}
.type-card.selected-training{border-color:var(--accent-blue);background:rgba(30,110,200,.1)}
.type-card.selected-gas{border-color:#2ecc71;background:rgba(46,204,113,.1)}
.type-card-icon{font-size:28px;margin-bottom:6px}
.type-card-label{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:12px;letter-spacing:.06em;text-transform:uppercase}

/* Minigame selector */
.minigame-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:8px}
.mg-card{
  padding:10px 8px;border:1px solid var(--border-color);border-radius:4px;
  background:var(--bg-card);cursor:pointer;text-align:center;transition:all .15s;
}
.mg-card:hover{border-color:var(--text-dim);background:var(--bg-hover)}
.mg-card.selected{border-color:var(--accent-cyan);background:rgba(0,207,207,.1)}
.mg-card.selected .mg-name{color:var(--accent-cyan)}
.mg-icon{font-size:22px;margin-bottom:5px}
.mg-name{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:11px;letter-spacing:.04em;text-transform:uppercase;color:var(--text-secondary)}
.mg-desc{font-size:10px;color:var(--text-dim);margin-top:3px;line-height:1.3}

/* Toggle switch */
.toggle-row{display:flex;align-items:center;justify-content:space-between;padding:10px 0;border-bottom:1px solid rgba(37,45,69,.4)}
.toggle-row:last-child{border-bottom:none}
.toggle-info .tl{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:13px;color:var(--text-primary)}
.toggle-info .ts{font-size:11px;color:var(--text-dim);margin-top:2px}
.toggle{position:relative;display:inline-block;width:44px;height:24px;flex-shrink:0}
.toggle input{opacity:0;width:0;height:0}
.toggle-slider{
  position:absolute;inset:0;background:#1c2540;border:1px solid var(--border-color);
  border-radius:24px;cursor:pointer;transition:.2s;
}
.toggle-slider::before{
  content:'';position:absolute;width:16px;height:16px;border-radius:50%;
  left:3px;top:3px;background:var(--text-dim);transition:.2s;
}
.toggle input:checked + .toggle-slider{background:rgba(0,207,207,.2);border-color:var(--accent-cyan)}
.toggle input:checked + .toggle-slider::before{transform:translateX(20px);background:var(--accent-cyan)}

/* Conditional fields */
.cond-field{padding:10px;border:1px dashed rgba(240,192,64,.3);border-radius:3px;background:rgba(240,192,64,.04);margin-top:8px}
.cond-label{font-size:10px;color:var(--accent-gold);font-family:'Rajdhani',sans-serif;font-weight:700;letter-spacing:.08em;text-transform:uppercase;margin-bottom:8px}

/* Effect tags */
.effect-tags{display:flex;flex-wrap:wrap;gap:6px;margin-top:4px}
.effect-tag{
  padding:4px 10px;border-radius:3px;font-size:11px;font-family:'Rajdhani',sans-serif;
  font-weight:700;cursor:pointer;border:1px solid var(--border-color);
  background:var(--bg-dark);color:var(--text-secondary);transition:all .15s;
}
.effect-tag:hover{border-color:var(--text-dim);color:var(--text-primary)}
.effect-tag.sel{background:rgba(230,126,34,.15);border-color:rgba(230,126,34,.5);color:var(--accent-orange)}

/* Form actions */
.form-actions{
  padding:12px 16px;border-top:1px solid var(--border-color);flex-shrink:0;
  display:flex;gap:8px;background:var(--bg-panel);
}
.btn-save{
  padding:9px 28px;background:var(--accent-green);color:#fff;
  font-family:'Rajdhani',sans-serif;font-weight:700;font-size:13px;letter-spacing:.1em;
  text-transform:uppercase;border:none;border-radius:3px;cursor:pointer;transition:background .15s;
}
.btn-save:hover{background:#27ae60}
.btn-cancel{
  padding:9px 20px;background:var(--bg-card);border:1px solid var(--border-accent);
  color:var(--text-primary);font-family:'Rajdhani',sans-serif;font-weight:700;font-size:13px;
  letter-spacing:.08em;text-transform:uppercase;border-radius:3px;cursor:pointer;
  transition:all .15s;
}
.btn-cancel:hover{background:var(--bg-hover)}
.btn-delete-form{
  margin-left:auto;padding:9px 20px;background:transparent;
  border:1px solid rgba(231,76,60,.35);color:#e74c3c;
  font-family:'Rajdhani',sans-serif;font-weight:700;font-size:13px;letter-spacing:.08em;
  text-transform:uppercase;border-radius:3px;cursor:pointer;transition:all .15s;
}
.btn-delete-form:hover{background:var(--accent-red);border-color:var(--accent-red);color:#fff}

/* ─── LANG MODAL ─── */
.lang-modal-overlay{display:none;position:absolute;inset:0;background:rgba(0,0,0,.7);z-index:300;align-items:center;justify-content:center}
.lang-modal-overlay.visible{display:flex}
.lang-modal{background:var(--bg-panel);border:1px solid var(--border-accent);border-radius:6px;width:340px;overflow:hidden;box-shadow:0 20px 80px rgba(0,0,0,.9)}
.lang-modal-hdr{padding:14px 16px;background:linear-gradient(90deg,#0d1525,#121b30);border-bottom:1px solid var(--border-accent);display:flex;align-items:center;justify-content:space-between}
.lang-modal-hdr h3{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:16px;color:#fff;letter-spacing:.06em}
.lang-close{background:transparent;border:none;color:var(--text-dim);cursor:pointer;font-size:16px;transition:color .15s}
.lang-close:hover{color:#e74c3c}
.lang-list{padding:10px}
.lang-item{display:flex;align-items:center;gap:12px;padding:10px 12px;border-radius:4px;cursor:pointer;transition:background .15s;border:1px solid transparent;margin-bottom:6px}
.lang-item:hover{background:var(--bg-hover);border-color:var(--border-color)}
.lang-item.active{background:rgba(30,110,200,.12);border-color:var(--accent-blue-light)}
.lang-flag{font-size:22px;line-height:1;flex-shrink:0}
.lang-info{flex:1}
.lang-name{font-family:'Rajdhani',sans-serif;font-weight:700;font-size:14px;color:var(--text-primary)}
.lang-native{font-size:11px;color:var(--text-dim)}
.lang-badge{font-size:10px;padding:2px 7px;border-radius:2px;font-family:'Rajdhani',sans-serif;font-weight:700;letter-spacing:.06em}
.lang-badge.default-badge{background:rgba(46,204,113,.15);color:var(--accent-green);border:1px solid rgba(46,204,113,.3)}
.lang-badge.active-badge{background:rgba(30,110,200,.2);color:var(--accent-blue-light);border:1px solid rgba(30,110,200,.4)}

/* ─── CONFIRM MODAL ─── */
.confirm-overlay{display:none;position:absolute;inset:0;background:rgba(0,0,0,.75);z-index:400;align-items:center;justify-content:center}
.confirm-overlay.visible{display:flex}
.confirm-box{background:var(--bg-panel);border:1px solid rgba(231,76,60,.4);border-radius:4px;padding:24px;max-width:380px;width:92%;text-align:center;box-shadow:0 20px 80px rgba(0,0,0,.9)}
.confirm-box h3{font-family:'Rajdhani',sans-serif;font-size:20px;font-weight:700;color:#fff;margin-bottom:6px}
.confirm-box p{font-size:13px;color:var(--text-secondary);margin-bottom:20px;line-height:1.5}
.confirm-btns{display:flex;gap:8px;justify-content:center}

/* ─── SPAWN MODAL ─── */
.spawn-overlay{display:none;position:absolute;inset:0;background:rgba(0,0,0,.75);z-index:400;align-items:center;justify-content:center}
.spawn-overlay.visible{display:flex}
.spawn-box{background:var(--bg-panel);border:1px solid rgba(46,204,113,.35);border-radius:4px;padding:24px;max-width:420px;width:92%;text-align:center;box-shadow:0 20px 80px rgba(0,0,0,.9)}
.spawn-box h3{font-family:'Rajdhani',sans-serif;font-size:22px;font-weight:700;color:#fff;margin-bottom:6px}
.spawn-icon{font-size:48px;margin-bottom:10px}
.spawn-detail{background:var(--bg-card);border:1px solid var(--border-color);border-radius:4px;padding:12px;margin:12px 0;text-align:left}
.spawn-kv{display:flex;justify-content:space-between;padding:4px 0;font-size:12px;border-bottom:1px solid rgba(37,45,69,.4)}
.spawn-kv:last-child{border-bottom:none}
.spawn-k{color:var(--text-dim)}
.spawn-v{color:var(--text-primary);font-weight:600}
.spawn-success-msg{font-size:12px;color:var(--accent-green);margin-top:8px;display:none}

/* ─── TOAST ─── */
.toast{position:absolute;bottom:16px;left:50%;transform:translateX(-50%) translateY(16px);background:var(--bg-hover);border:1px solid var(--border-accent);border-radius:4px;padding:9px 18px;font-size:13px;font-family:'Rajdhani',sans-serif;font-weight:600;color:#fff;opacity:0;transition:all .3s;pointer-events:none;white-space:nowrap;z-index:500}
.toast.show{opacity:1;transform:translateX(-50%) translateY(0)}
.toast.success{border-color:var(--accent-green);color:var(--accent-green)}
.toast.warn{border-color:var(--accent-orange);color:var(--accent-orange)}
.toast.error{border-color:var(--accent-red);color:var(--accent-red)}

/* No bombs state in sidebar */
.no-bombs{padding:20px 12px;text-align:center;font-size:12px;color:var(--text-dim);line-height:1.6}

/* Scrollbars */
::-webkit-scrollbar{width:6px}
::-webkit-scrollbar-track{background:var(--bg-dark)}
::-webkit-scrollbar-thumb{background:var(--border-accent);border-radius:3px}

/* ─── RESPONSIVE ─── */
@media(max-width:760px){
  .gmod-window{width:100vw;height:100vh;border:none}
  .sidebar{width:220px}
  .frow{grid-template-columns:1fr}
  .frow.trio,.frow.quad{grid-template-columns:1fr 1fr}
  .bomb-banner{flex-wrap:wrap}
  .bomb-banner-actions{width:100%}
  .bomb-stats-grid{grid-template-columns:1fr 1fr}
}
@media(max-width:560px){
  .main-layout{flex-direction:column}
  .sidebar{width:100%;height:200px;border-right:none;border-bottom:1px solid var(--border-color)}
  .sidebar-list{display:flex;overflow-x:auto;overflow-y:hidden;flex-direction:row}
  .cat-header{display:none}
  .bomb-item{min-width:180px;border-bottom:none;border-right:1px solid rgba(37,45,69,.5)}
  .frow.trio,.frow.quad{grid-template-columns:1fr}
}
</style>
</head>
<body>

<div class="gmod-window" id="app">

  <!-- TITLE BAR -->
  <div class="title-bar">
    <span class="server-name" data-i18n="server_name">GRN| BOMB CREATOR</span>
    <span class="sep">|</span>
    <span class="breadcrumb" id="breadcrumb"><span data-i18n="bc_manage">Manage</span> » <span data-i18n="bc_bombs">Bombs</span></span>
    <button class="lang-btn" id="langToggleBtn" onclick="openLang()">🌐 <span id="langLabel">EN</span></button>
    <button class="win-btn close" onclick="closeApp()">✕</button>
  </div>

  <!-- MAIN LAYOUT -->
  <div class="main-layout">

    <!-- SIDEBAR -->
    <div class="sidebar">
      <div class="sidebar-hdr">
        <span class="sidebar-hdr-title" data-i18n="sb_title">Bomb List</span>
        <button class="btn-new" onclick="showCreate()" data-i18n="sb_new">+ New</button>
      </div>
      <div class="sidebar-search">
        <input type="text" id="searchInput" placeholder="Search bombs..." oninput="filterBombs()" data-i18n-ph="search_ph">
      </div>
      <div class="sidebar-list" id="sidebarList"></div>
    </div>

    <!-- MAIN CONTENT -->
    <div class="main-content" id="mainContent">

      <!-- EMPTY STATE -->
      <div class="empty-state" id="emptyState">
        <div class="empty-icon">💣</div>
        <div class="empty-title" data-i18n="empty_title">No Bomb Selected</div>
        <div class="empty-sub" data-i18n="empty_sub">Select a bomb from the list or create a new one to get started.</div>
        <button class="btn-empty-new" onclick="showCreate()" data-i18n="empty_btn">Create First Bomb</button>
      </div>

      <!-- DETAIL VIEW -->
      <div class="detail-view" id="detailView" style="display:none">
        <div class="bomb-banner" id="detailBanner"></div>
        <div class="bomb-stats-grid" id="detailStats"></div>
        <div class="detail-scroll" id="detailScroll"></div>
      </div>

      <!-- FORM VIEW -->
      <div class="form-view" id="formView" style="display:none;flex-direction:column">
        <div class="form-hdr">
          <div>
            <div class="form-hdr-title" id="formTitle" data-i18n="form_create">Create New Bomb</div>
            <div class="form-hdr-sub" id="formSub" data-i18n="form_sub">Fill in the configuration below and save.</div>
          </div>
        </div>
        <div class="form-scroll">

          <!-- SECTION: Basic Info -->
          <div class="form-section">
            <div class="form-section-hdr open" onclick="toggleSection(this)" data-i18n="fs_basic">
              📋 Basic Information <span class="fs-arr">▶</span>
            </div>
            <div class="form-section-body open">
              <div class="frow">
                <div class="ffield">
                  <label data-i18n="fl_name">Bomb Name</label>
                  <input class="finput" type="text" id="f_name" placeholder="e.g. IED Mk.I" data-i18n-ph="fp_name">
                </div>
                <div class="ffield">
                  <label data-i18n="fl_category">Category</label>
                  <input class="finput" type="text" id="f_category" placeholder="e.g. Explosive, Training..." data-i18n-ph="fp_cat">
                  <span class="hint" data-i18n="fh_cat">Used to group bombs in the list</span>
                </div>
              </div>
              <div class="frow full" style="margin-bottom:6px">
                <div class="ffield">
                  <label data-i18n="fl_type">Bomb Type</label>
                  <div class="type-selector" id="typeSel">
                    <div class="type-card" data-type="explosive" onclick="selectType('explosive')">
                      <div class="type-card-icon">💥</div>
                      <div class="type-card-label" data-i18n="t_explosive">Explosive</div>
                    </div>
                    <div class="type-card" data-type="training" onclick="selectType('training')">
                      <div class="type-card-icon">🎓</div>
                      <div class="type-card-label" data-i18n="t_training">Training</div>
                    </div>
                    <div class="type-card" data-type="gas" onclick="selectType('gas')">
                      <div class="type-card-icon">☠️</div>
                      <div class="type-card-label" data-i18n="t_gas">Gas</div>
                    </div>
                  </div>
                </div>
              </div>
              <div class="frow">
                <div class="ffield">
                  <label data-i18n="fl_model">Bomb Model</label>
                  <select class="finput" id="f_model">
                    <option value="models/props_c17/oildrum001a.mdl">Oil Drum</option>
                    <option value="models/props_combine/combine_mine01.mdl">Combine Mine</option>
                    <option value="models/props_junk/explosive_barrel001a.mdl">Explosive Barrel</option>
                    <option value="models/props_phx/misc/ied.mdl">IED Device</option>
                    <option value="models/props_lab/jar01a.mdl">Gas Canister</option>
                    <option value="models/Gibs/HGIBS.mdl">Training Package</option>
                    <option value="models/props_c17/oildrum001a.mdl">Pipe Bomb</option>
                    <option value="custom">Custom...</option>
                  </select>
                </div>
                <div class="ffield">
                  <label data-i18n="fl_model_custom">Custom Model Path</label>
                  <input class="finput" type="text" id="f_model_custom" placeholder="models/your/model.mdl" data-i18n-ph="fp_model_custom">
                  <span class="hint" data-i18n="fh_model_custom">Only if "Custom..." is selected above</span>
                </div>
              </div>
            </div>
          </div>

          <!-- SECTION: Minigame -->
          <div class="form-section">
            <div class="form-section-hdr open" onclick="toggleSection(this)" data-i18n="fs_minigame">
              🎮 Defusal Minigame (E key) <span class="fs-arr">▶</span>
            </div>
            <div class="form-section-body open">
              <div class="ffield" style="margin-bottom:10px">
                <label data-i18n="fl_minigame">Select Minigame Type</label>
                <span class="hint" data-i18n="fh_minigame">Player interacts with the bomb by pressing E. The selected minigame will appear.</span>
              </div>
              <div class="minigame-grid" id="minigameGrid">
                <div class="mg-card" data-mg="wirecutting" onclick="selectMinigame('wirecutting')">
                  <div class="mg-icon">✂️</div>
                  <div class="mg-name" data-i18n="mg_wire">Wire Cutting</div>
                  <div class="mg-desc" data-i18n="mg_wire_d">Cut the correct wire</div>
                </div>
                <div class="mg-card" data-mg="code" onclick="selectMinigame('code')">
                  <div class="mg-icon">🔢</div>
                  <div class="mg-name" data-i18n="mg_code">Code Input</div>
                  <div class="mg-desc" data-i18n="mg_code_d">Enter numeric code</div>
                </div>
                <div class="mg-card" data-mg="sequence" onclick="selectMinigame('sequence')">
                  <div class="mg-icon">🔀</div>
                  <div class="mg-name" data-i18n="mg_seq">Sequence</div>
                  <div class="mg-desc" data-i18n="mg_seq_d">Repeat button sequence</div>
                </div>
                <div class="mg-card" data-mg="hackpad" onclick="selectMinigame('hackpad')">
                  <div class="mg-icon">💻</div>
                  <div class="mg-name" data-i18n="mg_hack">Hack Pad</div>
                  <div class="mg-desc" data-i18n="mg_hack_d">Terminal hacking puzzle</div>
                </div>
                <div class="mg-card" data-mg="timer" onclick="selectMinigame('timer')">
                  <div class="mg-icon">⏱️</div>
                  <div class="mg-name" data-i18n="mg_timer">Timed Press</div>
                  <div class="mg-desc" data-i18n="mg_timer_d">Press at exact moment</div>
                </div>
                <div class="mg-card" data-mg="lockpick" onclick="selectMinigame('lockpick')">
                  <div class="mg-icon">🔓</div>
                  <div class="mg-name" data-i18n="mg_lock">Lockpick</div>
                  <div class="mg-desc" data-i18n="mg_lock_d">Pick the lock mechanism</div>
                </div>
                <div class="mg-card" data-mg="buttons" onclick="selectMinigame('buttons')">
                  <div class="mg-icon">🟥</div>
                  <div class="mg-name" data-i18n="mg_btn">Button Panel</div>
                  <div class="mg-desc" data-i18n="mg_btn_d">Press correct buttons</div>
                </div>
                <div class="mg-card" data-mg="custom" onclick="selectMinigame('custom')">
                  <div class="mg-icon">⚙️</div>
                  <div class="mg-name" data-i18n="mg_cust">Custom</div>
                  <div class="mg-desc" data-i18n="mg_cust_d">Custom Lua minigame</div>
                </div>
              </div>
              <div style="margin-top:12px" id="mgCustomField" style="display:none">
                <div class="frow">
                  <div class="ffield">
                    <label data-i18n="fl_difficulty">Difficulty</label>
                    <select class="finput" id="f_difficulty">
                      <option value="easy" data-i18n="diff_easy">Easy</option>
                      <option value="medium" selected data-i18n="diff_med">Medium</option>
                      <option value="hard" data-i18n="diff_hard">Hard</option>
                      <option value="expert" data-i18n="diff_exp">Expert</option>
                    </select>
                  </div>
                  <div class="ffield">
                    <label data-i18n="fl_timer">Defusal Timer (seconds)</label>
                    <input class="finput" type="number" id="f_timer" value="60" min="5" max="600">
                  </div>
                </div>
              </div>
              <div id="codeField" class="cond-field" style="display:none">
                <div class="cond-label" data-i18n="cl_code">🔐 Code Input Configuration</div>
                <div class="frow">
                  <div class="ffield">
                    <label data-i18n="fl_code_value">Defuse Code</label>
                    <input class="finput" type="text" id="f_code_value" maxlength="12" placeholder="7342" data-i18n-ph="fp_code_value">
                  </div>
                  <div class="ffield">
                    <label data-i18n="fl_code_hint">Hint Text</label>
                    <input class="finput" type="text" id="f_code_hint" maxlength="64" placeholder="4 digits" data-i18n-ph="fp_code_hint">
                    <span class="hint" data-i18n="fh_code_hint">Optional staff hint shown inside the minigame.</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- SECTION: Explosion -->
          <div class="form-section">
            <div class="form-section-hdr open" onclick="toggleSection(this)" data-i18n="fs_explosion">
              💥 Explosion Configuration <span class="fs-arr">▶</span>
            </div>
            <div class="form-section-body open">
              <div class="frow trio">
                <div class="ffield">
                  <label data-i18n="fl_radius">Explosion Radius</label>
                  <input class="finput" type="number" id="f_radius" value="300" min="10" max="5000" placeholder="300">
                  <span class="hint" data-i18n="fh_radius">Units (HU). Blast area.</span>
                </div>
                <div class="ffield">
                  <label data-i18n="fl_damage">Max Damage</label>
                  <input class="finput" type="number" id="f_damage" value="500" min="1" max="9999" placeholder="500">
                  <span class="hint" data-i18n="fh_damage">HP at center of blast</span>
                </div>
                <div class="ffield">
                  <label data-i18n="fl_force">Blast Force</label>
                  <input class="finput" type="number" id="f_force" value="800" min="0" max="9999" placeholder="800">
                  <span class="hint" data-i18n="fh_force">Physics push force</span>
                </div>
              </div>
              <div class="frow full">
                <div class="ffield">
                  <label data-i18n="fl_effect">Explosion Effect Entity</label>
                  <div class="effect-tags" id="effectTags">
                    <span class="effect-tag" data-ef="env_explosion" onclick="toggleEffect(this)">env_explosion</span>
                    <span class="effect-tag" data-ef="env_fire" onclick="toggleEffect(this)">env_fire</span>
                    <span class="effect-tag" data-ef="env_smokestack" onclick="toggleEffect(this)">env_smokestack</span>
                    <span class="effect-tag" data-ef="env_electricspark" onclick="toggleEffect(this)">env_electricspark</span>
                    <span class="effect-tag" data-ef="env_steam" onclick="toggleEffect(this)">env_steam</span>
                    <span class="effect-tag" data-ef="env_gunshot" onclick="toggleEffect(this)">env_gunshot</span>
                    <span class="effect-tag" data-ef="env_physexplosion" onclick="toggleEffect(this)">env_physexplosion</span>
                  </div>
                  <span class="hint" style="margin-top:5px;display:block" data-i18n="fh_effect">Multiple effects spawn as separate entities at explosion point</span>
                </div>
              </div>
              <div class="frow">
                <div class="ffield">
                  <label data-i18n="fl_particles">Particle Effect</label>
                  <select class="finput" id="f_particles">
                    <option value="explosion_huge">explosion_huge</option>
                    <option value="explosion_large_sparks">explosion_large_sparks</option>
                    <option value="smoke_exhaust">smoke_exhaust</option>
                    <option value="gas_leak">gas_leak</option>
                    <option value="fire_medium_01">fire_medium_01</option>
                    <option value="explosioncore_wall">explosioncore_wall</option>
                    <option value="none" data-i18n="p_none">None</option>
                  </select>
                </div>
                <div class="ffield">
                  <label data-i18n="fl_particle_count">Particle Count</label>
                  <input class="finput" type="number" id="f_particle_count" value="5" min="1" max="50">
                  <span class="hint" data-i18n="fh_particle_count">Entities spawned per particle effect</span>
                </div>
              </div>
            </div>
          </div>

          <!-- SECTION: Rewards & Restrictions -->
          <div class="form-section">
            <div class="form-section-hdr open" onclick="toggleSection(this)" data-i18n="fs_rewards">
              💰 Rewards &amp; Restrictions <span class="fs-arr">▶</span>
            </div>
            <div class="form-section-body open">
              <div class="toggle-row">
                <div class="toggle-info">
                  <div class="tl" data-i18n="tgl_money">Reward Money on Defusal</div>
                  <div class="ts" data-i18n="tgl_money_s">Player receives money when defusing the bomb</div>
                </div>
                <label class="toggle">
                  <input type="checkbox" id="f_reward_money" onchange="toggleMoneyField()">
                  <span class="toggle-slider"></span>
                </label>
              </div>
              <div id="moneyField" class="cond-field" style="display:none">
                <div class="cond-label" data-i18n="cl_money">💰 Money Reward Config</div>
                <div class="frow">
                  <div class="ffield">
                    <label data-i18n="fl_money_amt">Amount ($)</label>
                    <input class="finput" type="number" id="f_money_amt" value="500" min="0">
                  </div>
                  <div class="ffield">
                    <label data-i18n="fl_money_notify">Notification</label>
                    <select class="finput" id="f_money_notify">
                      <option value="chat" data-i18n="mn_chat">Chat Message</option>
                      <option value="hud" data-i18n="mn_hud">HUD Notification</option>
                      <option value="both" data-i18n="mn_both">Both</option>
                    </select>
                  </div>
                </div>
              </div>

              <div class="toggle-row">
                <div class="toggle-info">
                  <div class="tl" data-i18n="tgl_weapon">Require Specific Weapon</div>
                  <div class="ts" data-i18n="tgl_weapon_s">Player must have a specific weapon equipped to interact</div>
                </div>
                <label class="toggle">
                  <input type="checkbox" id="f_req_weapon" onchange="toggleWeaponField()">
                  <span class="toggle-slider"></span>
                </label>
              </div>
              <div id="weaponField" class="cond-field" style="display:none">
                <div class="cond-label" data-i18n="cl_weapon">🔫 Weapon Requirement</div>
                <div class="frow">
                  <div class="ffield">
                    <label data-i18n="fl_weapon_class">Weapon Class</label>
                    <input class="finput" type="text" id="f_weapon_class" placeholder="e.g. weapon_defibrillator" data-i18n-ph="fp_weapon">
                  </div>
                  <div class="ffield">
                    <label data-i18n="fl_weapon_msg">Fail Message</label>
                    <input class="finput" type="text" id="f_weapon_msg" placeholder="You need the defuse kit!" data-i18n-ph="fp_weapon_msg">
                  </div>
                </div>
              </div>

              <div class="toggle-row">
                <div class="toggle-info">
                  <div class="tl" data-i18n="tgl_visible">Visible to Everyone</div>
                  <div class="ts" data-i18n="tgl_visible_s">Bomb entity is visible to all players when spawned</div>
                </div>
                <label class="toggle">
                  <input type="checkbox" id="f_visible" checked>
                  <span class="toggle-slider"></span>
                </label>
              </div>

              <div class="toggle-row">
                <div class="toggle-info">
                  <div class="tl" data-i18n="tgl_beep">Beep Warning Sound</div>
                  <div class="ts" data-i18n="tgl_beep_s">Plays a ticking/beeping sound while active</div>
                </div>
                <label class="toggle">
                  <input type="checkbox" id="f_beep" checked>
                  <span class="toggle-slider"></span>
                </label>
              </div>

              <div class="toggle-row">
                <div class="toggle-info">
                  <div class="tl" data-i18n="tgl_glow">Glow Effect</div>
                  <div class="ts" data-i18n="tgl_glow_s">Adds a colored glow outline to the entity</div>
                </div>
                <label class="toggle">
                  <input type="checkbox" id="f_glow">
                  <span class="toggle-slider"></span>
                </label>
              </div>
            </div>
          </div>

        </div><!-- /form-scroll -->

        <div class="form-actions">
          <button class="btn-save" onclick="saveBomb()" data-i18n="btn_save">💾 Save Bomb</button>
          <button class="btn-cancel" onclick="cancelForm()" data-i18n="btn_cancel">Cancel</button>
          <button class="btn-delete-form" id="btnDeleteForm" onclick="confirmDelete()" style="display:none" data-i18n="btn_delete">🗑 Delete Bomb</button>
        </div>
      </div><!-- /formView -->

    </div><!-- /main-content -->
  </div><!-- /main-layout -->

  <!-- LANG MODAL -->
  <div class="lang-modal-overlay" id="langModal">
    <div class="lang-modal">
      <div class="lang-modal-hdr">
        <h3>🌐 Language / Idioma / Langue</h3>
        <button class="lang-close" onclick="closeLang()">✕</button>
      </div>
      <div class="lang-list">
        <div class="lang-item" data-lang="en" onclick="setLang('en')">
          <span class="lang-flag">🇺🇸</span>
          <div class="lang-info">
            <div class="lang-name">English</div>
            <div class="lang-native">English (United States)</div>
          </div>
          <span class="lang-badge default-badge">DEFAULT</span>
        </div>
        <div class="lang-item" data-lang="es" onclick="setLang('es')">
          <span class="lang-flag">🇪🇸</span>
          <div class="lang-info">
            <div class="lang-name">Español</div>
            <div class="lang-native">Spanish</div>
          </div>
        </div>
        <div class="lang-item" data-lang="fr" onclick="setLang('fr')">
          <span class="lang-flag">🇫🇷</span>
          <div class="lang-info">
            <div class="lang-name">Français</div>
            <div class="lang-native">French</div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- CONFIRM DELETE MODAL -->
  <div class="confirm-overlay" id="confirmModal">
    <div class="confirm-box">
      <h3 data-i18n="del_title">Delete Bomb?</h3>
      <p id="confirmMsg" data-i18n="del_msg">This bomb configuration will be permanently removed.</p>
      <div class="confirm-btns">
        <button class="action-btn btn-delete" onclick="doDelete()" data-i18n="del_confirm">Yes, Delete</button>
        <button class="action-btn" style="background:var(--bg-card);border:1px solid var(--border-accent)" onclick="closeConfirm()" data-i18n="del_cancel">Cancel</button>
      </div>
    </div>
  </div>

  <!-- SPAWN MODAL -->
  <div class="spawn-overlay" id="spawnModal">
    <div class="spawn-box">
      <div class="spawn-icon" id="spawnIcon">💣</div>
      <h3 id="spawnTitle" data-i18n="spawn_title">Spawning Bomb...</h3>
      <div class="spawn-detail" id="spawnDetail"></div>
      <p style="font-size:12px;color:var(--text-dim)" data-i18n="spawn_note">The bomb will be spawned at your crosshair position.</p>
      <div class="spawn-success-msg" id="spawnSuccessMsg" data-i18n="spawn_ok">✅ Bomb spawned successfully!</div>
      <div style="display:flex;gap:8px;justify-content:center;margin-top:14px">
        <button class="btn-save" onclick="doSpawn()" id="spawnBtn" data-i18n="spawn_confirm">Spawn</button>
        <button class="btn-cancel" onclick="closeSpawn()" data-i18n="spawn_cancel">Close</button>
      </div>
    </div>
  </div>

  <div class="toast" id="toast"></div>
</div>

<script>
// ═══════════════════════════════════════
// I18N DATA
// ═══════════════════════════════════════
const LANGS = {
  en: {
    server_name:'GRN| BOMB CREATOR', bc_manage:'Manage', bc_bombs:'Bombs',
    sb_title:'Bomb List', sb_new:'+ New', search_ph:'Search bombs...',
    empty_title:'No Bomb Selected', empty_sub:'Select a bomb from the list or create a new one to get started.',
    empty_btn:'Create First Bomb',
    form_create:'Create New Bomb', form_edit:'Edit Bomb', form_sub:'Fill in the configuration below and save.',
    fs_basic:'📋 Basic Information', fl_name:'Bomb Name', fp_name:'e.g. IED Mk.I',
    fl_category:'Category', fp_cat:'e.g. Explosive, Training...', fh_cat:'Used to group bombs in the list',
    fl_type:'Bomb Type', t_explosive:'Explosive', t_training:'Training', t_gas:'Gas',
    fl_model:'Bomb Model', fl_model_custom:'Custom Model Path', fp_model_custom:'models/your/model.mdl',
    fh_model_custom:'Only if "Custom..." is selected above',
    fs_minigame:'🎮 Defusal Minigame (E key)',
    fl_minigame:'Select Minigame Type', fh_minigame:'Player interacts with the bomb by pressing E.',
    mg_wire:'Wire Cutting', mg_wire_d:'Cut the correct wire',
    mg_code:'Code Input', mg_code_d:'Enter numeric code',
    mg_seq:'Sequence', mg_seq_d:'Repeat button sequence',
    mg_hack:'Hack Pad', mg_hack_d:'Terminal hacking puzzle',
    mg_timer:'Timed Press', mg_timer_d:'Press at exact moment',
    mg_lock:'Lockpick', mg_lock_d:'Pick the lock mechanism',
    mg_btn:'Button Panel', mg_btn_d:'Press correct buttons',
    mg_cust:'Custom', mg_cust_d:'Custom Lua minigame',
    fl_difficulty:'Difficulty', diff_easy:'Easy', diff_med:'Medium', diff_hard:'Hard', diff_exp:'Expert',
    fl_timer:'Defusal Timer (seconds)',
    cl_code:'🔐 Code Input Configuration', fl_code_value:'Defuse Code', fp_code_value:'e.g. 7342', fl_code_hint:'Hint Text', fp_code_hint:'e.g. 4 digits', fh_code_hint:'Optional staff hint shown inside the minigame.',
    fs_explosion:'💥 Explosion Configuration',
    fl_radius:'Explosion Radius', fh_radius:'Units (HU). Blast area.',
    fl_damage:'Max Damage', fh_damage:'HP at center of blast',
    fl_force:'Blast Force', fh_force:'Physics push force',
    fl_effect:'Explosion Effect Entity', fh_effect:'Multiple effects spawn as separate entities at explosion point',
    fl_particles:'Particle Effect', p_none:'None',
    fl_particle_count:'Particle Count', fh_particle_count:'Entities spawned per particle effect',
    fs_rewards:'💰 Rewards & Restrictions',
    tgl_money:'Reward Money on Defusal', tgl_money_s:'Player receives money when defusing the bomb',
    cl_money:'💰 Money Reward Config',
    fl_money_amt:'Amount ($)',
    fl_money_notify:'Notification', mn_chat:'Chat Message', mn_hud:'HUD Notification', mn_both:'Both',
    tgl_weapon:'Require Specific Weapon', tgl_weapon_s:'Player must have a specific weapon equipped to interact',
    cl_weapon:'🔫 Weapon Requirement',
    fl_weapon_class:'Weapon Class', fp_weapon:'e.g. weapon_defibrillator',
    fl_weapon_msg:'Fail Message', fp_weapon_msg:'You need the defuse kit!',
    tgl_visible:'Visible to Everyone', tgl_visible_s:'Bomb entity is visible to all players when spawned',
    tgl_beep:'Beep Warning Sound', tgl_beep_s:'Plays a ticking/beeping sound while active',
    tgl_glow:'Glow Effect', tgl_glow_s:'Adds a colored glow outline to the entity',
    btn_save:'💾 Save Bomb', btn_cancel:'Cancel', btn_delete:'🗑 Delete Bomb',
    del_title:'Delete Bomb?', del_msg:'This bomb configuration will be permanently removed.',
    del_confirm:'Yes, Delete', del_cancel:'Cancel',
    spawn_title:'Spawn Bomb', spawn_note:'The bomb will be spawned at your crosshair position.',
    spawn_ok:'✅ Bomb spawned successfully!', spawn_confirm:'Spawn', spawn_cancel:'Close',
    toast_saved:'Bomb saved!', toast_deleted:'Bomb deleted!', toast_spawned:'Spawned!', toast_no_sel:'No bomb selected.',
    toast_fill:'Please fill all required fields.',
    det_type:'Type', det_model:'Model', det_minigame:'Minigame', det_radius:'Radius',
    det_damage:'Damage', det_timer:'Timer', det_difficulty:'Difficulty', det_code:'Code',
    det_money:'Money Reward', det_weapon:'Required Weapon', det_effects:'Effects',
    det_particles:'Particles', det_category:'Category',
    btn_spawn:'▶ Spawn', btn_edit_det:'✏ Edit', btn_del_det:'🗑 Delete',
    no_bombs:'No bombs found.',
  },
  es: {
    server_name:'GRN| CREADOR DE BOMBAS', bc_manage:'Gestión', bc_bombs:'Bombas',
    sb_title:'Lista de Bombas', sb_new:'+ Nueva', search_ph:'Buscar bombas...',
    empty_title:'Sin Bomba Seleccionada', empty_sub:'Selecciona una bomba de la lista o crea una nueva para empezar.',
    empty_btn:'Crear Primera Bomba',
    form_create:'Crear Nueva Bomba', form_edit:'Editar Bomba', form_sub:'Completa la configuración y guarda.',
    fs_basic:'📋 Información Básica', fl_name:'Nombre de Bomba', fp_name:'ej. IED Mk.I',
    fl_category:'Categoría', fp_cat:'ej. Explosiva, Entrenamiento...', fh_cat:'Para agrupar bombas en la lista',
    fl_type:'Tipo de Bomba', t_explosive:'Explosiva', t_training:'Entrenamiento', t_gas:'Gas',
    fl_model:'Modelo de Bomba', fl_model_custom:'Ruta Modelo Personalizado', fp_model_custom:'models/tu/modelo.mdl',
    fh_model_custom:'Solo si se seleccionó "Personalizado..."',
    fs_minigame:'🎮 Minijuego de Desactivación (tecla E)',
    fl_minigame:'Seleccionar Tipo de Minijuego', fh_minigame:'El jugador interactúa con la bomba presionando E.',
    mg_wire:'Corte de Cable', mg_wire_d:'Corta el cable correcto',
    mg_code:'Código Numérico', mg_code_d:'Ingresa el código',
    mg_seq:'Secuencia', mg_seq_d:'Repite la secuencia',
    mg_hack:'Panel Hack', mg_hack_d:'Puzzle de hackeo terminal',
    mg_timer:'Presión Cronometrada', mg_timer_d:'Presiona en el momento exacto',
    mg_lock:'Ganzúa', mg_lock_d:'Fuerza el mecanismo',
    mg_btn:'Panel de Botones', mg_btn_d:'Presiona los botones correctos',
    mg_cust:'Personalizado', mg_cust_d:'Minijuego Lua personalizado',
    fl_difficulty:'Dificultad', diff_easy:'Fácil', diff_med:'Medio', diff_hard:'Difícil', diff_exp:'Experto',
    fl_timer:'Tiempo de Desactivación (seg)',
    cl_code:'🔐 Configuración de Código', fl_code_value:'Código de Desactivación', fp_code_value:'ej. 7342', fl_code_hint:'Texto de Pista', fp_code_hint:'ej. 4 dígitos', fh_code_hint:'Pista opcional visible dentro del minijuego.',
    fs_explosion:'💥 Configuración de Explosión',
    fl_radius:'Radio de Explosión', fh_radius:'Unidades (HU). Área de daño.',
    fl_damage:'Daño Máximo', fh_damage:'HP en el centro del blast',
    fl_force:'Fuerza de Onda', fh_force:'Fuerza de empuje físico',
    fl_effect:'Entidad de Efecto de Explosión', fh_effect:'Múltiples efectos se crean como entidades separadas',
    fl_particles:'Efecto de Partículas', p_none:'Ninguno',
    fl_particle_count:'Cantidad de Partículas', fh_particle_count:'Entidades por efecto de partícula',
    fs_rewards:'💰 Recompensas y Restricciones',
    tgl_money:'Recompensar Dinero al Desactivar', tgl_money_s:'El jugador recibe dinero al desactivar la bomba',
    cl_money:'💰 Configuración de Recompensa',
    fl_money_amt:'Monto ($)',
    fl_money_notify:'Notificación', mn_chat:'Mensaje de Chat', mn_hud:'Notificación HUD', mn_both:'Ambos',
    tgl_weapon:'Requiere Arma Específica', tgl_weapon_s:'El jugador debe tener un arma específica equipada',
    cl_weapon:'🔫 Requisito de Arma',
    fl_weapon_class:'Clase del Arma', fp_weapon:'ej. weapon_defibrillator',
    fl_weapon_msg:'Mensaje de Error', fp_weapon_msg:'¡Necesitas el kit de desactivación!',
    tgl_visible:'Visible para Todos', tgl_visible_s:'La entidad bomba es visible para todos al spawnearse',
    tgl_beep:'Sonido de Bip', tgl_beep_s:'Reproduce un pitido mientras está activa',
    tgl_glow:'Efecto de Brillo', tgl_glow_s:'Agrega contorno luminoso a la entidad',
    btn_save:'💾 Guardar Bomba', btn_cancel:'Cancelar', btn_delete:'🗑 Eliminar Bomba',
    del_title:'¿Eliminar Bomba?', del_msg:'Esta configuración será eliminada permanentemente.',
    del_confirm:'Sí, Eliminar', del_cancel:'Cancelar',
    spawn_title:'Spawnear Bomba', spawn_note:'La bomba se spawneará en la posición de tu mira.',
    spawn_ok:'✅ ¡Bomba spawneada exitosamente!', spawn_confirm:'Spawnear', spawn_cancel:'Cerrar',
    toast_saved:'¡Bomba guardada!', toast_deleted:'¡Bomba eliminada!', toast_spawned:'¡Spawneada!', toast_no_sel:'Sin bomba seleccionada.',
    toast_fill:'Por favor completa todos los campos requeridos.',
    det_type:'Tipo', det_model:'Modelo', det_minigame:'Minijuego', det_radius:'Radio',
    det_damage:'Daño', det_timer:'Tiempo', det_difficulty:'Dificultad', det_code:'Código',
    det_money:'Recompensa', det_weapon:'Arma Requerida', det_effects:'Efectos',
    det_particles:'Partículas', det_category:'Categoría',
    btn_spawn:'▶ Spawnear', btn_edit_det:'✏ Editar', btn_del_det:'🗑 Eliminar',
    no_bombs:'No se encontraron bombas.',
  },
  fr: {
    server_name:'GRN|CRÉATEUR DE BOMBES', bc_manage:'Gestion', bc_bombs:'Bombes',
    sb_title:'Liste des Bombes', sb_new:'+ Nouvelle', search_ph:'Rechercher...',
    empty_title:'Aucune Bombe Sélectionnée', empty_sub:'Sélectionnez une bombe dans la liste ou créez-en une nouvelle.',
    empty_btn:'Créer la Première Bombe',
    form_create:'Créer une Nouvelle Bombe', form_edit:'Modifier la Bombe', form_sub:'Remplissez la configuration ci-dessous et enregistrez.',
    fs_basic:'📋 Informations de Base', fl_name:'Nom de la Bombe', fp_name:'ex. IED Mk.I',
    fl_category:'Catégorie', fp_cat:'ex. Explosif, Entraînement...', fh_cat:'Pour regrouper les bombes dans la liste',
    fl_type:'Type de Bombe', t_explosive:'Explosive', t_training:'Entraînement', t_gas:'Gaz',
    fl_model:'Modèle de Bombe', fl_model_custom:'Chemin du Modèle Personnalisé', fp_model_custom:'models/votre/modele.mdl',
    fh_model_custom:'Seulement si "Personnalisé..." est sélectionné',
    fs_minigame:'🎮 Mini-jeu de Désamorçage (touche E)',
    fl_minigame:'Sélectionner le Type de Mini-jeu', fh_minigame:'Le joueur interagit avec la bombe en appuyant sur E.',
    mg_wire:'Coupe de Câble', mg_wire_d:'Couper le bon câble',
    mg_code:'Code Numérique', mg_code_d:'Entrer le code numérique',
    mg_seq:'Séquence', mg_seq_d:'Répéter la séquence de boutons',
    mg_hack:'Panneau Hack', mg_hack_d:'Puzzle de piratage terminal',
    mg_timer:'Pression Chronométrée', mg_timer_d:'Appuyer au bon moment',
    mg_lock:'Crochetage', mg_lock_d:'Crocheter le mécanisme',
    mg_btn:'Panneau de Boutons', mg_btn_d:'Appuyer sur les bons boutons',
    mg_cust:'Personnalisé', mg_cust_d:'Mini-jeu Lua personnalisé',
    fl_difficulty:'Difficulté', diff_easy:'Facile', diff_med:'Moyen', diff_hard:'Difficile', diff_exp:'Expert',
    fl_timer:'Minuterie de Désamorçage (sec)',
    cl_code:'🔐 Configuration du Code', fl_code_value:'Code de Désamorçage', fp_code_value:'ex. 7342', fl_code_hint:'Texte d\'Indice', fp_code_hint:'ex. 4 chiffres', fh_code_hint:'Indice optionnel affiché dans le mini-jeu.',
    fs_explosion:'💥 Configuration de l\'Explosion',
    fl_radius:'Rayon d\'Explosion', fh_radius:'Unités (HU). Zone de blast.',
    fl_damage:'Dégâts Max', fh_damage:'PV au centre du blast',
    fl_force:'Force de Blast', fh_force:'Force de poussée physique',
    fl_effect:'Entité d\'Effet d\'Explosion', fh_effect:'Plusieurs effets spawned comme entités séparées',
    fl_particles:'Effet de Particules', p_none:'Aucun',
    fl_particle_count:'Nombre de Particules', fh_particle_count:'Entités par effet de particule',
    fs_rewards:'💰 Récompenses & Restrictions',
    tgl_money:'Récompenser l\'Argent au Désamorçage', tgl_money_s:'Le joueur reçoit de l\'argent en désamorçant',
    cl_money:'💰 Config de Récompense',
    fl_money_amt:'Montant ($)',
    fl_money_notify:'Notification', mn_chat:'Message Chat', mn_hud:'Notification HUD', mn_both:'Les deux',
    tgl_weapon:'Arme Spécifique Requise', tgl_weapon_s:'Le joueur doit avoir une arme spécifique équipée',
    cl_weapon:'🔫 Exigence d\'Arme',
    fl_weapon_class:'Classe d\'Arme', fp_weapon:'ex. weapon_defibrillator',
    fl_weapon_msg:'Message d\'Échec', fp_weapon_msg:'Vous avez besoin du kit de désamorçage!',
    tgl_visible:'Visible par Tous', tgl_visible_s:'L\'entité bombe est visible pour tous',
    tgl_beep:'Son de Bip', tgl_beep_s:'Joue un bip pendant qu\'elle est active',
    tgl_glow:'Effet de Lueur', tgl_glow_s:'Ajoute un contour lumineux à l\'entité',
    btn_save:'💾 Sauvegarder', btn_cancel:'Annuler', btn_delete:'🗑 Supprimer',
    del_title:'Supprimer la Bombe?', del_msg:'Cette configuration sera supprimée définitivement.',
    del_confirm:'Oui, Supprimer', del_cancel:'Annuler',
    spawn_title:'Spawner la Bombe', spawn_note:'La bombe sera spawnée à la position de votre viseur.',
    spawn_ok:'✅ Bombe spawnée avec succès!', spawn_confirm:'Spawner', spawn_cancel:'Fermer',
    toast_saved:'Bombe sauvegardée!', toast_deleted:'Bombe supprimée!', toast_spawned:'Spawnée!', toast_no_sel:'Aucune bombe sélectionnée.',
    toast_fill:'Veuillez remplir tous les champs requis.',
    det_type:'Type', det_model:'Modèle', det_minigame:'Mini-jeu', det_radius:'Rayon',
    det_damage:'Dégâts', det_timer:'Minuterie', det_difficulty:'Difficulté', det_code:'Code',
    det_money:'Récompense', det_weapon:'Arme Requise', det_effects:'Effets',
    det_particles:'Particules', det_category:'Catégorie',
    btn_spawn:'▶ Spawner', btn_edit_det:'✏ Modifier', btn_del_det:'🗑 Supprimer',
    no_bombs:'Aucune bombe trouvée.',
  }
};

let currentLang = 'en';
function t(key){ return LANGS[currentLang][key] || LANGS.en[key] || key; }

function applyI18n(){
  document.querySelectorAll('[data-i18n]').forEach(el=>{
    const k = el.getAttribute('data-i18n');
    if(LANGS[currentLang][k]) el.textContent = LANGS[currentLang][k];
  });
  document.querySelectorAll('[data-i18n-ph]').forEach(el=>{
    const k = el.getAttribute('data-i18n-ph');
    if(LANGS[currentLang][k]) el.placeholder = LANGS[currentLang][k];
  });
  document.getElementById('langLabel').textContent = currentLang.toUpperCase();
  // update lang items
  document.querySelectorAll('.lang-item').forEach(el=>{
    el.classList.toggle('active', el.dataset.lang === currentLang);
    const badge = el.querySelector('.lang-badge');
    if(badge){
      if(el.dataset.lang === 'en'){
        badge.textContent = 'DEFAULT';
        badge.className = 'lang-badge default-badge';
      } else if(el.dataset.lang === currentLang){
        badge.textContent = 'ACTIVE';
        badge.className = 'lang-badge active-badge';
      } else {
        badge.textContent = '';
        badge.className = 'lang-badge';
      }
    }
  });
  renderSidebar();
  if(currentBombId !== null) renderDetail(currentBombId);
}

function setLang(l){ currentLang = l; applyI18n(); closeLang(); gmCall('SetLang', {lang:l}); }
function openLang(){ document.getElementById('langModal').classList.add('visible'); }
function closeLang(){ document.getElementById('langModal').classList.remove('visible'); }

// ═══════════════════════════════════════
// DATA
// ═══════════════════════════════════════
let bombs = [
  {
    id:1, name:'IED Mk.I', category:'Explosive', type:'explosive',
    model:'models/props_combine/combine_mine01.mdl', minigame:'wirecutting',
    difficulty:'hard', timer:60, radius:400, damage:600, force:900,
    effects:['env_explosion','env_fire'], particles:'explosion_huge', particleCount:5,
    rewardMoney:true, moneyAmt:750, moneyNotify:'both',
    reqWeapon:false, weaponClass:'', weaponMsg:'',
    visible:true, beep:true, glow:false
  },
  {
    id:2, name:'Training Package', category:'Training', type:'training',
    model:'models/Gibs/HGIBS.mdl', minigame:'code',
    difficulty:'easy', timer:120, radius:50, damage:10, force:50,
    effects:['env_steam'], particles:'smoke_exhaust', particleCount:2,
    rewardMoney:true, moneyAmt:200, moneyNotify:'chat',
    reqWeapon:true, weaponClass:'weapon_defibrillator', weaponMsg:'You need the defuse kit!',
    visible:true, beep:false, glow:true
  },
  {
    id:3, name:'Gas Canister X', category:'Chemical', type:'gas',
    model:'models/props_lab/jar01a.mdl', minigame:'hackpad',
    difficulty:'medium', timer:90, radius:600, damage:250, force:300,
    effects:['env_smokestack','env_steam'], particles:'gas_leak', particleCount:8,
    rewardMoney:false, moneyAmt:0, moneyNotify:'hud',
    reqWeapon:false, weaponClass:'', weaponMsg:'',
    visible:true, beep:true, glow:true
  }
];
let nextId = 4;
let currentBombId = null;
let editMode = false;

// ═══════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════
function getCategories(){
  const cats = {};
  bombs.forEach(b=>{
    const c = b.category || 'General';
    if(!cats[c]) cats[c] = [];
    cats[c].push(b);
  });
  return cats;
}

function typeIcon(t){
  return t==='explosive'?'💥':t==='training'?'🎓':'☠️';
}
function typeBadge(t){
  return `badge-${t}`;
}

const collapsedCats = new Set();

function renderSidebar(){
  const search = (document.getElementById('searchInput')?.value||'').toLowerCase();
  const list = document.getElementById('sidebarList');
  list.innerHTML = '';
  const cats = getCategories();
  let total = 0;
  Object.entries(cats).forEach(([cat,items])=>{
    const filtered = items.filter(b=> b.name.toLowerCase().includes(search) || cat.toLowerCase().includes(search));
    if(!filtered.length) return;
    total += filtered.length;

    const hdr = document.createElement('div');
    hdr.className = 'cat-header' + (collapsedCats.has(cat)?' collapsed':'');
    hdr.innerHTML = `<span>${cat}</span><span class="cat-count">${filtered.length}</span><span class="cat-arr">▼</span>`;
    hdr.onclick = ()=>{ collapsedCats.has(cat)?collapsedCats.delete(cat):collapsedCats.add(cat); renderSidebar(); };
    list.appendChild(hdr);

    if(!collapsedCats.has(cat)){
      filtered.forEach(b=>{
        const row = document.createElement('div');
        row.className = 'bomb-item' + (currentBombId===b.id?' active':'');
        row.innerHTML = `
          <div class="bi-icon type-${b.type}">${typeIcon(b.type)}</div>
          <div class="bi-info">
            <div class="bi-name">${b.name}</div>
            <div class="bi-meta">${b.minigame} · ${b.timer}s</div>
          </div>
          <span class="bi-badge ${typeBadge(b.type)}">${t('t_'+b.type)}</span>
        `;
        row.onclick = ()=>{ showDetail(b.id); };
        list.appendChild(row);
      });
    }
  });

  if(total===0){
    const empty = document.createElement('div');
    empty.className = 'no-bombs';
    empty.textContent = t('no_bombs');
    list.appendChild(empty);
  }
}

function filterBombs(){ renderSidebar(); }

// ═══════════════════════════════════════
// VIEWS
// ═══════════════════════════════════════
function showEmpty(){
  currentBombId = null;
  document.getElementById('emptyState').style.display = 'flex';
  document.getElementById('detailView').style.display = 'none';
  document.getElementById('formView').style.display = 'none';
  renderSidebar();
}

function showDetail(id){
  currentBombId = id;
  editMode = false;
  document.getElementById('emptyState').style.display = 'none';
  document.getElementById('detailView').style.display = 'flex';
  document.getElementById('formView').style.display = 'none';
  renderDetail(id);
  renderSidebar();
}

function renderDetail(id){
  const b = bombs.find(x=>x.id===id);
  if(!b) return;

  // Banner
  const iconClass = `type-${b.type}`;
  document.getElementById('detailBanner').innerHTML = `
    <div class="bomb-banner-icon ${iconClass}">${typeIcon(b.type)}</div>
    <div class="bomb-banner-info">
      <div class="bomb-banner-name">${b.name}</div>
      <div class="bomb-banner-sub">
        ${t('det_category')}: <strong>${b.category}</strong> &nbsp;·&nbsp;
        ${t('det_type')}: <strong>${t('t_'+b.type)}</strong> &nbsp;·&nbsp;
        ${t('det_minigame')}: <strong>${b.minigame}</strong>
      </div>
    </div>
    <div class="bomb-banner-actions">
      <button class="action-btn btn-spawn" onclick="openSpawn(${b.id})">${t('btn_spawn')}</button>
      <button class="action-btn btn-edit" onclick="showEdit(${b.id})">${t('btn_edit_det')}</button>
      <button class="action-btn btn-delete" onclick="confirmDelete()">${t('btn_del_det')}</button>
    </div>
  `;

  // Stats
  document.getElementById('detailStats').innerHTML = `
    <div class="stat-card">
      <div class="stat-label">${t('det_radius')}</div>
      <div class="stat-value red">${b.radius} HU</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">${t('det_damage')}</div>
      <div class="stat-value red">${b.damage} HP</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">${t('det_timer')}</div>
      <div class="stat-value cyan">${b.timer}s</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">${t('det_difficulty')}</div>
      <div class="stat-value gold">${t('diff_'+b.difficulty.replace('medium','med'))}</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">${t('det_money')}</div>
      <div class="stat-value green">${b.rewardMoney?'$'+b.moneyAmt:'—'}</div>
    </div>
    <div class="stat-card">
      <div class="stat-label">${t('det_weapon')}</div>
      <div class="stat-value orange">${b.reqWeapon?b.weaponClass:'—'}</div>
    </div>
  `;

  // Detail sections
  document.getElementById('detailScroll').innerHTML = `
    <div class="detail-section">
      <div class="detail-section-hdr"><span class="ds-icon">💥</span>${t('fs_explosion')}</div>
      <div class="detail-kv"><span class="dk">${t('det_radius')}</span><span class="dv">${b.radius} Hammer Units</span></div>
      <div class="detail-kv"><span class="dk">${t('det_damage')}</span><span class="dv">${b.damage} HP</span></div>
      <div class="detail-kv"><span class="dk">Force</span><span class="dv">${b.force}</span></div>
      <div class="detail-kv"><span class="dk">${t('det_effects')}</span><span class="dv">${b.effects.map(e=>`<span class="dv-tag">${e}</span>`).join(' ')}</span></div>
      <div class="detail-kv"><span class="dk">${t('det_particles')}</span><span class="dv">${b.particles} × ${b.particleCount}</span></div>
    </div>
    <div class="detail-section">
      <div class="detail-section-hdr"><span class="ds-icon">🎮</span>${t('fs_minigame')}</div>
      <div class="detail-kv"><span class="dk">${t('det_minigame')}</span><span class="dv">${b.minigame}</span></div>
      <div class="detail-kv"><span class="dk">${t('det_difficulty')}</span><span class="dv">${t('diff_'+b.difficulty.replace('medium','med'))}</span></div>
      <div class="detail-kv"><span class="dk">${t('det_timer')}</span><span class="dv">${b.timer}s</span></div>
      ${b.minigame==='code' ? `<div class="detail-kv"><span class="dk">${t('det_code')}</span><span class="dv">${b.codeValue||'7342'}</span></div>` : ''}
    </div>
    <div class="detail-section">
      <div class="detail-section-hdr"><span class="ds-icon">💰</span>${t('fs_rewards')}</div>
      <div class="detail-kv"><span class="dk">${t('tgl_money')}</span><span class="dv">${b.rewardMoney?'✅ $'+b.moneyAmt+' ('+b.moneyNotify+')':'❌'}</span></div>
      <div class="detail-kv"><span class="dk">${t('tgl_weapon')}</span><span class="dv">${b.reqWeapon?'✅ '+b.weaponClass:'❌'}</span></div>
      <div class="detail-kv"><span class="dk">${t('tgl_visible')}</span><span class="dv">${b.visible?'✅':'❌'}</span></div>
      <div class="detail-kv"><span class="dk">${t('tgl_beep')}</span><span class="dv">${b.beep?'✅':'❌'}</span></div>
      <div class="detail-kv"><span class="dk">${t('tgl_glow')}</span><span class="dv">${b.glow?'✅':'❌'}</span></div>
    </div>
    <div class="detail-section">
      <div class="detail-section-hdr"><span class="ds-icon">📦</span>${t('fl_model')}</div>
      <div class="detail-kv"><span class="dk">${t('fl_model')}</span><span class="dv" style="font-size:11px;font-family:monospace">${b.model}</span></div>
    </div>
  `;
}

// ═══════════════════════════════════════
// FORM
// ═══════════════════════════════════════
let selectedType = null;
let selectedMinigame = null;
let selectedEffects = [];

function showCreate(){
  editMode = false;
  currentBombId = null;
  selectedType = null; selectedMinigame = null; selectedEffects = [];
  clearForm();
  document.getElementById('formTitle').textContent = t('form_create');
  document.getElementById('formSub').textContent = t('form_sub');
  document.getElementById('btnDeleteForm').style.display = 'none';
  document.getElementById('emptyState').style.display = 'none';
  document.getElementById('detailView').style.display = 'none';
  document.getElementById('formView').style.display = 'flex';
  renderSidebar();
}

function showEdit(id){
  const b = bombs.find(x=>x.id===id);
  if(!b) return;
  editMode = true;
  currentBombId = id;
  selectedType = b.type;
  selectedMinigame = b.minigame;
  selectedEffects = [...b.effects];
  populateForm(b);
  document.getElementById('formTitle').textContent = t('form_edit');
  document.getElementById('formSub').textContent = b.name;
  document.getElementById('btnDeleteForm').style.display = 'block';
  document.getElementById('emptyState').style.display = 'none';
  document.getElementById('detailView').style.display = 'none';
  document.getElementById('formView').style.display = 'flex';
  renderSidebar();
}

function clearForm(){
  document.getElementById('f_name').value = '';
  document.getElementById('f_category').value = '';
  document.getElementById('f_model').value = 'models/props_c17/oildrum001a.mdl';
  document.getElementById('f_model_custom').value = '';
  document.getElementById('f_difficulty').value = 'medium';
  document.getElementById('f_timer').value = 60;
  document.getElementById('f_code_value').value = '7342';
  document.getElementById('f_code_hint').value = '';
  document.getElementById('f_radius').value = 300;
  document.getElementById('f_damage').value = 500;
  document.getElementById('f_force').value = 800;
  document.getElementById('f_particles').value = 'explosion_huge';
  document.getElementById('f_particle_count').value = 5;
  document.getElementById('f_reward_money').checked = false;
  document.getElementById('f_money_amt').value = 500;
  document.getElementById('f_money_notify').value = 'both';
  document.getElementById('f_req_weapon').checked = false;
  document.getElementById('f_weapon_class').value = '';
  document.getElementById('f_weapon_msg').value = '';
  document.getElementById('f_visible').checked = true;
  document.getElementById('f_beep').checked = true;
  document.getElementById('f_glow').checked = false;
  document.getElementById('moneyField').style.display = 'none';
  document.getElementById('weaponField').style.display = 'none';
  document.getElementById('codeField').style.display = 'none';
  // clear type sel
  document.querySelectorAll('.type-card').forEach(c=>c.className='type-card');
  // clear mg sel
  document.querySelectorAll('.mg-card').forEach(c=>c.classList.remove('selected'));
  // clear effects
  document.querySelectorAll('.effect-tag').forEach(t=>t.classList.remove('sel'));
}

function populateForm(b){
  document.getElementById('f_name').value = b.name;
  document.getElementById('f_category').value = b.category;
  document.getElementById('f_model').value = b.model;
  document.getElementById('f_model_custom').value = '';
  document.getElementById('f_difficulty').value = b.difficulty;
  document.getElementById('f_timer').value = b.timer;
  document.getElementById('f_code_value').value = b.codeValue || '7342';
  document.getElementById('f_code_hint').value = b.codeHint || '';
  document.getElementById('f_radius').value = b.radius;
  document.getElementById('f_damage').value = b.damage;
  document.getElementById('f_force').value = b.force;
  document.getElementById('f_particles').value = b.particles;
  document.getElementById('f_particle_count').value = b.particleCount;
  document.getElementById('f_reward_money').checked = b.rewardMoney;
  document.getElementById('f_money_amt').value = b.moneyAmt;
  document.getElementById('f_money_notify').value = b.moneyNotify;
  document.getElementById('f_req_weapon').checked = b.reqWeapon;
  document.getElementById('f_weapon_class').value = b.weaponClass;
  document.getElementById('f_weapon_msg').value = b.weaponMsg;
  document.getElementById('f_visible').checked = b.visible;
  document.getElementById('f_beep').checked = b.beep;
  document.getElementById('f_glow').checked = b.glow;
  document.getElementById('moneyField').style.display = b.rewardMoney?'block':'none';
  document.getElementById('weaponField').style.display = b.reqWeapon?'block':'none';
  document.getElementById('codeField').style.display = (b.minigame==='code'||b.minigame==='hackpad')?'block':'none';
  // type
  document.querySelectorAll('.type-card').forEach(c=>{
    c.className = 'type-card' + (c.dataset.type===b.type?' selected-'+b.type:'');
  });
  // mg
  document.querySelectorAll('.mg-card').forEach(c=>{
    c.classList.toggle('selected', c.dataset.mg===b.minigame);
  });
  // effects
  document.querySelectorAll('.effect-tag').forEach(tag=>{
    tag.classList.toggle('sel', b.effects.includes(tag.dataset.ef));
  });
}

function selectType(type){
  selectedType = type;
  document.querySelectorAll('.type-card').forEach(c=>{
    c.className = 'type-card' + (c.dataset.type===type?' selected-'+type:'');
  });
}

function selectMinigame(mg){
  selectedMinigame = mg;
  document.querySelectorAll('.mg-card').forEach(c=>{
    c.classList.toggle('selected', c.dataset.mg===mg);
  });
  document.getElementById('codeField').style.display = (mg==='code'||mg==='hackpad') ? 'block' : 'none';
}

function toggleEffect(el){
  const ef = el.dataset.ef;
  if(selectedEffects.includes(ef)){
    selectedEffects = selectedEffects.filter(e=>e!==ef);
    el.classList.remove('sel');
  } else {
    selectedEffects.push(ef);
    el.classList.add('sel');
  }
}

function toggleSection(hdr){
  hdr.classList.toggle('open');
  const body = hdr.nextElementSibling;
  if(body && body.classList.contains('form-section-body')){
    body.classList.toggle('open');
  }
}

function toggleMoneyField(){
  const chk = document.getElementById('f_reward_money').checked;
  document.getElementById('moneyField').style.display = chk?'block':'none';
}
function toggleWeaponField(){
  const chk = document.getElementById('f_req_weapon').checked;
  document.getElementById('weaponField').style.display = chk?'block':'none';
}

function saveBomb(){
  const name = document.getElementById('f_name').value.trim();
  const category = document.getElementById('f_category').value.trim() || 'General';
  if(!name){ showToast(t('toast_fill'),'warn'); return; }
  if(!selectedType){ showToast(t('toast_fill'),'warn'); return; }
  if(!selectedMinigame){ showToast(t('toast_fill'),'warn'); return; }

  const model = document.getElementById('f_model').value === 'custom'
    ? document.getElementById('f_model_custom').value.trim()
    : document.getElementById('f_model').value;

  const bomb = {
    id: editMode ? currentBombId : nextId++,
    name, category, type:selectedType, model, minigame:selectedMinigame,
    difficulty: document.getElementById('f_difficulty').value,
    timer: parseInt(document.getElementById('f_timer').value)||60,
    codeValue: document.getElementById('f_code_value').value.trim(),
    codeHint: document.getElementById('f_code_hint').value.trim(),
    radius: parseInt(document.getElementById('f_radius').value)||300,
    damage: parseInt(document.getElementById('f_damage').value)||500,
    force: parseInt(document.getElementById('f_force').value)||800,
    effects:[...selectedEffects],
    particles: document.getElementById('f_particles').value,
    particleCount: parseInt(document.getElementById('f_particle_count').value)||5,
    rewardMoney: document.getElementById('f_reward_money').checked,
    moneyAmt: parseInt(document.getElementById('f_money_amt').value)||0,
    moneyNotify: document.getElementById('f_money_notify').value,
    reqWeapon: document.getElementById('f_req_weapon').checked,
    weaponClass: document.getElementById('f_weapon_class').value.trim(),
    weaponMsg: document.getElementById('f_weapon_msg').value.trim(),
    visible: document.getElementById('f_visible').checked,
    beep: document.getElementById('f_beep').checked,
    glow: document.getElementById('f_glow').checked,
  };

  if(editMode){
    const idx = bombs.findIndex(b=>b.id===currentBombId);
    if(idx>=0) bombs[idx] = bomb;
  } else {
    bombs.push(bomb);
  }

  showToast(t('toast_saved'),'success');
  showDetail(bomb.id);
}

function cancelForm(){
  if(currentBombId !== null) showDetail(currentBombId);
  else showEmpty();
}

// ═══════════════════════════════════════
// DELETE
// ═══════════════════════════════════════
function confirmDelete(){
  document.getElementById('confirmModal').classList.add('visible');
}
function closeConfirm(){
  document.getElementById('confirmModal').classList.remove('visible');
}
function doDelete(){
  if(currentBombId===null) return;
  bombs = bombs.filter(b=>b.id!==currentBombId);
  closeConfirm();
  showToast(t('toast_deleted'),'warn');
  showEmpty();
}

// ═══════════════════════════════════════
// SPAWN
// ═══════════════════════════════════════
function openSpawn(id){
  const b = bombs.find(x=>x.id===id);
  if(!b){ showToast(t('toast_no_sel'),'error'); return; }
  currentBombId = id;
  document.getElementById('spawnIcon').textContent = typeIcon(b.type);
  document.getElementById('spawnTitle').textContent = t('spawn_title') + ': ' + b.name;
  document.getElementById('spawnDetail').innerHTML = `
    <div class="spawn-kv"><span class="spawn-k">${t('det_type')}</span><span class="spawn-v">${t('t_'+b.type)}</span></div>
    <div class="spawn-kv"><span class="spawn-k">${t('det_minigame')}</span><span class="spawn-v">${b.minigame}</span></div>
    <div class="spawn-kv"><span class="spawn-k">${t('det_radius')}</span><span class="spawn-v">${b.radius} HU</span></div>
    <div class="spawn-kv"><span class="spawn-k">${t('det_timer')}</span><span class="spawn-v">${b.timer}s</span></div>
    <div class="spawn-kv"><span class="spawn-k">${t('fl_model')}</span><span class="spawn-v" style="font-size:10px;font-family:monospace">${b.model}</span></div>
  `;
  document.getElementById('spawnSuccessMsg').style.display = 'none';
  document.getElementById('spawnBtn').disabled = false;
  document.getElementById('spawnModal').classList.add('visible');
}
function closeSpawn(){
  document.getElementById('spawnModal').classList.remove('visible');
}
function doSpawn(){
  document.getElementById('spawnBtn').disabled = true;
  document.getElementById('spawnSuccessMsg').style.display = 'block';
  showToast(t('toast_spawned'),'success');
  setTimeout(closeSpawn, 1500);
}

// ═══════════════════════════════════════
// TOAST
// ═══════════════════════════════════════
let toastTimer;
function showToast(msg, type=''){
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.className = 'toast show ' + type;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(()=>{ el.className = 'toast'; }, 2600);
}

// ═══════════════════════════════════════
// CLOSE APP
// ═══════════════════════════════════════
function closeApp(){
  document.getElementById('app').style.opacity='0';
  document.getElementById('app').style.transform='scale(0.97)';
  document.getElementById('app').style.transition='all .2s';
  setTimeout(()=>{ document.getElementById('app').style.display='none'; }, 200);
}

// ═══════════════════════════════════════
// INIT
// ═══════════════════════════════════════
window.onload = ()=>{
  applyI18n();
  renderSidebar();
};


// ===== GRN BOMBS LUA BRIDGE =====
function gmCall(name, payload){
  if (typeof gmod !== 'undefined' && gmod && gmod[name]) {
    gmod[name](JSON.stringify(payload || {}));
  }
}

function closeApp(){ gmCall('CloseMenu', {}); }

const __oldSaveBomb = saveBomb;
saveBomb = function(){
  const name = document.getElementById('f_name').value.trim();
  const category = document.getElementById('f_category').value.trim() || 'General';
  if(!name || !selectedType || !selectedMinigame){ showToast(t('toast_fill'),'warn'); return; }
  const model = document.getElementById('f_model').value === 'custom'
    ? document.getElementById('f_model_custom').value.trim()
    : document.getElementById('f_model').value;
  const payload = {
    id: editMode ? currentBombId : null,
    name: name,
    category: category,
    type: selectedType,
    model: model,
    minigame: selectedMinigame,
    difficulty: document.getElementById('f_difficulty').value,
    timer: parseInt(document.getElementById('f_timer').value)||60,
    codeValue: document.getElementById('f_code_value').value.trim(),
    codeHint: document.getElementById('f_code_hint').value.trim(),
    radius: parseInt(document.getElementById('f_radius').value)||300,
    damage: parseInt(document.getElementById('f_damage').value)||500,
    force: parseInt(document.getElementById('f_force').value)||800,
    effects: selectedEffects || [],
    particles: document.getElementById('f_particles').value,
    particleCount: parseInt(document.getElementById('f_particle_count').value)||5,
    rewardMoney: document.getElementById('f_reward_money').checked,
    moneyAmt: parseInt(document.getElementById('f_money_amt').value)||0,
    moneyNotify: document.getElementById('f_money_notify').value,
    reqWeapon: document.getElementById('f_req_weapon').checked,
    weaponClass: document.getElementById('f_weapon_class').value.trim(),
    weaponMsg: document.getElementById('f_weapon_msg').value.trim(),
    visible: document.getElementById('f_visible').checked,
    beep: document.getElementById('f_beep').checked,
    glow: document.getElementById('f_glow').checked
  };
  gmCall('SaveBomb', payload);
}

doDelete = function(){
  if(currentBombId===null) return;
  gmCall('DeleteBomb', {id: currentBombId});
  closeConfirm();
}

doSpawn = function(){
  if(currentBombId===null) return;
  gmCall('SpawnBomb', {id: currentBombId});
  document.getElementById('spawnSuccessMsg').style.display = 'block';
  document.getElementById('spawnBtn').disabled = true;
  showToast(t('toast_spawned'),'success');
}

window.receiveBombs = function(serverBombs){
  bombs = serverBombs || [];
  let maxId = 0;
  for(const b of bombs){ if((b.id||0) > maxId) maxId = b.id; }
  nextId = maxId + 1;
  currentBombId = null;
  renderSidebar();
  showEmpty();
}

window.onBombSaved = function(bomb){
  const idx = bombs.findIndex(x => x.id === bomb.id);
  if (idx >= 0) bombs[idx] = bomb; else bombs.push(bomb);
  nextId = Math.max(nextId, (bomb.id||0)+1);
  currentBombId = bomb.id;
  showToast(t('toast_saved'),'success');
  showDetail(bomb.id);
}

window.onBombDeleted = function(id){
  bombs = bombs.filter(x => x.id !== id);
  currentBombId = null;
  showToast(t('toast_deleted'),'warn');
  showEmpty();
}

window.openBombById = function(id){
  const b = bombs.find(x=>x.id===id);
  if(b) showDetail(id);
}

window.setCurrentLang = function(lang){
  if(!lang || !LANGS[lang]) return;
  currentLang = lang;
  applyI18n();
}

</script>
</body>
</html>
]]

-- SymChars-Design: Bombs-Variablen auf die SymChars-Palette legen (wird von cl_menu / cl_minigames angehängt)
GRN_Bombs.SymCSS = ":root{"
    .. "--bg-dark:var(--sy-bg);--bg-panel:var(--sy-panel);--bg-card:var(--sy-panel2);--bg-hover:var(--sy-panel3);"
    .. "--accent-blue:var(--sy-accent);--accent-blue-light:var(--sy-accent);--accent-gold:var(--sy-accent);"
    .. "--accent-red:var(--sy-red);--accent-green:var(--sy-green);"
    .. "--text-primary:var(--sy-text);--text-secondary:var(--sy-dim);--text-dim:var(--sy-muted);"
    .. "--border-color:var(--sy-line2);--border-accent:var(--sy-accent-dim)}"
    .. "body{font-family:var(--sy-body)}h1,h2,h3,.title,button{font-family:var(--sy-head);letter-spacing:.04em}"
