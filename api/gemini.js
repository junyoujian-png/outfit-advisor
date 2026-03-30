module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { prompt } = req.body;
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: 'Vercel 環境變數 GEMINI_API_KEY 未設定！' });
  }

  // 🕵️‍♂️ 抓出前 10 個字元來核對是不是新 Key
  const keyPrefix = apiKey.substring(0, 10) + '...';

  try {
    // 鎖定最穩定的 1.5-flash 測試版路徑
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }]
      })
    });

    const data = await response.json();

    if (!response.ok) {
      // 如果失敗，把正在使用的 Key 前綴印在網頁上
      return res.status(500).json({ 
        error: `[目前 Vercel 使用的金鑰: ${keyPrefix}] Google 報錯: ${data?.error?.message}` 
      });
    }

    return res.status(200).json({ text: data.candidates[0].content.parts[0].text });

  } catch (error) {
    return res.status(500).json({ error: `連線錯誤: ${error.message}` });
  }
};