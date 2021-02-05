component {

	property name="mailjetNotificationsService" inject="mailjetNotificationsService";

	public void function index( event, rc, prc ) {
		try {
			var events = DeSerializeJson( event.getHTTPContent() );

			mailjetNotificationsService.processEvents(
				events = ( IsArray( events ) ? events : [ events ] )
			);
		} catch ( any e ) {
			logError( e );
		}

		event.renderData( type="text", data="Webhook received", statuscode=200 );
	}

}