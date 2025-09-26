# Decentralized API Keys

A blockchain-based marketplace for API services where developers can monetize their APIs through NFT-based access tokens with built-in usage tracking.

## Features

- **Service Registration**: Developers can list APIs with custom pricing and limits
- **NFT API Keys**: Transferable tokens representing API access rights
- **Usage Tracking**: Automated call counting and quota management
- **Period Renewal**: Automatic billing cycles with quota resets
- **Analytics Dashboard**: Comprehensive usage logs and statistics
- **Revenue Sharing**: Direct payments to API providers
- **Access Control**: Secure authentication through blockchain ownership

## Contract Functions

### Public Functions
- `register-api-service()`: List new API service with pricing
- `purchase-api-key()`: Buy NFT-based API access token
- `use-api-key()`: Consume API calls and log usage
- `transfer-api-key()`: Transfer NFT to another user
- `deactivate-service()`: Disable API service
- `update-service-pricing()`: Modify service pricing

### Read-Only Functions
- `get-service-info()`: View API service details
- `get-api-key-info()`: Check API key status and usage
- `get-usage-log()`: Retrieve usage history
- `check-key-validity()`: Verify key status and remaining calls

## Usage

Developers register services, users purchase NFT keys, consume API calls with automatic tracking, and renew subscriptions as needed.

## Monetization

Direct payment model where API providers receive immediate compensation for usage without intermediaries or complex billing systems.