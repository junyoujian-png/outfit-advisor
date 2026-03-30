module.exports = async function handler(req, res) {
  // 只允許 POST 請求
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { prompt } = req.body;
  
  // 從 Vercel 環境變數讀取 API Key
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey) {
    return res.status(500).json({ error: '伺服器端尚未設定 GEMINI_API_KEY 環境變數。' });
  }

  // 💡 終極對策：準備一組「絕對會中一個」的網址候選名單
  const endpoints = [
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${apiKey}`,
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`,
    `https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=${apiKey}`
  ];

  let lastError = "所有模型嘗試均失敗";

  // 自動依序嘗試每一個網址
  for (const url of endpoints) {
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }]
        })
      });

      const data = await response.json();

      // 如果成功，就立刻回傳結果給前端，並結束整個流程！
      if (response.ok && data?.candidates?.[0]?.content?.parts?.[0]?.text) {
        return res.status(200).json({ text: data.candidates[0].content.parts[0].text });
      } else {
        // 紀錄錯誤，但不要放棄，讓它繼續跑迴圈試下一個
        lastError = data?.error?.message || `HTTP ${response.status}`;
        console.log(`模型嘗試失敗，準備切換下一個。錯誤原因: ${lastError}`);
      }
    } catch (error) {
      lastError = error.message;
      console.log(`網路請求錯誤: ${lastError}`);
    }
  }

  // 如果這 4 個全部都失敗了，才會把最後的錯誤訊息丟給前端
  return res.status(500).json({ error: `AI 模型配對失敗，請檢查 Vercel 環境變數的 API Key 是否正確。最後錯誤: ${lastError}` });
};