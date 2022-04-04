ARG OPENSEARCH_VERSION
FROM docker.io/opensearchproject/opensearch:${OPENSEARCH_VERSION}
RUN bin/opensearch-plugin install analysis-phonetic \
    && bin/opensearch-plugin install analysis-icu
