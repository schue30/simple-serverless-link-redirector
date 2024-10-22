import json
from datetime import datetime

REDIRECT_TEXT = """
<html>
<head><title>302 Found</title></head>
<body>
<center><h1>302 Found</h1></center>
</body>
</html>
""".strip()

NOT_FOUND_TEXT = """
<html>
<head><title>404 Not Found</title></head>
<body>
<center><h1>404 Not Found</h1></center>
</body>
</html>
""".strip()


def lambda_handler(event, context):
    redirects = {
        'link.mathias.schuepany.at': {  # subdomain
            '/demo': {  # path start with
                'campaign': 'example',
                'destination': 'https://mathias.schuepany.at/demo'
            }
        },
        '*': {  # default action if none matches
            '*': {
                'campaign': 'default',
                'destination': 'https://mathias.schuepany/default'
            }
        }
    }

    matching_redirect = None
    if domain_redirects := redirects.get(event['requestContext']['domainName']):
        for path, destination_obj in domain_redirects.items():
            if event['requestContext']['path'].startswith(path):
                matching_redirect = destination_obj
    elif '*' in redirects and '*' in redirects['*']:
        matching_redirect = redirects['*']['*']

    print(json.dumps({
        'timestamp': datetime.strptime(event['requestContext']['requestTime'], "%d/%b/%Y:%H:%M:%S %z").isoformat(),
        'campaign': matching_redirect['campaign'],
        'ip_address': event['requestContext']['identity']['sourceIp'],
    }))

    return {
        'statusCode': 302 if matching_redirect else 404,
        'body': REDIRECT_TEXT if matching_redirect else NOT_FOUND_TEXT,
        'headers':
            {
                'Content-Type': 'text/html',
                'Cache-Control': 'no-store, no-cache, must-revalidate',
                'Expires': 'Thu, 01 Jan 1970 00:00:00 GMT'
            } | ({'Location': matching_redirect['destination']} if matching_redirect else {})
    }
