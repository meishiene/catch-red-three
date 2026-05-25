export class TurnTimer {
  private timer: NodeJS.Timeout | null = null;
  private startTime: number = 0;
  private duration: number = 0;
  private callback: (() => void) | null = null;
  private tickCallback: ((remainingMs: number) => void) | null = null;

  start(durationMs: number, onTimeout: () => void, onTick?: (remainingMs: number) => void): void {
    this.cancel();
    this.duration = durationMs;
    this.startTime = Date.now();
    this.callback = onTimeout;
    this.tickCallback = onTick || null;

    this.timer = setTimeout(() => {
      this.timer = null;
      if (this.callback) this.callback();
    }, durationMs);

    if (this.tickCallback) {
      this.startTicking();
    }
  }

  private startTicking(): void {
    const tick = () => {
      if (!this.timer) return;
      const elapsed = Date.now() - this.startTime;
      const remaining = Math.max(0, this.duration - elapsed);
      if (this.tickCallback) this.tickCallback(remaining);
      if (remaining > 0) {
        setTimeout(tick, 5000);
      }
    };
    setTimeout(tick, 5000);
  }

  getRemainingMs(): number {
    if (!this.timer) return 0;
    const elapsed = Date.now() - this.startTime;
    return Math.max(0, this.duration - elapsed);
  }

  cancel(): void {
    if (this.timer) {
      clearTimeout(this.timer);
      this.timer = null;
    }
    this.callback = null;
    this.tickCallback = null;
  }

  isRunning(): boolean {
    return this.timer !== null;
  }
}
