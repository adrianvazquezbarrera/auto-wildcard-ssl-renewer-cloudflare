# Auto Wildcard SSL Renewer (Cloudflare + Traefik)

A Docker-based utility for automatically obtaining and renewing wildcard SSL certificates using Let's Encrypt and Cloudflare DNS validation. This tool generates certificates and configures them for use with a traefik reverse proxy. With this tool, you can easily manage SSL certificates for your wildcard domains, **even if your domain is pointing to private IP addresses.**

## 📌 Table of Contents

- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Setup](#-setup)
- [Project Structure](#-project-structure)
- [Certificate Renewal](#-certificate-renewal)
- [Traefik Integration](#-traefik-integration)
- [Troubleshooting](#-troubleshooting)
- [Warnings](#-warning)

## 🚀 Features

- **Wildcard Certificate Support**: Obtain SSL certificates for wildcard domains (e.g., `*.example.com`)
- **Cloudflare DNS Validation**: Validates domain ownership via DNS records, allowing certificate issuance even when the domain points to **private IPs**
- **Traefik Integration**: Generates ready-to-use configuration files for Traefik
- **Docker-based**: Simple, containerized deployment
- **Persistent Storage**: Certificates are stored in mounted volumes

## 📋 Prerequisites

- Docker and Docker Compose installed
- A domain managed by Cloudflare
- Cloudflare API token with DNS edit permissions

## 🔧 Setup

### 1. Clone the Repository

```bash
git clone https://github.com/adrianvazquezbarrera/auto-wildcard-ssl-renewer-cloudflare.git

cd auto-wildcard-ssl-renewer-cloudflare
```

### 2. Getting Your Cloudflare API Token

1. Log in to your Cloudflare account
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Use the **Edit zone DNS** template or create a custom token with:
   - Permissions: `Zone` → `DNS` → `Edit`
   - Zone Resources: Include your specific zone
5. Copy the generated token to your `.env` file

### 3. Export Environment Variables

```bash
export CLOUDFLARE_API_TOKEN=your_cloudflare_api_token_here
export DOMAIN=*.example.com,example.com
export PRIMARY_DOMAIN=example.com
export BASE_CERT_PATH=/certificates/example.com
```

**Note**: Your `PRIMARY_DOMAIN` should be the non-wildcard version of the first domain in your `DOMAIN` list.

### 4. Run the Certificate Request Script

```bash
./request-certificate.sh
```

This script will:

1. Build the Docker image
2. Start the container
3. Request the wildcard SSL certificate via Let's Encrypt
4. Validate domain ownership via Cloudflare DNS
5. Save certificates to the `certificates/` directory along with the Traefik configuration file

## 📁 Project Structure

```
├── compose.yml              # Docker Compose configuration
├── Dockerfile               # Container image definition
├── entrypoint.sh           # Main certificate request logic
├── request-certificate.sh  # Convenience script to run the process
├── .env                    # Environment variables (create this)
├── certificates/           # Generated SSL certificates
│   └── <domain>/
│       ├── certificate.yml # Traefik configuration
│       ├── chain.crt       # Full certificate chain
│       └── privkey.key     # Private key
└── README.md               # This documentation
```

## 🔄 Certificate Renewal

Let's Encrypt certificates are valid for 90 days. To renew your certificates:

```bash
./request-certificate.sh
```

Certbot will automatically detect existing certificates and renew them if they're due for renewal (within 30 days of expiration).

### Automated Renewal

You can automate renewal by setting up a cron job:

```bash
# Edit crontab
crontab -e

# Add this line to run renewal check weekly (Sundays at 3 AM)
0 3 * * 0 cd /path/to/auto-wildcard-ssl-renewer && ./request-certificate.sh >> /var/log/ssl-renewal.log 2>&1
```

## 🔗 Traefik Integration

The utility generates a `certificate.yml` file in the certificates directory, which can be used with Traefik's dynamic configuration.

## 🐳 Dokploy Integration

1.  SSH into your dokploy server.
2.  Clone this repository into the folowing path: `/etc/dokploy/auto-wildcard-ssl-renewer-cloudflare`
3.  Create a symbolic link to the dokploy certificates directory:

    ```bash
    ln -sf /etc/dokploy/traefik/dynamic/certificates /etc/dokploy/auto-wildcard-ssl-renewer-cloudflare/certificates
    ```

    Now, the generated certificates will be directly available to dokploy's traefik setup. You can verify this by checking the files in Dokploy's dashboard: `Home` -> `Traefik File System` -> `dynamic` -> `certificates`.

4.  Go to the dokploy dashboard and navigate to `Home` -> `Schedules` -> `Add Schedule`.

5.  Set up a schedule to run the renewal script weekly:

    - **Name**: SSL Certificate Renewal
    - **Frequency**: Daily
    - **Time**: 00:00 AM
    - **Command**:

    ```bash
      #!/bin/sh
      set -e

      # Note: Cloudflare API token and email
      # shouln't be hardcoded here. You are seeing
      # this for demonstration purposes only.
      # You should use system's environment variable management instead.
      export CLOUDFLARE_API_TOKEN=your_cloudflare_api_token_here
      export EMAIL=your_email@example.com
      export BASE_CERT_PATH=/etc/dokploy/traefik/dynamic/certificates

      # We recommend you to set these environment variables here
      # because they are scoped to this scheduled task only.
      export PRIMARY_DOMAIN=private.example.com
      export DOMAIN=*.private.example.com,*.example.com

      /etc/dokploy/auto-wildcard-ssl-renewer-cloudflare/request-certificate.sh

      echo "*.private.example.com SSL updated!"
    ```

Caveat: When setting a domain in the `Projects` -> `<Your Project Name>` -> `environment` -> `<Your application name>` -> `Domains`, make sure to select **HTTPS** and set the certificate provider to **None** since the SSL certificate will be managed by .crt and .key files.

## 🛠️ Troubleshooting

### Certificate Request Fails

**Issue**: Certificate request fails with DNS validation error

**Solution**:

- Verify your Cloudflare API token has the correct permissions
- Ensure the domain is correctly configured in Cloudflare
- Check that DNS propagation time is sufficient (default: 60 seconds)

### Docker Build Fails

**Issue**: Docker build or compose fails

**Solution**:

- Ensure Docker and Docker Compose are installed and up to date
- Check that you have sufficient permissions to run Docker commands
- Try: `docker compose down` and then rebuild

### Certificates Not Appearing

**Issue**: Certificates directory is empty after running

**Solution**:

- Check Docker container logs: `docker logs certbot`
- Verify environment variables in `.env` file
- Ensure the `PRIMARY_DOMAIN` matches your certificate's common name

### Certificate Overwrite Issues

If you tried to use SSL earlier with the default Dokploy setup, probably you will now encounter SSL errors, since both certificates may conflict.

If you face this issue, carefully remove the previously set SSL, they are available here: `Home` -> `Traefik File System` -> `dynamic` -> `acme.json`.

**WARNING**: Be cautious when deleting certificates from `acme.json`, as it contains also the SSL certificates for the main dokploy app. Deleting it may break your Traefik instance, preventing access to your applications.

## 📝 Environment Variables Reference

| Variable               | Description                                              | Example                                        |
| ---------------------- | -------------------------------------------------------- | ---------------------------------------------- |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token with DNS edit permissions           | `abc123...`                                    |
| `DOMAIN`               | Domain(s) for certificate (comma-separated for multiple) | `*.example.com` or `*.example.com,example.com` |
| `PRIMARY_DOMAIN`       | Primary domain name (without wildcard)                   | `example.com`                                  |
| `BASE_CERT_PATH`       | Path where Traefik will find certificates                | `/certificates/example.com`                    |

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

## ⚠️ Warnings

**Note**: This tool uses Let's Encrypt's production servers. Be aware of [Let's Encrypt's rate limits](https://letsencrypt.org/docs/rate-limits/) when testing.
