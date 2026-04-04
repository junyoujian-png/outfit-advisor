const { createClient } = require('@supabase/supabase-js');

const ZODIACS = [
  { id: 'aries',       label: '牡羊座' },
  { id: 'taurus',      label: '金牛座' },
  { id: 'gemini',      label: '雙子座' },
  { id: 'cancer',      label: '巨蟹座' },
  { id: 'leo',         label: '獅子座' },
  { id: 'virgo',       label: '處女座' },
  { id: 'libra',       label: '天秤座' },
  { id: 'scorpio',     label: '天蠍座' },
  { id: 'sagittarius', label: '射手座' },
  { id: 'capricorn',   label: '摩羯座' },
  { id: 'aquarius',    label: '水瓶座' },
  { id: 'pisces',      label: '雙魚座' },
];

function buildPromptZh(label) {
  return `你是一位專業星座運勢占卜師。請為「${label}」提供今日運勢，並嚴格以下方 JSON 格式回傳，不要加任何多餘文字或 markdown：
{
  "overall": "今日運勢總評（2-3句）",
  "luckyColor": "幸運色",
  "luckyNumber": "幸運數字",
  "love": "愛情運（1-2句）",
  "career": "事業運（1-2句）",
  "health": "健康運（1-2句）"
}`;
}

function buildPromptEn(label) {
  return `You are a professional astrologer. Please provide today's horoscope for ${label} and respond strictly in the following JSON format, with no extra text or markdown:
{
  "overall": "Overall fortune for today (2-3 sentences)",
  "luckyColor": "Lucky color",
  "luckyNumber": "Lucky number",
  "love": "Love fortune (1-2 sentences)",
  "career": "Career fortune (1-2 sentences)",
  "health": "Health fortune (1-2 sentences)"
}`;
}

async function callGemini(prompt) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new Error('GEMINI_API_KEY 環境變數未設定');

  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${apiKey}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
      }),
    }
  );
  const data = await res.json();
  if (!res.ok) throw new Error('Gemini API 錯誤: ' + JSON.stringify(data));
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';
  const match = text.match(/\{[\s\S]*\}/);
  if (!match) throw new Error('無效 JSON，原始回應: ' + text.slice(0, 200));
  return JSON.parse(match[0]);
}

module.exports = async function handler(req, res) {
  try {
  const secret = req.headers['x-cron-secret'] || req.query.secret;
  if (secret !== process.env.CRON_SECRET) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
  );

  const today = new Date(Date.now() + 8 * 60 * 60 * 1000)
    .toISOString()
    .split('T')[0];

  const allLangs = [
    { code: 'zh', buildPrompt: (label) => buildPromptZh(label) },
    { code: 'en', buildPrompt: (label) => buildPromptEn(label) },
  ];
  const langFilter = req.query.lang;
  const langs = langFilter
    ? allLangs.filter((l) => l.code === langFilter)
    : allLangs;
  if (langs.length === 0) {
    return res.status(400).json({ error: `不支援的 lang 參數：${langFilter}，請使用 zh 或 en` });
  }
  const total = ZODIACS.length * langs.length;

  const tasks = ZODIACS.flatMap((zodiac) =>
    langs.map((lang) => async () => {
      const content = await callGemini(lang.buildPrompt(zodiac.label));
      const { error } = await supabase
        .from('daily_horoscopes')
        .upsert(
          { zodiac_sign: zodiac.id, content_json: content, date: today, lang: lang.code },
          { onConflict: 'zodiac_sign,date,lang' }
        );
      if (error) {
        console.error('Supabase Error:', error);
        throw error;
      }
      return `${zodiac.id}(${lang.code})`;
    })
  );

  const settled = await Promise.allSettled(tasks.map((t) => t()));

  const results = [];
  const errors = [];
  for (let i = 0; i < settled.length; i++) {
    const r = settled[i];
    if (r.status === 'fulfilled') {
      results.push(r.value);
    } else {
      const zodiac = ZODIACS[Math.floor(i / langs.length)];
      const lang = langs[i % langs.length];
      errors.push({ zodiac: zodiac.id, lang: lang.code, error: r.reason?.message ?? String(r.reason) });
    }
  }

  return res.status(200).json({
    date: today,
    success: results,
    errors,
    message: `完成 ${results.length}/${total} 個星座語言組合`,
  });
  } catch (err) {
    console.error('Handler Error:', err);
    return res.status(500).json({ error: err.message });
  }
};
