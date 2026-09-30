import React, { useState, useEffect } from 'react';
import Head from 'next/head';

interface LevelInfo {
  id: number;
  sector: string;
  puzzle: string;
  enemy: string;
  status: 'Launch Ready' | 'Expansion Pack 1' | 'Live-Ops';
}

export default function Home() {
  const [difficulty, setDifficulty] = useState<number>(0.33);
  const [installPrompt, setInstallPrompt] = useState<any>(null);
  const [overseerLogs, setOverseerLogs] = useState<string[]>([
    '[INIT] Stack frame established. Subterranean server labyrinth compiled.',
    '[EXPANSION] Sectors 01 through 40 verified on disk and loaded into stack.',
    '[OVERSEER] "Roxy, the nav-mesh doesn\'t even extend over there. Turn around and get back to the designated corridor before I delete your save file."',
    '[OVERSEER] "Are you trying to speed-run this? I haven\'t even finished rendering the next room. Slow down."',
    '[NOTICE] Impractical 90s outfit registered: Environmental hazard damage set to 0. Enemy melee damage active.',
    '[SYSTEM] Stamina sprint exhaustion system active. CRT phosphor glitch shader online.'
  ]);

  const getDifficultyTier = () => {
    if (difficulty < 0.25) return { name: 'Story', speed: 0.6, dmg: 0.5, cipher: 3, color: '#00e5ff' };
    if (difficulty < 0.60) return { name: 'Standard', speed: 1.0, dmg: 1.0, cipher: 4, color: '#00ff66' };
    if (difficulty < 0.85) return { name: 'Hardcore', speed: 1.4, dmg: 1.5, cipher: 5, color: '#ffb703' };
    return { name: 'Nightmare', speed: 2.0, dmg: 2.5, cipher: 7, color: '#ff3344' };
  };

  const tier = getDifficultyTier();

  useEffect(() => {
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      setInstallPrompt(e);
    });
  }, []);

  const handleInstallClick = () => {
    if (installPrompt) {
      installPrompt.prompt();
      installPrompt.userChoice.then(() => setInstallPrompt(null));
    }
  };

  // 40 Playable Sectors (Launch Day + Expansion Pack 1)
  const allPlayableLevels: LevelInfo[] = [
    { id: 1, sector: 'Subterranean BIOS Boot', puzzle: 'Memory Register 01', enemy: 'Glitch Walker α', status: 'Launch Ready' },
    { id: 2, sector: 'Corrupted Cache Trench', puzzle: 'Circuit Breaker Grid', enemy: 'Glitch Walker β', status: 'Launch Ready' },
    { id: 3, sector: 'Primary Bus Chasm', puzzle: 'Parity Check Purge', enemy: 'Glitch Walker α', status: 'Launch Ready' },
    { id: 4, sector: 'L1 Cache Labyrinth', puzzle: 'Hex Cipher Terminal', enemy: 'Dual Glitch Patrol', status: 'Launch Ready' },
    { id: 5, sector: 'Kernel Panic Chamber', puzzle: 'High Voltage Reroute', enemy: 'Wireframe Walker', status: 'Launch Ready' },
    { id: 6, sector: 'Deep Server Sub-Basement', puzzle: 'Coolant Flow Matrix', enemy: 'Glitch Walker γ', status: 'Launch Ready' },
    { id: 7, sector: 'Stack Overflow Vault', puzzle: 'Inverted Normal Defrag', enemy: 'Pulsating Walker', status: 'Launch Ready' },
    { id: 8, sector: 'Null Pointer Corridor', puzzle: 'Binary Gate Lock', enemy: 'Glitch Stalker', status: 'Launch Ready' },
    { id: 9, sector: 'Thread Lock Abyss', puzzle: 'Power Distribution', enemy: 'Wireframe Drone', status: 'Launch Ready' },
    { id: 10, sector: 'Clock Cycle Foundry', puzzle: 'Timed Parity Shift', enemy: 'Glitch Walker Prime', status: 'Launch Ready' },
    { id: 11, sector: 'DMA Controller Trench', puzzle: 'RAM Allocation Lock', enemy: 'Corrupted Walker', status: 'Launch Ready' },
    { id: 12, sector: 'Memory Leak Sump', puzzle: 'Leak Purge Valve', enemy: 'Swarm Walkers', status: 'Launch Ready' },
    { id: 13, sector: 'Floating Point Void', puzzle: 'Register Realignment', enemy: 'Void Walker', status: 'Launch Ready' },
    { id: 14, sector: 'Instruction Pipeline', puzzle: 'Opcode Cipher', enemy: 'Glitch Sentinel', status: 'Launch Ready' },
    { id: 15, sector: 'Interrupt Vector Cell', puzzle: 'Vector Relinking', enemy: 'Glitch Walker δ', status: 'Launch Ready' },
    { id: 16, sector: 'Thermal Throttling Spire', puzzle: 'Heat Sink Balancer', enemy: 'Thermal Glitch', status: 'Launch Ready' },
    { id: 17, sector: 'Garbage Collector Foundry', puzzle: 'Object Purge Matrix', enemy: 'Compactor Walker', status: 'Launch Ready' },
    { id: 18, sector: 'Segfault Catacombs', puzzle: 'Pointer Resolver', enemy: 'Triple Glitch Squad', status: 'Launch Ready' },
    { id: 19, sector: 'Hex Dump Sanctorum', puzzle: 'Master Breaker Grid', enemy: 'Sub-Routine Stalker', status: 'Launch Ready' },
    { id: 20, sector: 'Core Threshold Chamber', puzzle: 'Core Register Decrypt', enemy: 'Overseer Conduit', status: 'Launch Ready' },
    { id: 21, sector: 'High-Voltage Busbar Trench', puzzle: 'Busbar Synchronizer', enemy: 'Glitch Walker ε', status: 'Expansion Pack 1' },
    { id: 22, sector: 'Liquid Nitrogen Sump', puzzle: 'Cryo-Purge Keypad', enemy: 'Thermal Glitch II', status: 'Expansion Pack 1' },
    { id: 23, sector: 'Optical Fiber Chasm', puzzle: 'Laser Reflector Matrix', enemy: 'Wireframe Stalker', status: 'Expansion Pack 1' },
    { id: 24, sector: 'Core Parity Crypt', puzzle: 'Multi-Bit Parity Purge', enemy: 'Glitch Swarm β', status: 'Expansion Pack 1' },
    { id: 25, sector: 'Thermal Foundry Tier 2', puzzle: 'Heatsink Bypass Grid', enemy: 'Corrupted Drone', status: 'Expansion Pack 1' },
    { id: 26, sector: 'Async Event Loop Vault', puzzle: 'Event Queue Re-order', enemy: 'Glitch Walker Prime', status: 'Expansion Pack 1' },
    { id: 27, sector: 'Recursive Stack Siphon', puzzle: 'Recursion Depth Lock', enemy: 'Void Walker II', status: 'Expansion Pack 1' },
    { id: 28, sector: 'Zero-Day Exploit Cell', puzzle: 'Patch Verification Hex', enemy: 'Exploit Glitch', status: 'Expansion Pack 1' },
    { id: 29, sector: 'Corrupted Silicon Monolith', puzzle: 'Wafer Alignment Grid', enemy: 'Silicon Crawler', status: 'Expansion Pack 1' },
    { id: 30, sector: 'Overseer Sub-Core Gate', puzzle: 'Master Subroutine Decrypt', enemy: 'Overseer Sentinel', status: 'Expansion Pack 1' },
    { id: 31, sector: 'Microcode Execution Maze', puzzle: 'Instruction Re-decoder', enemy: 'Opcode Stalker', status: 'Expansion Pack 1' },
    { id: 32, sector: 'Branch Predictor Trench', puzzle: 'Speculative Branch Lock', enemy: 'Predictor Walker', status: 'Expansion Pack 1' },
    { id: 33, sector: 'TLB Cache Void', puzzle: 'Page Translation Matrix', enemy: 'Virtual Walker', status: 'Expansion Pack 1' },
    { id: 34, sector: 'Out-Of-Order Schedularium', puzzle: 'Dispatch Dependency Grid', enemy: 'Schedularium Drone', status: 'Expansion Pack 1' },
    { id: 35, sector: 'High-Frequency Clock Crypt', puzzle: 'Phase-Locked Loop Lock', enemy: 'Clock Jitter Walker', status: 'Expansion Pack 1' },
    { id: 36, sector: 'Bus Mastering Basin', puzzle: 'DMA Arbitration Matrix', enemy: 'Bus Master Glitch', status: 'Expansion Pack 1' },
    { id: 37, sector: 'Paging Table Catacombs', puzzle: 'Multi-Level Page Purge', enemy: 'Catacomb Walker', status: 'Expansion Pack 1' },
    { id: 38, sector: 'Real-Time Interrupt Trench', puzzle: 'Priority Interrupt Mask', enemy: 'IRQ Walker', status: 'Expansion Pack 1' },
    { id: 39, sector: 'Cryptographic Entropy Vault', puzzle: 'True Randomness Siphon', enemy: 'Entropy Stalker', status: 'Expansion Pack 1' },
    { id: 40, sector: 'Mainframe Master Terminal', puzzle: 'Grand Firmware Compiler', enemy: 'The Overseer Avatar', status: 'Expansion Pack 1' },
  ];

  return (
    <>
      <Head>
        <title>Sub-Routine | PS1 Indie Horror Game (PWA)</title>
      </Head>

      <main style={{ minHeight: '100vh', padding: '16px 24px', maxWidth: '1400px', margin: '0 auto' }}>
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #1f2333', paddingBottom: '14px', marginBottom: '20px', flexWrap: 'wrap', gap: '12px' }}>
          <div>
            <h1 style={{ fontSize: '24px', letterSpacing: '2px', color: '#00ff66', textShadow: '0 0 10px rgba(0, 255, 102, 0.4)' }}>
              SUB-ROUTINE // [PROD-v1.0]
            </h1>
            <p style={{ color: '#8892b0', fontSize: '13px', marginTop: '4px' }}>
              PS1 Lo-Fi Survival Horror | Subterranean Server Labyrinth | 40 Playable Sectors Ready
            </p>
          </div>

          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            <span style={{ fontSize: '11px', background: '#12141f', border: '1px solid #232738', padding: '4px 8px', borderRadius: '4px', color: '#00e5ff' }}>
              GL_COMPATIBILITY
            </span>
            <span style={{ fontSize: '11px', background: '#12141f', border: '1px solid #232738', padding: '4px 8px', borderRadius: '4px', color: '#00ff66' }}>
              60 FPS CAP
            </span>
            <span style={{ fontSize: '11px', background: '#12141f', border: '1px solid #232738', padding: '4px 8px', borderRadius: '4px', color: '#ffb703' }}>
              SINGLE-THREADED WASM
            </span>
            {installPrompt && (
              <button
                onClick={handleInstallClick}
                style={{
                  background: '#00ff66',
                  color: '#050508',
                  border: 'none',
                  padding: '6px 14px',
                  fontWeight: 'bold',
                  cursor: 'pointer',
                  borderRadius: '4px',
                  fontSize: '12px'
                }}
              >
                INSTALL PWA (ANDROID/LINUX)
              </button>
            )}
          </div>
        </header>

        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0, 2.5fr) minmax(320px, 1fr)', gap: '20px' }}>
          <div>
            <div className="crt-frame" style={{ width: '100%', height: '560px', position: 'relative' }}>
              <div className="crt-scanlines"></div>
              <iframe
                src="/game/index.html"
                title="Sub-Routine Game Viewport"
                style={{ width: '100%', height: '100%', border: 'none', display: 'block' }}
                allow="autoplay; fullscreen"
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#0e1017', border: '1px solid #1a1e2d', padding: '10px 16px', marginTop: '10px', borderRadius: '6px', fontSize: '13px' }}>
              <div>
                <span style={{ color: '#8892b0' }}>PROTAGONIST: </span>
                <strong style={{ color: '#fff' }}>ROXANNE "ROXY" VANCE</strong>
                <span style={{ color: '#00ff66', marginLeft: '12px' }}>[ENV DAMAGE: 0 | STAMINA SPRINT: ACTIVE]</span>
              </div>
              <div style={{ display: 'flex', gap: '16px' }}>
                <span>WASD: Move</span>
                <span>SHIFT: Sprint</span>
                <span>M / TAB: Telemetry</span>
                <span>ESC: Pause</span>
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div style={{ background: '#0f111a', border: '1px solid #1f2438', borderRadius: '8px', padding: '16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
                <h3 style={{ fontSize: '14px', color: '#fff', letterSpacing: '1px' }}>DYNAMIC DIFFICULTY SLIDER</h3>
                <span style={{ color: tier.color, fontWeight: 'bold', fontSize: '14px' }}>{tier.name.toUpperCase()}</span>
              </div>

              <input
                type="range"
                min="0"
                max="1"
                step="0.01"
                value={difficulty}
                onChange={(e) => setDifficulty(parseFloat(e.target.value))}
                style={{ width: '100%', cursor: 'pointer', accentColor: tier.color }}
              />

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '8px', marginTop: '14px', textAlign: 'center' }}>
                <div style={{ background: '#090a0f', padding: '8px', borderRadius: '4px', border: '1px solid #191c28' }}>
                  <div style={{ fontSize: '11px', color: '#8892b0' }}>ENEMY SPEED</div>
                  <div style={{ fontSize: '15px', color: tier.color, fontWeight: 'bold' }}>{tier.speed}x</div>
                </div>
                <div style={{ background: '#090a0f', padding: '8px', borderRadius: '4px', border: '1px solid #191c28' }}>
                  <div style={{ fontSize: '11px', color: '#8892b0' }}>ENEMY DAMAGE</div>
                  <div style={{ fontSize: '15px', color: tier.color, fontWeight: 'bold' }}>{tier.dmg}x</div>
                </div>
                <div style={{ background: '#090a0f', padding: '8px', borderRadius: '4px', border: '1px solid #191c28' }}>
                  <div style={{ fontSize: '11px', color: '#8892b0' }}>CIPHER KEYS</div>
                  <div style={{ fontSize: '15px', color: tier.color, fontWeight: 'bold' }}>{tier.cipher} Digits</div>
                </div>
              </div>
            </div>

            <div style={{ background: '#0f111a', border: '1px solid #1f2438', borderRadius: '8px', padding: '16px', flex: 1 }}>
              <h3 style={{ fontSize: '14px', color: '#ff3344', letterSpacing: '1px', marginBottom: '10px' }}>
                [THE OVERSEER - LIVE INTERVENTION FEED]
              </h3>
              <div style={{ background: '#07080c', border: '1px solid #191c28', borderRadius: '4px', padding: '10px', height: '170px', overflowY: 'auto', fontSize: '12px', lineHeight: '1.6' }}>
                {overseerLogs.map((log, idx) => (
                  <div key={idx} style={{ color: log.includes('OVERSEER') ? '#ff4d6d' : '#8892b0', marginBottom: '6px' }}>
                    {log}
                  </div>
                ))}
              </div>
            </div>

            <div style={{ background: '#0f111a', border: '1px solid #1f2438', borderRadius: '8px', padding: '12px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: '13px', color: '#fff' }}>OFFLINE PCK CACHING</div>
                <div style={{ fontSize: '11px', color: '#8892b0' }}>Service Worker active for Android/Linux</div>
              </div>
              <span style={{ fontSize: '11px', background: 'rgba(0, 255, 102, 0.1)', color: '#00ff66', border: '1px solid #00ff66', padding: '3px 8px', borderRadius: '4px' }}>
                SW ACTIVE
              </span>
            </div>
          </div>
        </div>

        <section style={{ marginTop: '24px', background: '#0f111a', border: '1px solid #1f2438', borderRadius: '8px', padding: '20px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px', flexWrap: 'wrap', gap: '10px' }}>
            <div>
              <h2 style={{ fontSize: '18px', color: '#fff', letterSpacing: '1px' }}>
                SECTOR ARCHITECTURE & LIVE-OPS ROADMAP
              </h2>
              <p style={{ color: '#8892b0', fontSize: '13px' }}>
                40 Playable Sectors Ready (Launch Day + Expansion Pack 1) | Total Scope: 120 Levels over 6 months
              </p>
            </div>
            <div style={{ fontSize: '13px', color: '#00ff66' }}>
              Active Playable Content: <strong>40 / 40 Built (100% of Phase 1 & 2)</strong>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '10px', maxHeight: '320px', overflowY: 'auto' }}>
            {allPlayableLevels.map((lvl) => (
              <div
                key={lvl.id}
                style={{
                  background: '#090a0f',
                  border: '1px solid #191c2b',
                  borderRadius: '6px',
                  padding: '10px 14px',
                  fontSize: '12px'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <strong style={{ color: lvl.id <= 20 ? '#00e5ff' : '#ffb703' }}>
                    SECTOR {lvl.id < 10 ? `0${lvl.id}` : lvl.id}
                  </strong>
                  <span style={{
                    background: lvl.id <= 20 ? 'rgba(0,255,102,0.15)' : 'rgba(255,183,3,0.15)',
                    color: lvl.id <= 20 ? '#00ff66' : '#ffb703',
                    padding: '2px 6px',
                    borderRadius: '3px',
                    fontSize: '10px'
                  }}>
                    {lvl.status}
                  </span>
                </div>
                <div style={{ color: '#fff', marginTop: '4px', fontWeight: 'bold' }}>{lvl.sector}</div>
                <div style={{ color: '#8892b0', fontSize: '11px', marginTop: '2px' }}>
                  Puzzle: {lvl.puzzle} | {lvl.enemy}
                </div>
              </div>
            ))}
          </div>
        </section>
      </main>
    </>
  );
}
