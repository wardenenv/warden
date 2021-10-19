# Elasticsearch

[Elasticsearch](https://www.elastic.co/) is the native search engine and it must be configured since Magento 2.4 onwards.
[Elastic HQ](https://www.elastichq.org/) gives you complete control over your ElasticSearch clusters, nodes, indexes, and mappings.

## Configuration

To enable Elasticsearch in your project environment, add to your `.env` file:

```
WARDEN_ELASTICSEARCH=1
```

Make sure you're using the correct version:

```
ELASTICSEARCH_VERSION=...
```

## Web Interface

Elasticsearch and also ElasticHQ web interfaces associated with the project can be found at `elasticsearch` and `elastichq` subdomains (eg. `https://elasticsearch.magento2.test/` and `https://elastichq.magento2.test/`).
