import express from "express";

const app = express();
const PORT = 3000;

app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.post("/api/submit", async (req, res) => {
    try {
        const formUrl =
            "https://docs.google.com/forms/d/124hlFNNdcPkCvuiZ0om_k2gzPzxyWL4CT1E8k9eXqyw/formResponse";

        const params = new URLSearchParams();

        for (const [key, value] of Object.entries(req.body)) {
            if (Array.isArray(value)) {
                value.forEach(v => params.append(key, v));
            } else {
                params.append(key, value);
            }
        }

        console.log("Submitting to Google Forms:", params.toString());

        const response = await fetch(formUrl, {
            method: "POST",
            body: params.toString(),
            headers: {
                "Content-Type": "application/x-www-form-urlencoded"
            }
        });

        console.log("Google Forms response:", response.status);

        if (!response.ok) {
            return res.status(500).json({
                message: "Google Forms submission failed"
            });
        }

        res.status(200).json({
            message: "Form submitted successfully"
        });

    } catch (error) {
        console.error("Error:", error);

        res.status(500).json({
            message: "Error submitting form",
            error: error.message
        });
    }
});

app.get("/health", (req, res) => {
    res.json({ status: "OK" });
});

app.listen(PORT, "0.0.0.0", () => {
    console.log(`SkillForge API running on port ${PORT}`);
});