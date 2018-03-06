/**
 * Service provider for email sending through mailjet API
 *
 */
component {
	property name="mailjetApiService" inject="mailjetApiService";
	property name="emailTemplateService" inject="emailTemplateService";

	private boolean function send( struct sendArgs={}, struct settings={} ) {
		var template = emailTemplateService.getTemplate( sendArgs.template ?: "" );

		sendArgs.params = sendArgs.params ?: {};
		sendArgs.params[ "X-mailjet-Variables" ] = {
			  name  = "X-mailjet-Variables"
			, value =  SerializeJson( { presideMessageId = sendArgs.messageId ?: "" } )
		};

		if ( IsTrue( settings.mailjet_test_mode ?: "" ) ) {
			sendArgs.params[ "X-mailjet-Drop-Message" ] = {
				  name  = "X-mailjet-Drop-Message"
				, value =  "yes"
			};
		}
		if ( Len( Trim( template.name ?: "" ) ) ) {
			sendArgs.params[ "X-mailjet-Tag" ] = {
				  name  = "X-mailjet-Tag"
				, value =  template.name
			};
		}

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