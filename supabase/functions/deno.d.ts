// supabase/functions/deno.d.ts
/// <reference types="https://esm.sh/@deno/types@2.0.0" />

declare const Deno: {
  env: {
    get(name: string): string | undefined;
    set(name: string, value: string): void;
    delete(name: string): void;
    toObject(): Record<string, string>;
  };
  serve(handler: (req: Request) => Response | Promise<Response>): void;
  serve(options: { port?: number; hostname?: string; onListen?: (params: { hostname: string; port: number }) => void; signal?: AbortSignal }, handler: (req: Request) => Response | Promise<Response>): void;
  readTextFile(path: string | URL): Promise<string>;
  writeTextFile(path: string | URL, data: string): Promise<void>;
  args: string[];
  cwd(): string;
  exit(code?: number): never;
  build: {
    arch: string;
    os: string;
    vendor: string;
    target: string;
  };
  version: {
    deno: string;
    v8: string;
    typescript: string;
  };
  permissions: {
    query(desc: unknown): Promise<{ state: "granted" | "denied" | "prompt" }>;
  };
  metrics(): {
    blobsCacheSize: number;
    blobsHeapSize: number;
    blobsTotalSize: number;
    threads: number;
    heapTotal: number;
    heapUsed: number;
  };
  run(opt: unknown): unknown;
};
