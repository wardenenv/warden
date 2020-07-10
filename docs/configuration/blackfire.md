## Blackfire Profiling

For information on what Blackfire is, please see the [introduction to Blackfire](https://blackfire.io/docs/introduction) in Blackfire documentation.

Blackfire may be enabled on both `magento1` and `magento2` env types by adding the following to the project's `.env` file (or exporting them to environment variables prior to starting the environment):

```
WARDEN_BLACKFIRE=1

BLACKFIRE_CLIENT_ID=<client_id>
BLACKFIRE_CLIENT_TOKEN=<client_token>
BLACKFIRE_SERVER_ID=<server_id>
BLACKFIRE_SERVER_TOKEN=<server_token>
```

Note: You can obtain the IDs and Tokens used in the above from within your Blackfire account under Account Settings -> Credentials or from the credentials are of the environment you're pushing profile information into.

### CLI Tool

To use the Blackfire CLI Tool, you can run `warden blackfire [arguments]`.

For more information on the CLI tool, please see [Profiling CLI Commands](https://blackfire.io/docs/cookbooks/profiling-cli) in Blackfire's documentation. 
