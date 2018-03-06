component {

	property name="mailjetNotificationsService" inject="mailjetNotificationsService";

	public void function index( event, rc, prc ) {
		try {
			mailjetNotificationsService.processEvents(
				events = DeSerializeJson( request.http.body ?: "" )
			);
		} catch ( any e ) {
			logError( e );
		}

		event.renderData( type="text", data="Webhook received", statuscode=200 );
	}

}