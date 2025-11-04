// Disable body parsing, we'll handle it manually
export const config = {
    api: {
        bodyParser: false,
    },
};

export default async function handler(req, res) {
    // Enable CORS
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        return res.status(200).end();
    }

    if (req.method !== "POST") {
        return res.status(405).json({ message: "Method not allowed" });
    }

    try {
        const formUrl = "https://docs.google.com/forms/d/124hlFNNdcPkCvuiZ0om_k2gzPzxyWL4CT1E8k9eXqyw/formResponse";

        // Parse the form data
        const buffers = [];
        for await (const chunk of req) {
            buffers.push(chunk);
        }
        const rawData = Buffer.concat(buffers).toString();
        
        // Parse multipart form data properly
        const boundary = req.headers['content-type']?.split('boundary=')[1];
        const params = new URLSearchParams();
        
        if (boundary) {
            // Parse multipart/form-data
            const parts = rawData.split(`--${boundary}`);
            for (const part of parts) {
                const nameMatch = part.match(/name="([^"]+)"/);
                if (nameMatch) {
                    const name = nameMatch[1];
                    const valueMatch = part.split('\r\n\r\n')[1]?.split('\r\n')[0];
                    if (valueMatch) {
                        params.append(name, valueMatch);
                    }
                }
            }
        } else {
            // Already URL encoded
            return res.status(400).json({ message: "Invalid content type" });
        }

        console.log("Parsed params:", params.toString());
        
        // Forward to Google Forms
        const response = await fetch(formUrl, {
            method: "POST",
            body: params.toString(),
            headers: { 
                "Content-Type": "application/x-www-form-urlencoded",
            },
        });

        console.log("Google Forms response status:", response.status);

        return res.status(200).json({ message: "Form submitted successfully" });
    } catch (err) {
        console.error("Error:", err);
        return res.status(500).json({ message: "Error submitting form", error: err.message });
    }
}