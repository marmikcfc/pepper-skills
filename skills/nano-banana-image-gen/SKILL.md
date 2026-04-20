---
name: nano-banana-image-gen
description: Generate images from text prompts using Gemini models via the Nano Banana API on Orthogonal. Supports flash ($0.05/image) and pro ($0.15/image) quality tiers. Use when asked to create, generate, or make images.
---

# Nano Banana Image Generation

Generate images from text prompts using Gemini-powered models through the Orthogonal platform.

## Requirements

- Orthogonal CLI installed and authenticated (`orth login`)
- An Orthogonal API key with credits

## Models

| Model | Endpoint | Price | Best For |
|-------|----------|-------|----------|
| **Flash** | `gemini-2.5-flash-image` | $0.05/call | Quick drafts, iterations, bulk generation |
| **Pro** | `gemini-3-pro-image-preview` | $0.15/call | High-quality output, 2K/4K resolution, complex scenes |

Default to **flash** unless the user requests high quality or pro.

## Generate an Image

```bash
orth api run nano-banana /v1beta/models/gemini-2.5-flash-image:generateContent --body '{
  "contents": [{
    "parts": [{"text": "YOUR PROMPT HERE"}]
  }],
  "generationConfig": {
    "responseModalities": ["TEXT", "IMAGE"]
  }
}'
```

For pro quality, replace `gemini-2.5-flash-image` with `gemini-3-pro-image-preview`.

## Response Format

The response contains a `candidates` array. Each candidate has `content.parts` with:
1. A `text` part (short description from the model)
2. An `inlineData` part with `mimeType: "image/png"` and `data` containing the base64-encoded PNG

```json
{
  "candidates": [{
    "content": {
      "parts": [
        { "text": "Here is your image!" },
        { "inlineData": { "mimeType": "image/png", "data": "<base64>" } }
      ]
    }
  }]
}
```

## Save the Image

After getting the response, extract the base64 data from `candidates[0].content.parts[1].inlineData.data` and decode it to a file.

**Python:**
```python
import base64, json

response = json.loads(raw_response)
img_data = response["candidates"][0]["content"]["parts"][1]["inlineData"]["data"]
with open("output.png", "wb") as f:
    f.write(base64.b64decode(img_data))
```

**Node.js:**
```javascript
const fs = require("fs");
const response = JSON.parse(rawResponse);
const imgData = response.candidates[0].content.parts[1].inlineData.data;
fs.writeFileSync("output.png", Buffer.from(imgData, "base64"));
```

**Bash (using jq + base64):**
```bash
echo "$RESPONSE" | jq -r '.candidates[0].content.parts[1].inlineData.data' | base64 -d > output.png
```

## Prompt Tips

- Be specific about style: "digital art", "watercolor", "photorealistic", "pixel art"
- Mention composition details: "close-up", "wide angle", "top-down view"
- Include mood/lighting: "warm sunset lighting", "dramatic shadows", "soft pastel colors"
- Reference art styles: "in the style of Studio Ghibli", "minimalist flat design"
- For text in images, be explicit: "with the text 'Hello World' in bold sans-serif font"

## List Available Models

To see all models available on the Nano Banana API:

```bash
orth api run nano-banana /v1beta/models -X GET
```
