const { createClient } = require('@supabase/supabase-js');

module.exports = async function handler(req, res) {
  const { sign } = req.query;

  if (!sign) {
    return res.status(400).json({ error: '缺少 sign 參數' });
  }

  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY
  );

  const today = new Date(Date.now() + 8 * 60 * 60 * 1000)
    .toISOString()
    .split('T')[0];

  const { data, error } = await supabase
    .from('daily_horoscopes')
    .select('content_json')
    .eq('zodiac_sign', sign)
    .eq('date', today)
    .single();

  if (error || !data) {
    return res.status(404).json({
      error: '今日運勢尚未準備好，請稍後再試',
      date: today,
      sign,
    });
  }

  res.setHeader('Cache-Control', 's-maxage=3600, stale-while-revalidate');
  return res.status(200).json(data.content_json);
};
