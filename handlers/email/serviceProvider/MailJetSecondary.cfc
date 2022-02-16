/**
 * Service provider for email sending through Mailjet SMTP
 *
 */
component {
	property name="emailTemplateService" inject="emailTemplateService";

	private boolean function send( struct sendArgs={}, struct settings={} ) {
		var template = emailTemplateService.getTemplate( sendArgs.template ?: "" );

		sendArgs.params = sendArgs.params ?: {};
		sendArgs.params[ "X-MJ-CustomID" ] = {
			  name  = "X-MJ-CustomID"
			, value =  sendArgs.messageId ?: ""
		};

		if ( Len( Trim( template.name ?: "" ) ) ) {
			sendArgs.params[ "X-Mailjet-Campaign" ] = {
				  name  = "X-Mailjet-Campaign"
				, value =  template.name
			};
		}

		settings.username = settings.mailjet_api_key    ?: "";
		settings.password = settings.mailjet_secret_key ?: "";

		var result = runEvent(
			  event          = "email.serviceProvider.smtp.send"
			, private        = true
			, prepostExempt  = true
			, eventArguments = {
				  sendArgs = sendArgs
				, settings = settings
			  }
		);

		return result;
	}

	private any function validateSettings( required struct settings, required any validationResult ) {
		return validationResult;
	}
}