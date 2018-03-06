component extends="testbox.system.BaseSpec" {
	public function run(){
		describe( "validatePostHookSignature", function() {
			it( "should return true when generating a signature using passed token, timestamp and stored api key matches the provided signature", function(){
				var service = _getService();
				var timestamp = 1487089870;
				var token     = "9859b97624eb842a4a4463ff8138c5b412a086f33569fcb54b";
				var signature = "b1b54e561291204fd87e132d5ed99c923c79dfbd8651190f1aed6934efb3931b";
				var apiKey    = "key-9jlk309mslkjkjfl4099-sdkj59a-99n";

				service.$( "_getApiKey", apiKey );

				expect( service.validatePostHookSignature(
					  timestamp = timestamp
					, token     = token
					, signature = signature
				) ).toBeTrue();
			} );

			it( "should return false when generating a signature using passed token, timestamp and stored api key does not match the provided signature", function(){
				var service = _getService();
				var timestamp = 1487089870;
				var token     = "9859b97624eb842a4a4463ff8138c5b412a086f33569fcb54b";
				var signature = "2b6a49bb9ca653337599a9197919ebb3b8539c100d917be810a92d9bd112d58d";
				var apiKey    = "key-9jlk309mslkjkjfl4099-sdkj59a-99n";

				service.$( "_getApiKey", apiKey );

				expect( service.validatePostHookSignature(
					  timestamp = timestamp
					, token     = token
					, signature = signature
				) ).toBeFalse();
			} );

			it( "should throw a useful error when API key is not configured", function(){
				var service     = _getService();
				var timestamp   = 1487089870;
				var token       = "9859b97624eb842a4a4463ff8138c5b412a086f33569fcb54b";
				var signature   = "b1b54e561291204fd87e132d5ed99c923c79dfbd8651190f1aed6934efb3931b";
				var apiKey      = "";
				var errorThrown = false;

				service.$( "_getApiKey", apiKey );

				try {
					service.validatePostHookSignature(
						  timestamp = timestamp
						, token     = token
						, signature = signature
					);
				} catch( "mailjet.api.key.not.configured" e ) {
					expect( e.message ).toBe( "No API key is configured for the mailjet extension. This prevents the validation of mailjet POST hooks." );
					errorThrown = true;
				}

				expect( errorThrown ).toBeTrue();
			} );
		});

		describe( "getPresideMessageIdForNotification", function(){
			it( "should return the ID in 'presideMessageId' variable if found in POST data", function(){
				var service  = _getService();
				var postData = { test=CreateUUId(), presideMessageId=CreateUUId() };

				expect( service.getPresideMessageIdForNotification( postData ) ).toBe( postData.presideMessageId );
			} );

			it( "should return X-Message-ID mail header if 'presideMessageId' is not present", function(){
				var service = _getService();
				var messageId = CreateUUId();
				var postData = { test=CreateUUId(), "message-headers"='[["Sender", "test@preside.org"], ["Date", "Tue, 14 Feb 2017 16:31:10 +0000"], ["X-mailjet-Sending-Ip", "184.173.153.222"], ["X-mailjet-Sid", "WyI4ZDI4NyIsICJkb21pbmljLndhdHNvbkBwaXhsOC5jby51ayIsICIxMDljMCJd"], ["Received", "by luna.mailjet.net with HTTP; Tue, 14 Feb 2017 16:31:09 +0000"], ["Message-Id", "<20170214163109.97563.12188.A9321BA4@preside.org>"], ["X-Message-ID", "#messageId#"], ["To", "dominic.watson@pixl8.co.uk"], ["From", "test@preside.org"], ["Subject", "mailjet test"], ["Mime-Version", "1.0"], ["Content-Type", ["multipart/alternative", {"boundary": "b6fc3745c8704ca8b0b839614e9d27be"}]]]'}

				expect( service.getPresideMessageIdForNotification( postData ) ).toBe( messageId );
			} );

			it( "should return X-Message-ID mail header if 'presideMessageId' is empty string", function(){
				var service = _getService();
				var messageId = CreateUUId();
				var postData = { test=CreateUUId(), presideMessageId="", "message-headers"='[["Sender", "test@preside.org"], ["Date", "Tue, 14 Feb 2017 16:31:10 +0000"], ["X-mailjet-Sending-Ip", "184.173.153.222"], ["X-mailjet-Sid", "WyI4ZDI4NyIsICJkb21pbmljLndhdHNvbkBwaXhsOC5jby51ayIsICIxMDljMCJd"], ["Received", "by luna.mailjet.net with HTTP; Tue, 14 Feb 2017 16:31:09 +0000"], ["Message-Id", "<20170214163109.97563.12188.A9321BA4@preside.org>"], ["X-Message-ID", "#messageId#"], ["To", "dominic.watson@pixl8.co.uk"], ["From", "test@preside.org"], ["Subject", "mailjet test"], ["Mime-Version", "1.0"], ["Content-Type", ["multipart/alternative", {"boundary": "b6fc3745c8704ca8b0b839614e9d27be"}]]]'}

				expect( service.getPresideMessageIdForNotification( postData ) ).toBe( messageId );
			} );

			it( "should return empty string when neither X-Message-ID or presideMessageId present", function(){
				var service = _getService();
				var postData = { test=CreateUUId(), "message-headers"='[["Sender", "test@preside.org"], ["Date", "Tue, 14 Feb 2017 16:31:10 +0000"], ["X-mailjet-Sending-Ip", "184.173.153.222"], ["X-mailjet-Sid", "WyI4ZDI4NyIsICJkb21pbmljLndhdHNvbkBwaXhsOC5jby51ayIsICIxMDljMCJd"], ["Received", "by luna.mailjet.net with HTTP; Tue, 14 Feb 2017 16:31:09 +0000"], ["To", "dominic.watson@pixl8.co.uk"], ["From", "test@preside.org"], ["Subject", "mailjet test"], ["Mime-Version", "1.0"], ["Content-Type", ["multipart/alternative", {"boundary": "b6fc3745c8704ca8b0b839614e9d27be"}]]]'}

				expect( service.getPresideMessageIdForNotification( postData ) ).toBe( "" );
			} );
		} );

		describe( "processNotification", function(){
			it( "should mark email as delivered when message event = 'delivered'", function(){
				var service      = _getService();
				var messageId    = CreateUUId();
				var messageEvent = "delivered";

				mockEmailLoggingService.$( "markAsDelivered" );

				service.processNotification(
					  messageId    = messageId
					, messageEvent = messageEvent
				);

				var callLog = mockEmailLoggingService.$callLog().markAsDelivered;

				expect( callLog.len() ).toBe( 1, "markAsDelivered() was not called" );
				expect( callLog[1] ).toBe( { id=messageId } );
			} );

			it( "should mark email as failed when message event = 'dropped'", function(){
				var service      = _getService();
				var messageId    = CreateUUId();
				var messageEvent = "dropped";
				var postData     = {
					  code = 605
					, description = "Whatever" & CreateUUId()
				};

				mockEmailLoggingService.$( "markAsFailed" );

				service.processNotification(
					  messageId    = messageId
					, messageEvent = messageEvent
					, postData     = postData
				);

				var callLog = mockEmailLoggingService.$callLog().markAsFailed;

				expect( callLog.len() ).toBe( 1, "markAsFailed() was not called" );
				expect( callLog[1] ).toBe( { id=messageId, reason=postData.description, code=postData.code } );
			} );

			it( "should mark email as hard bounced when message event = 'bounced'", function(){
				var service      = _getService();
				var messageId    = CreateUUId();
				var messageEvent = "bounced";
				var postData     = {
					  code = 550
					, error = "Bounced init" & CreateUUId()
				};

				mockEmailLoggingService.$( "markAsHardBounced" );

				service.processNotification(
					  messageId    = messageId
					, messageEvent = messageEvent
					, postData     = postData
				);

				var callLog = mockEmailLoggingService.$callLog().markAsHardBounced;

				expect( callLog.len() ).toBe( 1, "markAsHardBounced() was not called" );
				expect( callLog[1] ).toBe( { id=messageId, reason=postData.error, code=postData.code } );
			} );

			it( "should mark email as unsubscribed when message event = 'unsubscribed'", function(){
				var service      = _getService();
				var messageId    = CreateUUId();
				var messageEvent = "unsubscribed";

				mockEmailLoggingService.$( "markAsUnsubscribed" );

				service.processNotification(
					  messageId    = messageId
					, messageEvent = messageEvent
				);

				var callLog = mockEmailLoggingService.$callLog().markAsUnsubscribed;

				expect( callLog.len() ).toBe( 1, "markAsUnsubscribed() was not called" );
				expect( callLog[1] ).toBe( { id=messageId } );
			} );

			it( "should mark email as 'marked as spam' when message event = 'complained'", function(){
				var service      = _getService();
				var messageId    = CreateUUId();
				var messageEvent = "complained";

				mockEmailLoggingService.$( "markAsMarkedAsSpam" );

				service.processNotification(
					  messageId    = messageId
					, messageEvent = messageEvent
				);

				var callLog = mockEmailLoggingService.$callLog().markAsMarkedAsSpam;

				expect( callLog.len() ).toBe( 1, "markAsMarkedAsSpam() was not called" );
				expect( callLog[1] ).toBe( { id=messageId } );
			} );

			it( "should mark email as 'opened' when message event = 'opened'", function(){
				var service      = _getService();
				var messageId    = CreateUUId();
				var messageEvent = "opened";

				mockEmailLoggingService.$( "markAsOpened" );

				service.processNotification(
					  messageId    = messageId
					, messageEvent = messageEvent
				);

				var callLog = mockEmailLoggingService.$callLog().markAsOpened;

				expect( callLog.len() ).toBe( 1, "markAsOpened() was not called" );
				expect( callLog[1] ).toBe( { id=messageId } );
			} );

			it( "should record click when message event = 'clicked'", function(){
				var service      = _getService();
				var messageId    = CreateUUId();
				var messageEvent = "clicked";
				var postData     = {
					  url = "https://mylink.com/" & CreateUUId()
				};

				mockEmailLoggingService.$( "recordClick" );

				service.processNotification(
					  messageId    = messageId
					, messageEvent = messageEvent
					, postData     = postData
				);

				var callLog = mockEmailLoggingService.$callLog().recordClick;

				expect( callLog.len() ).toBe( 1, "recordClick() was not called" );
				expect( callLog[1] ).toBe( { id=messageId, link=postData.url } );
			} );
		} );
	}

// private helpers
	private any function _getService() {
		variables.mockEmailServiceProviderService = CreateStub();
		variables.mockEmailLoggingService = CreateStub();

		var service = new mailjet.services.mailjetNotificationsService(
			  emailServiceProviderService = mockEmailServiceProviderService
			, emailLoggingService         = mockEmailLoggingService
		);

		service = createMock( object=service );

		return service;
	}
}