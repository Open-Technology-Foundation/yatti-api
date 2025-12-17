# <img src="https://yatti.id/images/logo.svg" alt="YaTTI Logo" height="32" style="vertical-align: middle"> YaTTI - Indonesian Open Technology Foundation

**Building Indonesia's digital future through open technology, one project at a time.**

YaTTI (Yayasan Teknologi Terbuka Indonesia) has been democratizing technology access across Indonesia since 2014. We build practical open source tools that solve real problems—from AI-powered legal search to cultural knowledge preservation—while advocating for transparency and collaboration. With 72 repositories and 13 specialized knowledgebases, we're making technology work for everyone.

## Featured Projects

### API & CLI Tools
- **[yatti-api](https://github.com/Open-Technology-Foundation/yatti-api)** - Command-line interface for querying YaTTI knowledgebases with LLM-powered responses. Features multi-model support (GPT, Claude, Gemini), retry logic, GPG-verified updates, and 240+ tests.
- **[dejavu2-cli](https://github.com/Open-Technology-Foundation/dejavu2-cli)** - Elegant terminal interface for querying knowledge bases and interacting with LLMs. Your command-line gateway to AI.

### AI & Knowledge Infrastructure
- **[customkb](https://github.com/Open-Technology-Foundation/customkb)** - Build your own AI knowledge bases with vector search, semantic queries, and LLM integration. Powers all YaTTI knowledge systems.
- **[peraturan.go.id](https://github.com/Open-Technology-Foundation/peraturan.go.id)** - AI-powered search for 5,800+ Indonesian regulations. Transforms impenetrable legal PDFs into actionable insights for 66 million SMEs, law firms, and citizens.

### Knowledge Preservation
- **[appliedanthropology](https://github.com/Open-Technology-Foundation/appliedanthropology)** - 777,000+ documents bridging anthropology, evolution, and cultural studies. Making academic knowledge accessible.
- **[seculardharma](https://github.com/Open-Technology-Foundation/seculardharma)** - Ancient wisdom meets modern science. Ethical living resources for the "spiritual but not religious" demographic.

### Developer Tools
- **[en_ID](https://github.com/Open-Technology-Foundation/en_ID)** - The missing English (Indonesia) locale. Proper date, time, and currency formatting for software used in Indonesia.
- **[md2ansi](https://github.com/Open-Technology-Foundation/md2ansi)** - Beautiful markdown rendering in your terminal. Tables, syntax highlighting, custom themes—because terminals deserve good typography.
- **[rtfm](https://github.com/Open-Technology-Foundation/rtfm)** - Smart documentation search that actually finds what you're looking for. "Read The Fine Manual" made easy.
- **[checkpoint](https://github.com/Open-Technology-Foundation/checkpoint)** - Intelligent backup system for developers. Never lose work again.

### System Utilities
Browse our [full repository list](https://github.com/Open-Technology-Foundation) for specialized tools including process monitors, time utilities, and shell enhancements.

## Knowledgebases

YaTTI maintains 13 specialized knowledgebases covering Indonesian law, anthropology, philosophy, and culture:

| Knowledgebase | Description |
|---------------|-------------|
| **[peraturan.go.id](https://yatti.id)** | Indonesian laws and regulations (5,800+ documents) |
| **[appliedanthropology](https://yatti.id)** | 777,000+ scholarly documents on evolution, culture, and dharma |
| **[seculardharma](https://yatti.id)** | Secular dharma philosophy and ethical living |
| **[wayang.net](https://yatti.id)** | Indonesian wayang culture and traditional performing arts |

Query any knowledgebase via the [yatti-api CLI](#api-access) or [REST API](https://yatti.id/v1/help).

## API Access

### Using yatti-api CLI (Recommended)

The easiest way to query YaTTI knowledgebases:

```bash
# Install yatti-api
curl -fsSL https://yatti.id/v1/client/download -o yatti-api && chmod +x yatti-api
sudo mv yatti-api /usr/local/bin/

# Configure your API key
yatti-api configure

# Query Indonesian regulations
yatti-api query -K peraturan.go.id -q "pajak UMKM"

# Get anthropology insights
yatti-api query -K appliedanthropology -q "cultural evolution"

# List available knowledgebases
yatti-api kb list
```

### Using REST API

For programmatic access, use the REST API with authentication:

```bash
# Set your API key
export YATTI_API_KEY="your-api-key"

# Search Indonesian regulations
curl -s -H "Authorization: Bearer $YATTI_API_KEY" \
  "https://yatti.id/v1/peraturan.go.id?q=pajak%20umkm" | jq

# List all available knowledge bases
curl -s -H "Authorization: Bearer $YATTI_API_KEY" \
  "https://yatti.id/v1/list" | jq
```

Full API documentation: [https://yatti.id/v1/help](https://yatti.id/v1/help)

## Get Involved

### For Developers
- **Contribute**: Pick any repository and dive in. We welcome PRs that align with our open technology mission.
- **Build**: Use our tools as foundations for your own projects. Everything is MIT/GPL licensed.
- **Learn**: Our codebases demonstrate practical AI implementation, vector search, and clean architecture.

### For Organizations
- **Adopt**: Our tools are production-ready and serving millions. Free to use, modify, and deploy.
- **Partner**: Collaborate on open technology initiatives that benefit Indonesian communities.
- **Support**: Help sustain our infrastructure and development efforts.

### For Citizens
- **Use**: Access legal information, cultural knowledge, and powerful tools—all free.
- **Share**: Spread awareness about open technology alternatives.
- **Advocate**: Push for transparency and openness in your communities.

## Our Approach

We believe sustainable progress comes from:
- **Open Source** - Every line of code freely available
- **Open Data** - Public information as public resource
- **Open Standards** - Interoperability over vendor lock-in
- **Open Science** - Knowledge sharing for collective advancement
- **Open Governance** - Transparent decision-making
- **Open Commons** - Shared resources for collective benefit

Read our detailed [position papers](https://yatti.id/statements/) on each principle.

## Connect

- **Website**: [https://yatti.id](https://yatti.id)
- **Email**: admin@yatti.id
- **Location**: Jakarta, Indonesia
- **Established**: April 28, 2014

---

*YaTTI - Membuka Teknologi, Membuka Kesempatan*
*Opening Technology, Opening Opportunities*
