# Publishing This Repository

The public repository is:

```text
https://github.com/mcdonaldajr/signalk-boat-bootstrap
```

For normal updates, commit locally and push:

```bash
git push origin main
```

If the repository ever needs to be recreated, GitHub CLI can publish it with:

```bash
gh repo create mcdonaldajr/signalk-boat-bootstrap \
  --public \
  --source=. \
  --remote=origin \
  --push
```

If `gh auth status` reports an invalid token, refresh authentication first:

```bash
gh auth login -h github.com
```

The curl install URL in `README.md` uses:

```bash
curl -fsSL https://raw.githubusercontent.com/mcdonaldajr/signalk-boat-bootstrap/main/scripts/install-ais-suite.sh -o install-ais-suite.sh
```
