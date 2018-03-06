component {

	property name="mailjetNotificationsService" inject="mailjetNotificationsService";

	public void function index( event, rc, prc ) {
		// deliberate use of form scope here. DO NOT CHANGE.
		// this is because 'event' is overridden in rc scope by coldbox
		var validRequest = mailjetNotificationsService.validatePostHookSignature(
			  timestamp = Val( form.timestamp ?: "" )
			, token     = form.token     ?: ""
			, signature = form.signature ?: ""
		);

		if ( validRequest ) {
			var presideMessageId = mailjetNotificationsService.getPresideMessageIdForNotification( form );

			if ( presideMessageId.trim().len() ) {
				var messageEvent = form.event ?: "";
				mailjetNotificationsService.processNotification(
					  messageId    = presideMessageId
					, messageEvent = messageEvent
					, postData     = form
				);
				event.renderData( type="text", data="Notification of [#messageEvent#] event received and processed for preside message [#presideMessageId#]", statuscode=200 );
			} else {
				event.renderData( type="text", data="Ignored: Could not identify source preside message", statusCode=200 );
			}
		} else {
			event.renderData( type="text", data="Not acceptable: invalid request signature", statusCode=406 );
		}



	}

}