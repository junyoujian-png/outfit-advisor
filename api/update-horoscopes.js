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

function buildPrompt(label) {
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

  const results = [];
  const errors = [];

  for (const zodiac of ZODIACS) {
    try {
      const content = await callGemini(buildPrompt(zodiac.label));
      const { error } = await supabase
        .from('daily_horoscopes')
        .upsert(
          { zodiac_sign: zodiac.id, content_json: content, date: today },
          { onConflict: 'zodiac_sign,date' }
        );
      if (error) throw error;
      results.push(zodiac.id);
      await new Promise(r => setTimeout(r, 500));
    } catch (err) {
      errors.push({ zodiac: zodiac.id, error: err.message });
    }
  }

  return res.status(200).json({
    date: today,
    success: results,
    errors,
    message: `完成 ${results.length}/12 個星座`,
  });
};
