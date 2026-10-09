# Ar-Rayaan Vault

One small service that holds the Quran Foundation client secret server-side.
The app talks only to this vault; the secret never reaches a browser.

## Deploy on Render (5 minutes)

1. dashboard.render.com -> **New +** -> **Web Service**
2. Connect `agkautobody-design/ar-rayaan`
3. Settings:
   - **Root Directory**: `services/vault`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn app:app --workers 2 --threads 4`
   - **Instance Type**: Free
4. Environment variables:
   - `QF_CLIENT_ID` = 1c25b109-9834-41c4-8ae5-609ce76a3dab
   - `QF_CLIENT_SECRET` = (your qfcs_... secret - paste from your records)
   - `VAULT_ORIGIN` = https://ar-rayaan.onrender.com
5. **Deploy**. Note the service URL (https://ar-rayaan-vault.onrender.com).

The app reads the vault URL from the AR_VAULT_URL build flag.
