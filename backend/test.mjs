// Node 22.18+ runs the pure TypeScript pipeline tests without Deno or network access.
import { test } from 'node:test';
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
globalThis.Deno = { env: { get: (key) => process.env[key] }, test };
await import('./supabase/functions/StudioAI/quality-eval.test.ts');

test('Balance live output regressions: planning, instruction leakage and chart assignment', async () => {
    const { buildDesignManifest } = await import('./supabase/functions/StudioAI/manifest.ts');
    const { postProcessComponents } = await import('./supabase/functions/StudioAI/postprocess.ts');
    const { validateChartAssignment } = await import('./supabase/functions/StudioAI/content-contract.ts');
    const prompt = 'Create a finance dashboard with a spending donut chart, monthly revenue line chart with a $10K goal line, three metric cards, recent transactions, search/filter chips, and a bottom tab bar with Overview, Activity, and Profile.';
    const manifest = buildDesignManifest(prompt);
    assert(!manifest.requirements.some((r) => r.requirementKey === 'search_results_list'));
    assert(manifest.requirements.some((r) => r.requirementKey === 'explicit_navigation'));
    assert(manifest.requirements.some((r) => r.requirementKey === 'explicit_metrics' && r.itemCount === 3));
    assert(manifest.requirements.some((r) => r.requirementKey === 'explicit_transactions'));
    const assignment = manifest.requirements.find((r) => r.requirementKey === 'explicit_charts').mustInclude;
    const leaked = 'Offer 3 selectable mood-style filter chips for quick dashboard context switching such as All, Spending, and Revenue. Required: 3 selectable mood chips';
    assert.equal(postProcessComponents([{ type: 'Text', properties: { text: leaked } }])[0].properties.text, 'Filters');
    const badChart = { type: 'Chart', properties: { chartStyle: 'Donut', dataPoints: '[{"label":"Feb","value":9400},{"label":"Mar","value":8900}]' } };
    assert(validateChartAssignment(badChart, assignment).length >= 2);
    const good = { type: 'VStack', children: [{ type: 'Chart', properties: { chartStyle: 'Donut', dataPoints: '[{"label":"Food","value":200},{"label":"Rent","value":800}]' } }, { type: 'Chart', properties: { chartStyle: 'Line', dataPoints: badChart.properties.dataPoints } }] };
    assert.deepEqual(validateChartAssignment(good, assignment), []);
    assert(buildDesignManifest('Design a search results screen with exactly 4 results').requirements.some((r) => r.requirementKey === 'search_results_list' && r.itemCount === 4));
});

test('duplicate navigation groups are removed while unrelated content survives', async () => {
    const { reviewScreen } = await import('./supabase/functions/StudioAI/screen-quality.ts');
    const { buildDesignManifest } = await import('./supabase/functions/StudioAI/manifest.ts');
    const { buildBaselineTheme } = await import('./supabase/functions/StudioAI/theme.ts');
    const nav = { type: 'HStack', children: ['Overview', 'Activity', 'Profile'].map((text) => ({ type: 'Text', properties: { text } })) };
    const sections = [{ slot: { slotType: 'content_list', position: 'body', intent: 'Transactions' }, component: { type: 'VStack', children: [structuredClone(nav), { type: 'Text', properties: { text: 'Coffee $5' } }] }, exemplarIds: [] }, { slot: { slotType: 'nav_bar', position: 'bottom', intent: 'Navigation' }, component: nav, exemplarIds: [] }];
    const result = await reviewScreen({ sections, plan: { slots: sections.map((s) => s.slot) }, manifest: buildDesignManifest('Transactions'), theme: buildBaselineTheme({ accentColor: 'blue:1.0', surfaceStyle: 'minimal', density: 'regular', fontDesign: 'default' }), deadlineAt: 0, repair: async () => { throw new Error('No model call expected'); } });
    assert.equal(result.sections[0].component.children.length, 1);
    assert.equal(result.sections[0].component.children[0].properties.text, 'Coffee $5');
    assert.deepEqual(result.sections[1].component.children.map((n) => n.properties.text), ['Overview', 'Activity', 'Profile']);
});

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
