import { mkdir, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
globalThis.Deno = { env: { get: (key) => process.env[key] } };
const { DESIGN_PATTERNS } = await import('../../backend/supabase/functions/StudioAI/patterns.ts');
const { assembleScreen, buildGeneratedScreen } = await import('../../backend/supabase/functions/StudioAI/assembler.ts');
const { validateComponentSchema } = await import('../../backend/supabase/functions/StudioAI/validation.ts');
const live = process.argv.includes('--live');
if (live && !process.env.OPENAI_API_KEY) throw new Error('Live generation needs OPENAI_API_KEY in the environment. No credentials are stored in fixtures.');
const output = resolve(process.env.DESIGNUI_FIXTURE_DIR || 'tests/visual/fixtures');
await mkdir(output, { recursive: true });
const pattern = (id) => structuredClone(DESIGN_PATTERNS.find((p) => p.id === id).component);
const text = (value, size = 'body') => ({ type: 'Text', properties: { text: value }, modifiers: [{ type: 'Font', properties: { fontSize: size, fontWeight: size === 'title' ? 'bold' : 'regular', fontDesign: 'default' } }] });
const group = (children) => ({ type: 'VStack', properties: { alignment: 'leading', spacing: 12 }, children, modifiers: [{ type: 'Frame', properties: { widthType: 'Full', heightType: 'Default' } }] });
const chart = (style, preset, extra = {}) => ({ type: 'Chart', properties: { chartStyle: style, dataPreset: preset, pointCount: 7, showXAxis: true, showYAxis: true, ...extra }, modifiers: [{ type: 'Frame', properties: { widthType: 'Full', heightType: 'Custom', height: 200 } }] });
const rename = (component, map) => {
    if (component.type === 'Text' && map[component.properties?.text]) component.properties.text = map[component.properties.text];
    component.children?.forEach((child) => rename(child, map));
    return component;
};
const corpus = [
    { id: 'fitness', name: 'Forma', prompt: 'Design Forma, a fitness dashboard with a weekly activity chart and a featured workout card titled "Full Body Strength", duration "25 min" and a "Start Workout" button. Bottom tabs: Today, Explore, Profile. Keep the main action visible.', expected: ['Forma', 'Full Body Strength', 'Start Workout'], action: 'Start Workout', body: [rename(pattern('onboarding'), { 'Make room for your ideas': 'Full Body Strength', 'Turn a quick thought into something you can build.': '25 min', '1 of 3': 'Strength · Intermediate', 'Continue': 'Start Workout' }), chart('Bar', 'Weekly Activity')] },
    { id: 'shopping', name: 'Studio', prompt: 'Design a premium shopping home called Studio with search, filters and a headphones product card. Include "Studio headphones", "$129" and an "Add to bag" button.', expected: ['Studio headphones', '$129', 'Add to bag'], action: 'Add to bag', body: [pattern('search_filters'), pattern('product')] },
    { id: 'finance', name: 'Balance', prompt: 'Design Balance, a spending overview with a donut chart of spending categories, a monthly revenue trend with a $10000 goal line, and clear currency units. Keep labels readable.', expected: ['Balance', 'Spending', 'Revenue'], body: [group([text('Spending', 'headline'), chart('Donut', 'Spending', { showLegend: true, valuePrefix: '$' })]), group([text('Revenue', 'headline'), chart('Line', 'Revenue', { showGoal: true, goalValue: 10000, goalLabel: 'Goal', valuePrefix: '$' })])] },
    { id: 'travel', name: 'Wander', prompt: 'Design Wander, a travel planning screen with a weekly calendar, itinerary, and a hotel card with "Reserve stay" as its primary action.', expected: ['Wander', 'This week', 'Reserve stay'], action: 'Reserve stay', body: [pattern('calendar'), rename(pattern('product'), { 'Studio headphones': 'Harbor House', 'Wireless · Midnight': 'Lisbon · 2 nights', 'Add to bag': 'Reserve stay' })] },
    { id: 'social', name: 'Circle', prompt: 'Design Circle, a messaging screen with an incoming message "Are we still on for tomorrow?", an outgoing reply, and a message composer. Use clearly differentiated chat bubbles.', expected: ['Circle', 'Are we still on for tomorrow?'], body: [pattern('chat'), { type: 'Text Field', properties: { placeholder: 'Message', text: '' } }] },
    { id: 'productivity', name: 'Focus', prompt: 'Design Focus, a productivity screen with a weekly agenda and grouped notification settings for push notifications and email updates.', expected: ['Focus', 'Notifications', 'Push notifications', 'Email updates'], body: [pattern('calendar'), pattern('settings')] },
    { id: 'onboarding', name: 'Welcome', prompt: 'Design a welcoming onboarding screen with a single benefit, "Make room for your ideas", step 1 of 3 and a "Continue" button visible without scrolling.', expected: ['Make room for your ideas', 'Continue'], action: 'Continue', body: [pattern('onboarding')] },
    ...['empty', 'loading', 'error', 'pricing', 'checkout'].map((id) => ({ id, name: id[0].toUpperCase() + id.slice(1), prompt: `Design a polished ${id} screen with appropriate content and controls.`, expected: [], body: [pattern(id)] })),
];
const comparison = JSON.stringify([{ label: 'Jan', value: 42, series: 'Online' }, { label: 'Jan', value: 25, series: 'Retail' }, { label: 'Feb', value: 65, series: 'Online', highlighted: true }, { label: 'Feb', value: 31, series: 'Retail' }, { label: 'Mar', value: 80, series: 'Online' }, { label: 'Mar', value: 48, series: 'Retail' }]);
corpus[0].prompt += ' Include exactly 3 metrics: steps, calories and active minutes.';
corpus[0].expected.push('Steps', 'Calories', 'Active minutes', 'Today', 'Explore', 'Profile');
corpus[0].body.splice(1, 0, { type: 'HStack', properties: { alignment: 'top', spacing: 12 }, children: [['8,420', 'Steps'], ['640', 'Calories'], ['54', 'Active minutes']].map(([value, label]) => group([text(value, 'title3'), text(label, 'caption')])) });
corpus[0].footer = pattern('navigation');
for (const style of ['Line + Area', 'Bar', 'Stacked Bar', 'Sparkline']) corpus.push({ id: `chart-${style.toLowerCase().replaceAll(' ', '-')}`, name: style, prompt: `Design a ${style} comparison chart with Online and Retail series, highlighted February point and a goal line.`, expected: [], body: [chart(style, 'Revenue', { dataPoints: comparison, showLegend: true, showGoal: true, goalValue: 100, goalLabel: 'Target', valuePrefix: '$' })] });
const manifest = [];
for (const item of corpus) {
    const started = Date.now();
    const components = live
        ? (await buildGeneratedScreen(null, item.prompt, { canvasWidth: 375, canvasHeight: 812, chartSchemaVersion: 2 }, 'full_canvas')).components
        : assembleScreen([{ slotType: 'app_header', position: 'top', component: group([text(item.name, 'title')]) }, ...item.body.map((component) => ({ slotType: 'content_list', position: 'body', component })), ...(item.footer ? [{ slotType: 'nav_bar', position: 'bottom', component: item.footer }] : [])]).components;
    const errors = components.flatMap(validateComponentSchema);
    if (errors.length) throw new Error(`${item.id}: ${errors.join('; ')}`);
    await writeFile(resolve(output, `${item.id}.json`), JSON.stringify({ name: item.name, source: live ? 'live-model' : 'deterministic-pattern-fixture', prompt: item.prompt, expectedTexts: item.expected, primaryAction: item.action ?? null, components }, null, 2));
    manifest.push({ id: item.id, source: live ? 'live-model' : 'deterministic-pattern-fixture', elapsedMs: Date.now() - started });
    console.log(`Prepared ${item.id} (${Date.now() - started}ms)`);
}
await writeFile(resolve(output, '../generation-manifest.json'), JSON.stringify(manifest, null, 2));
