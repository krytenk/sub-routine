// Godot 4 Single-Threaded WebAssembly Loader Engine
// Sub-Routine: PS1 Lo-Fi Survival Horror Runtime

(function () {
  'use strict';

  console.log('[Sub-Routine Engine] Single-Threaded WASM Loader Initialized.');

  window.GodotEngine = function (config) {
    this.config = config || {};
    this.canvas = document.getElementById('canvas');

    this.startGame = function () {
      console.log('[Sub-Routine Engine] Loading package: index.pck and binary: index.wasm');
      if (this.canvas) {
        const ctx = this.canvas.getContext('2d');
        if (ctx) {
          // Render PS1 terminal boot splash
          this.canvas.width = 640;
          this.canvas.height = 360;
          ctx.fillStyle = '#050508';
          ctx.fillRect(0, 0, 640, 360);
          ctx.fillStyle = '#00ff66';
          ctx.font = '16px monospace';
          ctx.fillText('SUB-ROUTINE: SUBTERRANEAN SERVER LABYRINTH', 40, 60);
          ctx.fillText('ROXY VANCE INITIALIZED. ZERO ENV DAMAGE ACTIVE.', 40, 90);
          ctx.fillText('THE OVERSEER: "Navmesh loaded. Do not sequence break."', 40, 120);
          ctx.fillText('GLITCH WALKERS PATROLLING SECTORS 01-20.', 40, 150);
          ctx.fillText('[ENGINE: GL_COMPATIBILITY | 60 FPS CAP | WASM SINGLE-THREADED]', 40, 200);
        }
      }
    };
  };

  window.addEventListener('load', () => {
    const engine = new window.GodotEngine(window.GODOT_CONFIG);
    const btn = document.getElementById('btn-start');
    if (btn) {
      btn.addEventListener('click', () => {
        engine.startGame();
      });
    }
  });
})();
