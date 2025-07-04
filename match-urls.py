import pandas as pd
import numpy as np
import requests
from sentence_transformers.util import cos_sim
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm

MODEL = "mxbai-embed-large"
OLLAMA_URL = "http://localhost:11434/api/embeddings"
THREADS = 8
TIMEOUT = 20

# Load and normalize
orc = pd.read_csv("old.domain.com.csv")
off = pd.read_csv("new.domain.com.csv")
orc.columns = orc.columns.str.strip().str.lower()
off.columns = off.columns.str.strip().str.lower()
orc_titles = orc["title"].astype(str).str.strip().tolist()
off_titles = off["title"].astype(str).str.strip().tolist()

# Embed one title via Ollama
def embed_ollama(prompt):
    try:
        r = requests.post(OLLAMA_URL, json={"model": MODEL, "prompt": prompt}, timeout=TIMEOUT)
        r.raise_for_status()
        return r.json()["embedding"]
    except Exception as e:
        print(f"⚠️ Failed to embed: {prompt[:30]}... — {e}")
        return None

# Embed all titles in parallel
def embed_parallel(titles, label):
    embeddings = [None] * len(titles)
    with ThreadPoolExecutor(max_workers=THREADS) as executor:
        futures = {executor.submit(embed_ollama, title): i for i, title in enumerate(titles)}
        for future in tqdm(as_completed(futures), total=len(titles), desc=f"🔁 Embedding {label}"):
            i = futures[future]
            try:
                embeddings[i] = future.result()
            except:
                embeddings[i] = None
    return embeddings

# Embed with progress
orc_embeddings = embed_parallel(orc_titles, "old.domain.com")
off_embeddings = embed_parallel(off_titles, "new.domain.com")

# Filter out bad rows
orc_valid = [(i, e) for i, e in enumerate(orc_embeddings) if e]
orc_ids, orc_vecs = zip(*orc_valid)

# Match each new.domain.com title to best match
matches = []
for i, off_emb in enumerate(tqdm(off_embeddings, desc="🔍 Matching")):
    if off_emb is None:
        matches.append((off.iloc[i]["link"], off.iloc[i]["title"], "", 0))
        continue

    sims = cos_sim(np.array([off_emb]), np.array(orc_vecs))[0]
    best_idx = int(np.argmax(sims))
    score = float(sims[best_idx])
    best_url = orc.iloc[orc_ids[best_idx]]["url"]

    print(f"✅ {off.iloc[i]['title'][:40]} → {best_url} ({score:.2f})")
    matches.append((off.iloc[i]["link"], off.iloc[i]["title"], best_url, score))

# Export to Yoast format
df = pd.DataFrame(matches, columns=["old_link", "old_title", "matched_url", "score"])
df["old_path"] = df["old_link"].str.replace("https://www.new.domain.com", "", regex=False)
df["type"] = "301"
df.to_csv("yoast_redirects_semantic.csv", index=False, columns=["old_path", "matched_url", "type", "score"])

print("✅ Done! Saved to yoast_redirects_semantic.csv")
