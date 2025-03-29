from flask import Flask, request
from twilio.twiml.messaging_response import MessagingResponse
import requests
import re
import time
from difflib import SequenceMatcher
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Replace with your new Twilio credentials
ACCOUNT_SID = 'your_new_account_sid_here'  # Replace with your new Account SID
AUTH_TOKEN = 'your_new_auth_token_here'    # Replace with your new Auth Token
TWILIO_PHONE = 'whatsapp:+14155238886'     # Replace with your new sandbox number
VT_API_KEY = '083d3077c5a690fe13ce7180cc36ebd6f063dc6e278fc4f8ad00a78029e0a7a8'
GOOGLE_SAFE_BROWSING_API_KEY = 'AIzaSyDCiIhZKVFYMM5J3PXwsJ9mT7DbFJ0ny5g'
app = Flask(__name__)

# Expanded list of known safe domains
KNOWN_SAFE_DOMAINS = [
    'google.com', 'facebook.com', 'amazon.com', 'microsoft.com', 'apple.com',
    'twitter.com', 'instagram.com', 'linkedin.com', 'paypal.com', 'netflix.com',
    'yahoo.com', 'gmail.com', 'outlook.com', 'ebay.com', 'wikipedia.org'
]

# Store user conversation state
user_states = {}

# Welcome message with menu
WELCOME_MESSAGE = (
    "👋 Welcome to the Safe URL Bot! I can help you stay safe online.\n\n"
    "Please choose an option:\n"
    "1️⃣ Check a URL for phishing\n"
    "2️⃣ Learn about phishing\n"
    "3️⃣ Get help\n"
    "4️⃣ Exit\n\n"
    "Reply with the number (e.g., 1) to select an option."
)

# Extract URL from message
def extract_url(message):
    url_pattern = r'(https?://[^\s]+)'
    urls = re.findall(url_pattern, message)
    return urls[0] if urls else None

# Extract and normalize domain from URL
def extract_domain(url):
    match = re.search(r'https?://([^/]+)', url)
    domain = match.group(1) if match else url
    if domain.startswith('www.'):
        domain = domain[4:]
    return domain

# Check for typosquatting
def is_typosquatting(domain):
    # Exact match with a known safe domain
    if domain.lower() in [d.lower() for d in KNOWN_SAFE_DOMAINS]:
        logger.info(f"Domain {domain} is an exact match with a known safe domain.")
        return False, None
    
    # Check for typosquatting
    for safe_domain in KNOWN_SAFE_DOMAINS:
        similarity = SequenceMatcher(None, domain.lower(), safe_domain.lower()).ratio()
        logger.info(f"Similarity between {domain} and {safe_domain}: {similarity}")
        if 0.90 <= similarity < 0.98:  # Adjusted threshold to reduce false positives
            logger.warning(f"Typosquatting detected: {domain} is similar to {safe_domain}")
            return True, f"⚠️ Warning: The domain '{domain}' closely resembles '{safe_domain}', a well-known safe domain. This may indicate a phishing attempt. Please proceed with caution."
    return False, None

# Check URL with Google Safe Browsing
def check_url_with_google_safe_browsing(url):
    logger.info(f"Checking {url} with Google Safe Browsing")
    start_time = time.time()
    try:
        api_url = 'https://safebrowsing.googleapis.com/v4/threatMatches:find'
        payload = {
            "client": {
                "clientId": "whatsappbot",
                "clientVersion": "1.0.0"
            },
            "threatInfo": {
                "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"],
                "platformTypes": ["ANY_PLATFORM"],
                "threatEntryTypes": ["URL"],
                "threatEntries": [{"url": url}]
            }
        }
        params = {'key': GOOGLE_SAFE_BROWSING_API_KEY}
        response = requests.post(api_url, json=payload, params=params, timeout=5)
        if response.status_code != 200:
            logger.error(f"Google Safe Browsing error: {response.status_code}")
            return False, "Error checking with Google Safe Browsing."
        
        result = response.json()
        if 'matches' in result:
            logger.info(f"Google Safe Browsing flagged {url} as dangerous: {result['matches']}")
            return True, f"⚠️ Warning: The URL '{url}' is flagged as dangerous by Google Safe Browsing and may be a phishing or malicious link."
        logger.info(f"Google Safe Browsing took {time.time() - start_time:.2f} seconds")
        return False, None
    except requests.Timeout:
        logger.error("Google Safe Browsing timed out")
        return False, "Google Safe Browsing timed out."
    except Exception as e:
        logger.error(f"Google Safe Browsing error: {str(e)}")
        return False, f"Error checking with Google Safe Browsing: {str(e)}"

