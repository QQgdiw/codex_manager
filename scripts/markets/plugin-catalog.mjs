import { createHash } from 'node:crypto';
import { spawn } from 'node:child_process';

const DEFAULT_TIMEOUT_MS = 30_000;

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function hasOwn(value, property) {
  return Object.prototype.hasOwnProperty.call(value, property);
}

function validateJsonRpcResponse(message, requestId) {
  if (message.jsonrpc !== '2.0') {
    throw new Error(`invalid JSON-RPC response for request ${requestId}`);
  }
  const hasResult = hasOwn(message, 'result');
  const hasError = hasOwn(message, 'error');
  if (hasResult === hasError) {
    throw new Error(`invalid JSON-RPC response for request ${requestId}`);
  }
  if (hasError && !isObject(message.error)) {
    throw new Error(`invalid JSON-RPC response for request ${requestId}`);
  }
  return message;
}

function marketplaceNameOf(marketplace) {
  if (!isObject(marketplace)) {
    return undefined;
  }

  return marketplace.name
    ?? marketplace.marketplaceName
    ?? marketplace.marketplace?.name;
}

function pluginField(plugin, field) {
  return plugin[field] ?? plugin.manifest?.[field] ?? plugin.metadata?.[field];
}

function displayValue(plugin, fields, fallback = '') {
  for (const field of fields) {
    const value = pluginField(plugin, field);
    if (value != null && value !== '') {
      return value;
    }
  }
  return fallback;
}

function chineseCategory(plugin) {
  const category = String(displayValue(plugin, ['category', 'categories'], '')).toLowerCase();
  const categories = {
    ai: '人工智能',
    analytics: '数据分析',
    data: '数据分析',
    database: '数据库',
    development: '开发工具',
    devops: '开发运维',
    documentation: '文档',
    productivity: '效率工具',
    security: '安全',
  };
  return categories[category] ?? '其他';
}

function markdownCell(value) {
  const text = Array.isArray(value) ? value.join(', ') : String(value ?? '');
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\\/g, '\\\\')
    .replace(/\|/g, '\\|')
    .replace(/\r?\n/g, '<br>');
}

function recordDetails(record) {
  const plugin = record.plugin;
  return {
    displayName: displayValue(plugin, ['displayName', 'name', 'title'], record.id),
    developer: displayValue(plugin, ['developer', 'publisher', 'author', 'organization']),
    description: displayValue(plugin, ['description', 'shortDescription', 'summary']),
    capabilities: displayValue(plugin, ['capabilities', 'features'], record.keywords),
    website: displayValue(plugin, ['website', 'url', 'homepage']),
  };
}

export function pluginRecordKey(marketplaceName, plugin) {
  const identity = JSON.stringify([
    marketplaceName,
    String(plugin.id),
    plugin.remotePluginId == null ? '' : String(plugin.remotePluginId),
    plugin.version == null ? '' : String(plugin.version),
  ]);
  return createHash('sha256').update(identity, 'utf8').digest('hex');
}

export function validatePluginListResult(result) {
  if (!isObject(result)) {
    throw new Error('plugin list result must be an object');
  }
  if (!Array.isArray(result.marketplaces)) {
    throw new Error('plugin list result marketplaces must be an array');
  }
  if (result.marketplaceLoadErrors != null && !Array.isArray(result.marketplaceLoadErrors)) {
    throw new Error('plugin list result marketplaceLoadErrors must be an array');
  }
  if ((result.marketplaceLoadErrors ?? []).length > 0) {
    throw new Error('marketplace load error prevents catalog export');
  }

  const records = [];
  const recordKeys = new Set();
  for (const marketplace of result.marketplaces) {
    const marketplaceName = marketplaceNameOf(marketplace);
    if (typeof marketplaceName !== 'string' || marketplaceName.length === 0) {
      throw new Error('plugin list marketplace name is required');
    }
    if (!Array.isArray(marketplace.plugins)) {
      throw new Error(`plugin list plugins for ${marketplaceName} must be an array`);
    }

    for (const plugin of marketplace.plugins) {
      if (!isObject(plugin) || plugin.id == null || String(plugin.id).length === 0) {
        throw new Error(`plugin list plugin id is required for ${marketplaceName}`);
      }
      const recordKey = pluginRecordKey(marketplaceName, plugin);
      if (recordKeys.has(recordKey)) {
        throw new Error(`duplicate plugin record key: ${recordKey}`);
      }
      recordKeys.add(recordKey);
      records.push({
        marketplaceName,
        id: String(plugin.id),
        remotePluginId: plugin.remotePluginId ?? null,
        version: plugin.version ?? null,
        interface: plugin.interface ?? null,
        availability: plugin.availability ?? null,
        installPolicy: plugin.installPolicy ?? null,
        authPolicy: plugin.authPolicy ?? null,
        keywords: Array.isArray(plugin.keywords) ? plugin.keywords : [],
        recordKey,
        plugin,
      });
    }
  }

  return {
    records,
    marketplaces: result.marketplaces.length,
    marketplaceLoadErrors: result.marketplaceLoadErrors ?? [],
  };
}

