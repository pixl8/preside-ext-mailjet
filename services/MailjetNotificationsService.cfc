/**
 * @singleton
 * @presideservice
 *
 */
component {

	/**
	 * @emailLoggingService.inject emailLoggingService
	 *
	 */
	public any function init(
		  required any emailServiceProviderService
		, required any emailLoggingService
	) {
		_setEmailServiceProviderService( arguments.emailServiceProviderService );
		_setEmailLoggingService( arguments.emailLoggingService );
		_setupErrorCodes();

		return this;
	}

// PUBLIC API METHODS
	public void function processEvents( required array events ) {
		for ( var event in events ) {
			processEvent( event );
		}
	}

	public void function processEvent( required struct event ){
		var loggingService = _getEmailLoggingService();
		var eventType      = arguments.event.event    ?: "";
		var messageId      = arguments.event.customID ?: "";

		if ( !messageId.len() ) {
			return;
		}

		switch( eventType ) {
			case "open":
				loggingService.markAsOpened( id=messageId );
			break;
			case "sent":
				loggingService.markAsDelivered( id=messageId );
			break;
			case "bounce":
			case "blocked":
				var hardBounced  = IsBoolean( arguments.event.hard_bounce ?: "" ) && arguments.event.hard_bounce;
				var errorDetails = _getErrorDetails( arguments.event );

				if ( hardBounced ) {
					loggingService.markAsFailed(
						  id     = messageId
						, reason = errorDetails.description ?: ""
						, code   = errorDetails.code        ?: ""
					);
				} else {
					loggingService.markAsHardBounced(
						  id     = messageId
						, reason = errorDetails.description ?: ""
						, code   = errorDetails.code  ?: ""
					);
				}
			break;
			case "unsub":
				loggingService.markAsUnsubscribed( id=messageId );
			break;
			case "spam":
				loggingService.markAsMarkedAsSpam( id=messageId );
			break;
			case "click":
				loggingService.recordClick( id=messageId, link=arguments.event.url ?: "" );
			break;
		}
		return true;
	}

// PRIVATE HELPERS
	private struct function _getErrorDetails( required struct event ) {
		var codes     = _getErrorCodes();
		var relatedTo = arguments.event.error_related_to ?: "unknown";
		var error     = arguments.event.error            ?: "unknown";

		return {
			  code        = "#relatedTo#.#error.reReplace( '\W', '', 'all' )#"
			, description = codes[ relatedTo ][ error ] ?: "unknown"
		};
	}

// GETTERS AND SETTERS
	private any function _getEmailLoggingService() {
		return _emailLoggingService;
	}
	private void function _setEmailLoggingService( required any emailLoggingService ) {
		_emailLoggingService = arguments.emailLoggingService;
	}

	private void function _setupErrorCodes() {
		_errorCodes = {};
		_errorCodes.recipient = {
			  "user unknown"     = "Email address doesn't exist, double check it for typos!"
			, "mailbox inactive" = "Account has been inactive for too long (likely that it doesn't exist anymore)."
			, "quota exceeded"   = "Even though this is a non-permanent error, most of the time when accounts are over-quota, it means they are inactive."
			, "blacklisted"      = "You tried to send to a blacklisted recipient for this account."
			, "spam reporter"    = "You tried to send to a recipient that has reported a previous message from this account as spam."
		};
		_errorCodes.domain = {
			  "invalid domain"      = "There's a typo in the domain name part of the address. Or the address is so old that its domain has expired!"
			, "no mail host"        = "Nobody answers when we knock at the door."
			, "relay/access denied" = "The destination mail server is refusing to talk to us."
			, "greylisted"          = "This is a temporary error due to possible unrecognised senders. Delivery will be re-attempted."
			, "typofix"             = "The domain part of your recipient email address was not valid."
		};
		_errorCodes.content = {
			  "bad or empty template"      = "You should check that the template you are using has a content or is not corrupted."
			, "error in template language" = "Your content contain a template language error , you can refer to the error reporting functionalities to get more information."
		};
		_errorCodes.spam = {
			  "sender blocked"  = "This is quite bad! You should contact us to investigate this issue."
			, "content blocked" = "Something in your email has triggered an anti-spam filter and your email was rejected. Please contact us so we can review the email content and report any false positives."
			, "policy issue"    = "We do our best to avoid these errors with outbound throttling and following best practices. Although we do receive alerts when this happens, make sure to contact us for further information and a workaround"
		};
		_errorCodes.system = {
			  "system issue"     = "Something went wrong on our server-side. A temporary error. Please contact us if you receive an event of this type."
			, "protocol issue"   = "Something went wrong with our servers. This should not happen, and never be permanent !"
			, "connection issue" = "Something went wrong with our servers. This should not happen, and never be permanent !"
		};
		_errorCodes.mailjet = {
			  "preblocked"            = "You tried to send an email to an address that recently (or repeatedly) bounced. We didn't try to send it to avoid damaging your reputation."
			, "duplicate in campaign" = "You used X-Mailjet-DeduplicateCampaign and sent more than one email to a single recipient. Only the first email was sent; the others were blocked."
		};
	}
	private struct function _getErrorCodes() {
		return _errorCodes;
	}
}