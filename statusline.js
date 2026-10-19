#!/usr/bin/env node
// Statusline: model | directory | context used %
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const model = data.model?.display_name || 'Claude';
    const dir = (data.workspace?.current_dir || process.cwd()).split('/').pop();
    const remaining = data.context_window?.remaining_percentage;
    let ctx = '';
    if (remaining != null) {
      const used = Math.max(0, Math.min(100, Math.round(100 - remaining)));
      const bar = '█'.repeat(Math.floor(used / 10)) + '░'.repeat(10 - Math.floor(used / 10));
      const color = used < 50 ? 32 : used < 70 ? 33 : 31;
      ctx = ` \x1b[${color}m${bar} ${used}%\x1b[0m`;
    }
    process.stdout.write(`${model} │ ${dir}${ctx}`);
  } catch (e) {
    process.stdout.write('Claude');
  }
});
