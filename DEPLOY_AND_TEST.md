# Notes API – Deploy to Azure & Test with Postman

This guide walks you through deploying the **Notes API** to Azure App Service and testing it with Postman.

---

## Prerequisites

| Tool | Install link |
|------|-------------|
| **.NET 8 SDK** | <https://dotnet.microsoft.com/download/dotnet/8.0> |
| **Azure CLI** | <https://learn.microsoft.com/cli/azure/install-azure-cli> |
| **Postman** | <https://www.postman.com/downloads/> |
| **An Azure subscription** | [Free account](https://azure.microsoft.com/free/) |

### Install Azure CLI

If you don't have the Azure CLI installed, follow the official instructions for your OS:

- **macOS:**
  ```bash
  brew update && brew install azure-cli
  ```
- **Windows:**
  Download and run the installer from [Install Azure CLI on Windows](https://learn.microsoft.com/cli/azure/install-azure-cli-windows)
- **Linux:**
  See [Install Azure CLI on Linux](https://learn.microsoft.com/cli/azure/install-azure-cli-linux)

For more details and troubleshooting, see the [official Azure CLI installation guide](https://learn.microsoft.com/cli/azure/install-azure-cli).

---

## 1 – Run the API Locally (optional)

Before deploying, confirm it works on your machine:

```bash
cd Notes
dotnet run
```

The API starts at **http://localhost:5107**. Try a quick test:

```bash
curl -X POST "http://localhost:5107/notes?category=work" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test","content":"Hello world"}'
```

---

## 2 – Log in to Azure

```bash
az login
```

If you have multiple subscriptions, set the one you want to use:

```bash
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

---

## 3 – Create a Resource Group

Pick a region (e.g. `australiaeast`) and replace `<UNIQUE_SUFFIX>` with something unique to you (e.g. your initials + 4 random digits like `ms1234`):

```bash
az group create --name rg-notes-<UNIQUE_SUFFIX> --location <REGION>
```

---

## 4 – Deploy Infrastructure with Bicep

The Bicep template in `_infra/main.bicep` creates:

- An **App Service Plan** (Linux, Free tier by default)
- An **App Service** (.NET 8)

Run the deployment using the same `<UNIQUE_SUFFIX>` you chose above:

```bash
az deployment group create \
  --resource-group rg-notes-<UNIQUE_SUFFIX> \
  --template-file _infra/main.bicep \
  --parameters appNameSuffix=<UNIQUE_SUFFIX>
```

Once complete, note the **webAppUrl** in the outputs – this is your live API URL.

> **Example output:**
> ```
> "outputs": {
>   "resourceGroupName": { "value": "rg-notes-ms1234" },
>   "webAppName":        { "value": "app-notes-ms1234" },
>   "webAppUrl":         { "value": "https://app-notes-ms1234.azurewebsites.net" }
> }
> ```

---

## 5 – Publish the Application Code

```bash
cd Notes
dotnet publish -c Release -o ./publish
```

Then zip-deploy to Azure:

```bash
cd publish && zip -r ../deploy.zip . && cd ..

az webapp deploy \
  --resource-group rg-notes-<UNIQUE_SUFFIX> \
  --name app-notes-<UNIQUE_SUFFIX> \
  --src-path deploy.zip \
  --type zip
```

Wait a minute for the app to start, then open the URL from step 4 in a browser – you should see the Swagger UI **or** a blank page (Swagger is only enabled in Development mode).

---

## 6 – Test with Postman

### 6.1 Create a Note

| Setting | Value |
|---------|-------|
| **Method** | `POST` |
| **URL** | `https://app-notes-<UNIQUE_SUFFIX>.azurewebsites.net/notes?category=work` |
| **Headers** | `Content-Type: application/json` |
| **Body** (raw JSON) | see below |

**Body:**

```json
{
  "title": "My First Note",
  "content": "Deployed to Azure!"
}
```

**Expected response** – `201 Created`:

```json
{
  "id": 1,
  "title": "My First Note",
  "content": "Deployed to Azure!",
  "category": "work",
  "createdAt": "2026-02-24T12:00:00Z"
}
```

### 6.2 Create Another Note (different category)

| Setting | Value |
|---------|-------|
| **Method** | `POST` |
| **URL** | `https://app-notes-<UNIQUE_SUFFIX>.azurewebsites.net/notes?category=personal` |
| **Body** | `{ "title": "Groceries", "content": "Buy milk and eggs" }` |

### 6.3 Get All Notes

| Setting | Value |
|---------|-------|
| **Method** | `GET` |
| **URL** | `https://app-notes-<UNIQUE_SUFFIX>.azurewebsites.net/notes` |

You should receive a JSON array with all notes you created.

### 6.4 Filter Notes by Category

| Setting | Value |
|---------|-------|
| **Method** | `GET` |
| **URL** | `https://app-notes-<UNIQUE_SUFFIX>.azurewebsites.net/notes?category=work` |

Only notes with `category == "work"` should appear.

---

## 7 – Clean Up Resources

When you're done, delete the resource group to avoid charges:

```bash
az group delete --name rg-notes-<UNIQUE_SUFFIX> --yes --no-wait
```

---

## Quick Reference – API Endpoints

| Method | Endpoint | Query Params | Body | Description |
|--------|----------|-------------|------|-------------|
| `POST` | `/notes` | `?category=work\|personal\|other` (optional, defaults to `other`) | `{ "title": "...", "content": "..." }` | Create a note |
| `GET` | `/notes` | `?category=work\|personal\|other` (optional) | – | List all notes (with optional filter) |

---

**Happy deploying!** If you run into issues, check the App Service logs:

```bash
az webapp log tail --resource-group rg-notes-<UNIQUE_SUFFIX> --name app-notes-<UNIQUE_SUFFIX>
```