export function renderPluginsMarket(catalog, metadata = {}) {
  const records = catalog.records ?? [];
  const lines = [
    '# Plugins 市场目录',
    '',
    '## 采集摘要',
    '',
    `- 采集时间：${markdownCell(metadata.collectedAt ?? '未记录')}`,
    `- Codex 版本：${markdownCell(metadata.codexVersion ?? '未记录')}`,
    `- Marketplace 数：${markdownCell(catalog.marketplaces ?? '未记录')}`,
    `- 原始记录数：${records.length}`,
    '',
    '## 来源边界',
    '',
    '本目录仅以当前 Codex app-server `plugin/list` 响应为收录权威。CLI marketplace snapshot、本地缓存和历史仓库只能补充信息，不能替代完整目录。',
    '',
    '## 异常记录',
    '',
    catalog.marketplaceLoadErrors?.length ? markdownCell(JSON.stringify(catalog.marketplaceLoadErrors)) : '无。',
    '',
    '## 研发者重点索引',
    '',
  ];

  const focused = records.filter((record) => {
    const category = chineseCategory(record.plugin);
    return category === '开发工具' || category === '开发运维' || category === '人工智能';
  });
  if (focused.length === 0) {
    lines.push('无。');
  }
  else {
    for (const record of focused) {
      const details = recordDetails(record);
      lines.push(`- ${markdownCell(details.displayName)}（${markdownCell(record.id)}，${markdownCell(record.marketplaceName)}）`);
    }
  }

  lines.push(
    '',
    '## 完整清单',
    '',
    '| 记录键 | 插件 ID | Marketplace | 版本 | 展示名称 | 开发者 | 中文类别 | 官方简述 | 能力 | 可用状态 | 安装策略 | 认证策略 | 网站 |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |',
  );
  for (const record of records) {
    const details = recordDetails(record);
    lines.push(`<!-- plugin-record:${record.recordKey} -->`);
    lines.push([
      record.recordKey,
      record.id,
      record.marketplaceName,
      record.version,
      details.displayName,
      details.developer,
      chineseCategory(record.plugin),
      details.description,
      details.capabilities,
      record.availability,
      record.installPolicy,
      record.authPolicy,
      details.website,
    ].map(markdownCell).join(' | ').replace(/^/, '| ').concat(' |'));
  }
  return `${lines.join('\n')}\n`;
}

export function collectPluginCatalog({
  codexCommand = 'codex',
  cwd,
  timeoutMs = DEFAULT_TIMEOUT_MS,
  spawnImpl = spawn,
} = {}) {
  return new Promise((resolve, reject) => {
    let child;
    let settled = false;
    let buffer = '';
    let initialized = false;
    let initializeRequestSent = false;
    let pluginListRequestSent = false;
    const finish = (error, catalog) => {
      if (settled) {
        return;
      }
      settled = true;
      clearTimeout(timer);
      if (child?.stdin && !child.stdin.destroyed) {
        child.stdin.end();
      }
      if (child && child.exitCode == null && !child.killed) {
        child.kill();
      }
      if (error) {
        reject(error);
      }
      else {
        resolve(catalog);
      }
    };
    const send = (message) => child.stdin.write(`${JSON.stringify(message)}\n`);
    const sendRequest = (message) => {
      send(message);
      if (message.id === 1) {
        initializeRequestSent = true;
      }
      if (message.id === 2) {
        pluginListRequestSent = true;
      }
    };
    const timer = setTimeout(() => finish(new Error('plugin_catalog_timeout')), timeoutMs);

    try {
      child = spawnImpl(codexCommand, ['app-server', '--stdio'], {
        cwd,
        stdio: ['pipe', 'pipe', 'pipe'],
        windowsHide: true,
      });
      child.once('error', (error) => finish(error));
      child.stdout.setEncoding('utf8');
      child.stdout.on('data', (chunk) => {
        buffer += chunk;
        const lines = buffer.split('\n');
        buffer = lines.pop();
        for (const line of lines) {
          if (!line.trim() || settled) {
            continue;
          }
          let message;
          try {
            message = JSON.parse(line);
          }
          catch {
            finish(new Error('plugin catalog received invalid JSON'));
            continue;
          }
          if (!isObject(message)) {
            continue;
          }
          if (message.id !== 1 && message.id !== 2) {
            continue;
          }
          if ((message.id === 1 && !initializeRequestSent)
            || (message.id === 2 && !pluginListRequestSent)) {
            finish(new Error(`plugin catalog response received before request ${message.id}`));
            continue;
          }
          try {
            validateJsonRpcResponse(message, message.id);
          }
          catch (error) {
            finish(error);
            continue;
          }
          if (message.id === 1 && !initialized) {
            if (message.error) {
              finish(new Error('plugin catalog initialize failed'));
              continue;
            }
            if (!isObject(message.result)) {
              finish(new Error('invalid JSON-RPC response for request 1'));
              continue;
            }
            initialized = true;
            send({ method: 'initialized', params: {} });
            sendRequest({ id: 2, method: 'plugin/list', params: { cwds: [cwd] } });
          }
          else if (message.id === 2) {
            if (message.error) {
              finish(new Error('plugin catalog plugin/list failed'));
              continue;
            }
            try {
              finish(null, validatePluginListResult(message.result));
            }
            catch {
              finish(new Error('plugin catalog plugin/list result is invalid'));
            }
          }
        }
      });
      child.stderr?.resume();
      sendRequest({
        id: 1,
        method: 'initialize',
        params: {
          clientInfo: { name: 'codex-market-audit', version: '1.0.0' },
          capabilities: { experimentalApi: true },
        },
      });
    }
    catch (error) {
      finish(error);
    }
  });
}
