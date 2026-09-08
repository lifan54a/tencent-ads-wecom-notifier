# Tencent Leads Platform API notes

Authoritative guide: https://leads.qq.com/assets/doc/api_guide.pdf

## Pull endpoint

- Method: `GET`
- URL: `https://leads.qq.com/api/mv1/leads/list`
- Required query fields: `start_time`, `end_time`
- Optional query fields: `time_type`, `page`, `page_size`, `search_after_leads_id`
- `time_type=0` selects lead submission time; `time_type=1` selects platform ingestion time.
- `page_size` must not exceed 200.
- Results default to descending `leads_create_time` order.

## Current signature

Generate a unique nonce of at most 32 characters and a ten-digit Unix timestamp within five minutes of server time.

For SHA256:

```text
digest = sha256(token + "." + timestamp + "." + secret)
X-Signature = base64(token + "," + timestamp + "," + nonce + "," + digest)
X-Signature-Algorithm = SHA256
```

The older three-element signature is documented but not recommended for advertiser-initiated pulls.

## Response

HTTP 200 can still contain a business error. Always inspect `code`:

- `0`: success
- `1100-1199`: internal error range documented by the platform
- `2000-2100`: permission or authentication error range
- `2100-2200`: parameter error range

Successful list responses contain `data.page_info` and `data.list`. Use `leads_id` as the durable de-duplication key. Do not log complete response bodies because lead records can contain direct personal information.

