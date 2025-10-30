import os, requests, datetime, collections
from dateutil import tz

REPO = os.environ["REPO"]
TOKEN = os.environ["METRICS_TOKEN"]
owner, repo = REPO.split("/")
SINCE = (datetime.datetime.utcnow() - datetime.timedelta(days=14)).isoformat() + "Z"

S = requests.Session()
S.headers.update({
    "Authorization": f"Bearer {TOKEN}",
    "Accept": "application/vnd.github+json",
})

def get(url, params=None):
    r = S.get(url, params=params or {})
    r.raise_for_status()
    return r.json()

def search_count(q):
    r = get("https://api.github.com/search/issues", {"q": q})
    return r.get("total_count", 0)

# Totals
repo_info = get(f"https://api.github.com/repos/{owner}/{repo}")
stars = repo_info.get("stargazers_count", 0)
forks = repo_info.get("forks_count", 0)

# 14d deltas
issues_open = search_count(f"repo:{owner}/{repo} is:issue created:>={SINCE}")
issues_closed = search_count(f"repo:{owner}/{repo} is:issue closed:>={SINCE}")

prs_open = search_count(f"repo:{owner}/{repo} is:pr created:>={SINCE}")
prs_merged = search_count(f"repo:{owner}/{repo} is:pr is:merged merged:>={SINCE}")
prs_closed = search_count(f"repo:{owner}/{repo} is:pr is:closed -is:merged closed:>={SINCE}")

# Active contributors in last 14d (unique commit authors)
authors = set()
commits = get(f"https://api.github.com/repos/{owner}/{repo}/commits", {"since": SINCE})
for c in commits:
    a = c.get("author")
    if a and a.get("login"):
        authors.add(a["login"])
active_contributors = len(authors)

views_total = views_unique = clones_total = clones_unique = 0
try:
    views = get(f"https://api.github.com/repos/{owner}/{repo}/traffic/views")
    clones = get(f"https://api.github.com/repos/{owner}/{repo}/traffic/clones")
    views_total = sum(v["count"] for v in views.get("views", []))
    views_unique = views.get("uniques", 0)
    clones_total = sum(v["count"] for v in clones.get("clones", []))
    clones_unique = clones.get("uniques", 0)
except requests.HTTPError as e:
    if e.response is not None and e.response.status_code == 403:
        print("Note: Traffic API not accessible with this token; continuing without traffic metrics.")
    else:
        raise

# Downloads
releases = get(f"https://api.github.com/repos/{owner}/{repo}/releases")
downloads_total = 0
latest_dl = 0
latest_tag = "-"
if isinstance(releases, list) and releases:
    for r in releases:
        for a in r.get("assets", []):
            downloads_total += a.get("download_count", 0)
    latest = releases[0]
    latest_tag = latest.get("tag_name") or latest.get("name") or "-"
    latest_dl = sum(a.get("download_count", 0) for a in latest.get("assets", []))

# Timestamp
now = datetime.datetime.now(tz=tz.gettz("America/New_York")).strftime("%b %d, %Y %I:%M %p %Z")

html = f"""<!DOCTYPE html>
<html>
<head><meta charset='utf-8'><title>{REPO} Metrics</title></head>
<body style="font-family:Arial, sans-serif;">
<h2>{REPO} – Biweekly Metrics Report</h2>
<p><strong>Generated:</strong> {now}</p>
<table border="1" cellspacing="0" cellpadding="6">
<tr><th align="left">Metric</th><th align="left">Value</th></tr>
<tr><td>Stars</td><td>{stars}</td></tr>
<tr><td>Forks</td><td>{forks}</td></tr>
<tr><td>Issues opened / closed (14 d)</td><td>{issues_open} / {issues_closed}</td></tr>
<tr><td>PRs opened / merged / closed (14 d)</td><td>{prs_open} / {prs_merged} / {prs_closed}</td></tr>
<tr><td>Active contributors (14 d)</td><td>{active_contributors}</td></tr>
<tr><td>Traffic (views / uniques)</td><td>{views_total} / {views_unique}</td></tr>
<tr><td>Clones (total / uniques)</td><td>{clones_total} / {clones_unique}</td></tr>
<tr><td>Downloads (latest release)</td><td>{latest_dl} ({latest_tag})</td></tr>
<tr><td>Downloads (all releases)</td><td>{downloads_total}</td></tr>
</table>
</body></html>"""

with open("metrics_report.html","w",encoding="utf-8") as f:
    f.write(html)
print("✅ metrics_report.html created")