# Check URL with VirusTotal
def check_url_with_virustotal(url):
    logger.info(f"Checking {url} with VirusTotal")
    start_time = time.time()
    try:
        vt_url = 'https://www.virustotal.com/api/v3/urls'
        headers = {'x-apikey': VT_API_KEY}
        
        payload = {'url': url}
        response = requests.post(vt_url, headers=headers, data=payload, timeout=5)
        if response.status_code != 200:
            logger.error(f"VirusTotal submission error: {response.status_code}")
            return False, "Error submitting URL to VirusTotal."
        
        analysis_id = response.json()['data']['id']
        
        analysis_url = f'https://www.virustotal.com/api/v3/analyses/{analysis_id}'
        for _ in range(5):
            response = requests.get(analysis_url, headers=headers, timeout=5)
            if response.status_code != 200:
                logger.error(f"VirusTotal analysis error: {response.status_code}")
                return False, "Error retrieving analysis from VirusTotal."
            
            analysis = response.json()['data']['attributes']
            status = analysis.get('status')
            if status == 'completed':
                break
            time.sleep(1)
        
        if status != 'completed':
            logger.warning("VirusTotal analysis timed out")
            return False, "VirusTotal analysis timed out."
        
        result = analysis['stats']
        malicious = result.get('malicious', 0)
        suspicious = result.get('suspicious', 0)
        
        # Require at least 2 malicious or suspicious reports to flag as phishing
        if (malicious + suspicious) >= 2:
            logger.info(f"VirusTotal flagged {url} as malicious/suspicious: {malicious} malicious, {suspicious} suspicious")
            return True, f"⚠️ Warning: The URL '{url}' is flagged as potentially phishing or malicious by VirusTotal ({malicious} malicious, {suspicious} suspicious reports)."
        logger.info(f"VirusTotal took {time.time() - start_time:.2f} seconds")
        return False, None
    except requests.Timeout:
        logger.error("VirusTotal timed out")
        return False, "VirusTotal timed out."
    except Exception as e:
        logger.error(f"VirusTotal error: {str(e)}")
        return False, f"Error checking with VirusTotal: {str(e)}"

@app.route('/whatsapp', methods=['POST'])
def whatsapp_bot():
    logger.info("Received a new message")
    start_time = time.time()
    
    sender = request.values.get('From', '')
    incoming_msg = request.values.get('Body', '').strip().lower()
    resp = MessagingResponse()
    msg = resp.message()

    # Reset to start state if user sends "hello" in any state
    if incoming_msg == 'hello':
        user_states[sender] = {'state': 'start'}

    if sender not in user_states:
        user_states[sender] = {'state': 'start'}

    state = user_states[sender]['state']
    logger.info(f"User {sender} is in state: {state}, message: {incoming_msg}")

    if state == 'start':
        msg.body(WELCOME_MESSAGE)
        user_states[sender]['state'] = 'menu'
    
    elif state == 'menu':
        if incoming_msg == '1':
            msg.body("🔗 Please send the URL you want to check (e.g., https://example.com).")
            user_states[sender]['state'] = 'check_url'
        elif incoming_msg == '2':
            msg.body(
                "📚 **What is Phishing?**\n"
                "Phishing is a scam where attackers trick you into giving sensitive information (like passwords) by pretending to be a trusted source.\n"
                "Common signs:\n"
                "- Misspelled URLs (e.g., faceb00k.com)\n"
                "- Urgent or threatening messages\n"
                "- Requests for personal info\n\n"
                "Reply '1' to check a URL or '0' to return to the menu."
            )
            user_states[sender]['state'] = 'learn_phishing'
        elif incoming_msg == '3':
            msg.body(
                "ℹ️ **Help**\n"
                "I can help you stay safe online! Choose an option from the menu to get started.\n"
                "- To check a URL, select 1\n"
                "- To learn about phishing, select 2\n"
                "- To exit, select 4\n\n"
                "Reply '0' to return to the menu."
            )
            user_states[sender]['state'] = 'help'
        elif incoming_msg == '4':
            msg.body("👋 Goodbye! Stay safe online. Reply 'hello' to start again.")
            user_states[sender]['state'] = 'exit'
        else:
            msg.body("❓ Please select a valid option (1, 2, 3, or 4).")
    
    elif state == 'check_url':
        url = extract_url(incoming_msg)
        if url:
            domain = extract_domain(url)
            logger.info(f"Checking URL: {url}, Domain: {domain}")
            
            # Check for typosquatting
            is_suspicious, typosquatting_message = is_typosquatting(domain)
            if is_suspicious:
                msg.body(typosquatting_message)
            else:
                # Check with VirusTotal
                vt_is_malicious, vt_message = check_url_with_virustotal(url)
                if vt_is_malicious:
                    msg.body(vt_message)
                else:
                    # Check with Google Safe Browsing
                    gsb_is_malicious, gsb_message = check_url_with_google_safe_browsing(url)
                    if gsb_is_malicious:
                        msg.body(gsb_message)
                    else:
                        msg.body(f"✅ The URL '{url}' appears to be safe according to VirusTotal and Google Safe Browsing.")
            msg.body("\nReply '1' to check another URL or '0' to return to the menu.")
            user_states[sender]['state'] = 'check_another_url'
        else:
            msg.body("❌ Please send a valid URL (e.g., https://example.com).")
    
    elif state == 'check_another_url':
        if incoming_msg == '1':
            msg.body("🔗 Please send the URL you want to check (e.g., https://example.com).")
            user_states[sender]['state'] = 'check_url'
        elif incoming_msg == '0':
            msg.body(WELCOME_MESSAGE)
            user_states[sender]['state'] = 'menu'
        else:
            msg.body("❓ Please reply '1' to check another URL or '0' to return to the menu.")

    elif state == 'learn_phishing' or state == 'help':
        if incoming_msg == '0':
            msg.body(WELCOME_MESSAGE)
            user_states[sender]['state'] = 'menu'
        elif incoming_msg == '1':
            msg.body("🔗 Please send the URL you want to check (e.g., https://example.com).")
            user_states[sender]['state'] = 'check_url'
        else:
            msg.body("❓ Please reply '1' to check a URL or '0' to return to the menu.")

    elif state == 'exit':
        if incoming_msg == 'hello':
            msg.body(WELCOME_MESSAGE)
            user_states[sender]['state'] = 'menu'
        else:
            msg.body("👋 Reply 'hello' to start again.")

    logger.info(f"Processed message in {time.time() - start_time:.2f} seconds")
    return str(resp)

if __name__ == '__main__':
    app.run(debug=True, port=5000)