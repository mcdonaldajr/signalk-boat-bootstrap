# Publishing This Repository

The intended public repository is:

```text
https://github.com/mcdonaldajr/signalk-boat-bootstrap
```

When GitHub CLI authentication is working, publish it with:

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

After publishing, the curl install URL in `README.md` will work:

```bash
curl -fsSL https://raw.githubusercontent.com/mcdonaldajr/signalk-boat-bootstrap/main/scripts/install-ais-suite.sh -o install-ais-suite.sh
```

