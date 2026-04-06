# Automated Continuous Recon for Bug Bounty

This is the source for a simple docker image that is responsible for executing a recon pipeline on a number of given domains. Based on [this](https://bugbounty.info/Recon/Pipeline).

The container itself does not run the pipeline on regular intervals. **Scheduling should be handled by the host or another container**.

Interaction with the container occurs via the embedded flask server `C2C.py`. Endpoints are:

- `/add_target/<target_domain>`: Starts tracking of a new domain
- `/remove_target/<target_domain>`: Remove domain from tracking
- `/run_full_recon`: Execute the full pipeline on all domains
- `/run_quick_recon`: Execute quick subdomain enumeration on all domains

Required environment variables:
- SECRET_KEY: Authenticate request to C2C server
- TELEGRAM_API_TOKEN: Telegram bot API token, required for sending notifications via telegram
- TELEGRAM_CHAT_ID: ID for the chat to which send messages, required for sending notifications via telegram 

Outputs are stored in the `/recon` folder.
