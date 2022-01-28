# Elasticsearch

Warden supports use of Elasticsearch. It is enabled by default on some environments such as `magento2` where it is a baseline requirement for the application, but it can be enabled and used on other environments types such as `shopware` and `symfony` as an optional service. Please refer to specific installation guides for configuration specific to a given application.

[Elasticsearch](https://www.elastic.co/) is a leading free and open search and analytics solution built on Apache Lucene.
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

Elasticsearch and also ElasticHQ web interfaces associated with the project can be found at `elasticsearch` and `elastichq` subdomains (eg. `https://elasticsearch.exampleproject.test/` and `https://elastichq.exampleproject.test/`).
