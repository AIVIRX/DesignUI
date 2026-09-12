// Node 22.18+ runs the pure TypeScript pipeline tests without Deno or network access.
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
globalThis.Deno = { env: { get: (key) => process.env[key] }, test };
await import('./supabase/functions/StudioAI/quality-eval.test.ts');

test('bundled editable patterns match the generator recipe catalog', async () => {
    const { DESIGN_PATTERNS } = await import('./supabase/functions/StudioAI/patterns.ts');
    const bundled = JSON.parse(await readFile(new URL('../DesignUI/Resources/design-patterns.json', import.meta.url), 'utf8'));
    assert.deepEqual(bundled, DESIGN_PATTERNS);
});

test('backend schema type vocabulary matches Swift renderer models', async () => {
    const schema = await import('./supabase/functions/StudioAI/schema.ts');
    for (const [file, enumName, supported] of [
        ['UIComponent.swift', 'ComponentType', schema.UI_COMPONENT_SCHEMA_TYPES],
        ['Modifier.swift', 'ModifierType', schema.UI_MODIFIER_SCHEMA_TYPES],
    ]) {
        const source = await readFile(new URL(`../DesignUI/Core/Views/Editor/Models/${file}`, import.meta.url), 'utf8');
        const enumBody = source.slice(source.indexOf(`enum ${enumName}`)).split('var id:')[0];
        const native = new Set([...enumBody.matchAll(/case\s+\w+\s*=\s*"([^"]+)"/g)].map((m) => m[1]));
        assert(native.size > 0, `Could not find ${enumName}`);
        for (const type of supported) assert(native.has(type), `${type} has no native renderer type`);
    }
});
