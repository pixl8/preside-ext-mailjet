/**
 * @singleton
 * @presideservice
 *
 */
component {

	/**
	 * @emailServiceProviderService.inject emailServiceProviderService
	 */
	public any function init(
		  required any     emailServiceProviderService
		,          string  baseUrl       = "https://api.mailjet.net/v3"
		,          numeric httpsTimeout  = 60
	) {
		_setEmailServiceProviderService( arguments.emailServiceProviderService );
		_setBaseUrl( arguments.baseUrl );
		_setHttpTimeout( arguments.httpsTimeout );

		return this;
	}

// PUBLIC API METHODS
	/**
	 * Attempts to send a message through the mailjet API - returns message if successul and throws an error otherwise
	 *
	 */
	public string function sendMessage(
		   required string from
		,  required string to
		,  required string subject
		,  required string text
		,  required string html
		,           string cc                = ""
		,           string bcc               = ""
		,           array  attachments       = []
		,           array  inlineAttachments = []
		,           string domain            = ""
		,           boolean testMode         = false
		,           array  tags              = []
		,           string campaign          = ""
		,           string dkim              = ""
		,           string deliveryTime      = ""
		,           string tracking          = ""
		,           string clickTracking     = ""
		,           string openTracking      = ""
		,           struct customHeaders     = {}
		,           struct customVariables   = {}
	){

		var results    = "";
		var files      = {};
		var domain     = _getDefaultDomain() ?: "";
		var postVars   = {
			   from    = arguments.from
			,  to      = arguments.to
			,  subject = arguments.subject
			,  text    = arguments.text
			,  html    = arguments.html
		};

		if( Len( Trim( arguments.cc ) ) ){
			postVars.cc = arguments.cc;
		}

		if( Len( Trim( arguments.bcc ) ) ){
			postVars.bcc = arguments.bcc;
		}

		if( _getForceTestMode() or arguments.testMode ){
			postVars[ "o:testmode" ] = "yes";
		}

		if( ArrayLen( arguments.tags ) ){
			postVars[ "o:tag" ] = arguments.tags;
		}

		if( Len( Trim( arguments.campaign ) ) ){
			postVars[ "o:campaign" ] = arguments.campaign;
		}

		if( isBoolean( arguments.dkim ) ){
			postVars[ "o:dkim" ] = _boolFormat( arguments.dkim );
		}

		if ( IsDate( arguments.deliveryTime ) ) {
				postVars[ "o:deliverytime" ] = _formatDate( arguments.deliveryTime );
		}

		if ( IsBoolean( arguments.tracking ) ) {
			postVars[ "o:tracking" ] = _boolFormat( arguments.tracking );
		}

		if ( IsBoolean( arguments.clickTracking ) ) {
			postVars[ "o:tracking-clicks" ] = _boolFormat( arguments.clickTracking );
		} elseif( arguments.clickTracking eq "htmlonly" ) {
			postVars[ "o:tracking-clicks" ] = "htmlonly";
		}

		if ( IsBoolean( arguments.openTracking ) ) {
			postVars[ "o:tracking-opens" ] = _boolFormat( arguments.openTracking );
		}

		for( var key in arguments.customHeaders ){
			postVars[ "h:X-#key#" ] = arguments.customHeaders[ key ];
		}

		for( var key in arguments.customVariables ){
			postVars[ "v:#key#" ] = arguments.customVariables[ key ];
		}

		if ( ArrayLen( arguments.attachments ) ) {
			files.attachment = arguments.attachments;
		}

		if ( ArrayLen( arguments.inlineAttachments ) ) {
			files.inline = arguments.inlineAttachments;
		}

		result = _restCall(
			  httpMethod = "POST"
			, uri        = "/messages"
			, domain     = domain
			, postVars   = postVars
			, files      = files
		);

		if ( StructKeyExists( result, "id" ) ) {
			return result.id;
		}

		_throw(
			  type    = "unexpected"
			, message = "Unexpected error processing mail send. Expected an ID of successfully sent mail but instead received [#SerializeJson( result )#]"
		);


	}


	public struct function listCampaigns( string domain, numeric limit, numeric skip ){
		var result  = "";
		var getVars = {};
		var domain  = arguments.domain ?: _getDefaultDomain();

		if( structKeyExists(arguments, "limit") ){
			getVars.limit = arguments.limit;
		}

		if( structKeyExists(arguments, "skip") ){
			getVars.skip = arguments.skip;
		}

		result = _restCall(
			  httpMethod = "GET"
			, url        = "/campaigns"
			, domain     = domain
			, getVars    = getVars
		);

		if ( StructKeyExists( result, "total_count" ) and StructKeyExists( result, "items" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, errorCode = 500
			, message   = "Expected response to contain [total_count] and [items] keys. Instead, receieved: [#SerializeJson( result )#]" )

	}


	public struct function getCampaign( required string id, string domain ){
		var domain = arguments.domain ?: _getDefaultDomain();
		var result = _restCall(
			  httpMethod = "GET"
			, uri        = "/campaigns/#arguments.id#"
			, domain     = domain
		);

		if ( IsStruct( result ) and StructKeyExists( result, "id" ) and StructKeyExists( result, "name" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "Unexpected mailjet response. Expected a campaign object (structure) but received: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public any function createCampaign( required string name, string id = "", string domain ){
		var postVars = { name=arguments.name }
		var result   = "";
		var domain   = arguments.domain ?: _getDefaultDomain();

		if ( Len( Trim( arguments.id ) ) ) {
			postVars[ "id" ] = arguments.id;
		}

		result = _restCall(
			  httpMethod = "POST"
			, uri        = "/campaigns"
			, domain     = domain
			, postVars   = postVars
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "campaign" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "CreateCampaign() response was an in an unexpected format. Expected success message and campaign detail. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public struct function updateCampaign( required string id, string name, string newId, string domain ){
		var result  = "";
		var getVars = {};
		var domain  = arguments.domain ?: _getDefaultDomain();

		if ( Len( Trim( arguments.name ) ) ) {
			getVars.name = arguments.name;
		}

		if ( Len( Trim( arguments.newId ) ) ) {
			getVars.id = arguments.newId;
		}

		result = _restCall(
			  httpMethod = "PUT"
			, uri        = "/campaigns/#arguments.id#"
			, domain     = domain
			, getVars    = getVars
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "campaign" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "UpdateCampaign() response was an in an unexpected format. Expected success message and campaign detail. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public struct function deleteCampaign( required string id, string domain ){
		var domain  = arguments.domain ?: _getDefaultDomain();

		var result = _restCall(
			  httpMethod = "DELETE"
			, uri        = "/campaigns/#arguments.id#"
			, domain     = domain
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "id" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "DeleteCampaign() response was an in an unexpected format. Expected success message and campaign id. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public struct function listMailingLists( numeric limit, numeric skip, string page, string lastEmailAddress ){
		var result  = "";
		var getVars = {};
		var uri     = "/lists";

		if ( StructKeyExists( arguments, "limit" ) ) {
			getVars.limit = arguments.limit;
		}
		if ( StructKeyExists( arguments, "skip" ) ) {
			getVars.skip = arguments.skip;
		}
		if ( StructKeyExists( arguments, "page" ) ) {
			getVars.page = arguments.page;
			uri &= "/pages";
		}
		if ( StructKeyExists( arguments, "lastEmailAddress" ) ) {
			getVars.address = arguments.lastEmailAddress;
		}

		result = _restCall(
			  httpMethod = "GET"
			, uri        = uri
			, domain     = ""
			, getVars    = getVars
		);

		if ( IsStruct( result ) and ( StructKeyExists( result, "total_count" ) || StructKeyExists( result, "paging" ) ) and StructKeyExists( result, "items" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, errorCode = 500
			, message   = "Expected response to contain [total_count] and [items] keys. Instead, receieved: [#SerializeJson( result )#]"
		);
	}


	public struct function getMailingList( required string address ){
		var result = _restCall(
			  httpMethod = "GET"
			, uri        = "/lists/#arguments.address#"
			, domain     = ""
		);

		if ( IsStruct( result ) and StructKeyExists( result, "list" ) and IsStruct( result.list ) and StructKeyExists( result.list, "address" ) ) {
			return result.list;
		}

		_throw(
			  type      = "unexpected"
			, errorCode = 500
			, message   = "Unexpected mailjet response. Expected a mailing list object (structure) but received: [#SerializeJson( result )#]"
		);
	}


	public struct function createMailingList( required string address, string name = "", string description = "", string accessLevel = "" ){
		var postVars = { address = arguments.address };
		var result   = "";

		if ( Len( Trim( arguments.name ) ) ) {
			postVars[ "name" ] = arguments.name;
		}
		if ( Len( Trim( arguments.description ) ) ) {
			postVars[ "description" ] = arguments.description;
		}
		if ( Len( Trim( arguments.accessLevel ) ) ) {
			postVars[ "access_level" ] = arguments.accessLevel;
		}

		result = _restCall(
			  httpMethod = "POST"
			, uri        = "/lists"
			, domain     = ""
			, postVars   = postVars
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "list" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "CreateMailingList() response was an in an unexpected format. Expected success message and list detail. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public struct function updateMailingList( required string address, string newAddress = "", string name = "", string description = "", string accessLevel = "" ){
		var result  = "";
		var getVars = {};

		if ( Len( Trim( arguments.newAddress ) ) ) {
			getVars[ "address" ] = arguments.newAddress;
		}
		if ( Len( Trim( arguments.name ) ) ) {
			getVars[ "name" ] = arguments.name;
		}
		if ( Len( Trim( arguments.description ) ) ) {
			getVars[ "description" ] = arguments.description;
		}
		if ( Len( Trim( arguments.accessLevel ) ) ) {
			getVars[ "access_level" ] = arguments.accessLevel;
		}

		result = _restCall(
			  httpMethod = "PUT"
			, uri        = "/lists/#arguments.address#"
			, domain     = ""
			, getVars    = getVars
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "list" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "UpdateMailingList() response was an in an unexpected format. Expected success message and list detail. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);

		return result;
	}


	public struct function deleteMailingList( required string address ){
		var result = _restCall(
			  httpMethod = "DELETE"
			, uri        = "/lists/#arguments.address#"
			, domain     = ""
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "address" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "DeleteMailingList() response was an in an unexpected format. Expected success message and list address. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public struct function listMailingListMembers( required string address, numeric limit, numeric skip, boolean subscribed, string page, string lastEmailAddress ){
		var result  = "";
		var getVars = {};
		var uri     = "/lists/#arguments.address#/members";

		if ( StructKeyExists( arguments, "limit" ) ) {
			getVars[ "limit" ] = arguments.limit;
		}
		if ( StructKeyExists( arguments, "skip" ) ) {
			getVars[ "skip" ] = arguments.skip;
		}
		if ( StructKeyExists( arguments, "subscribed" ) ) {
			getVars[ "subscribed" ] = _boolFormat( arguments.subscribed );
		}
		if ( StructKeyExists( arguments, "page" ) ) {
			getVars[ "page" ] = arguments.page;
			uri &= "/pages";
		}
		if ( StructKeyExists( arguments, "lastEmailAddress" ) ) {
			getVars[ "address" ] = arguments.lastEmailAddress;
		}

		result = _restCall(
			  httpMethod = "GET"
			, uri        = uri
			, domain     = ""
			, getVars    = getVars
		);

		if ( IsStruct( result ) and ( StructKeyExists( result, "total_count" ) || StructKeyExists( result, "paging" ) ) and StructKeyExists( result, "items" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "ListMailingListMembers() response was an in an unexpected format. Expected list of addresses. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public struct function getMailingListMember( required string listAddress, required string memberAddress ){
		var result = _restCall(
			  httpMethod = "GET"
			, uri        = "/lists/#arguments.listAddress#/members/#arguments.memberAddress#"
			, domain     = ""
		);

		if ( IsStruct( result ) and StructKeyExists( result, "member" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "GetMailingListMember() response was an in an unexpected format. Expected member structure. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public struct function createMailingListMember(
		  required string  listAddress
		, required string  memberAddress
		,          string  name          = ""
		,          boolean subscribed
		,          boolean upsert
	){

		var result   = "";
		var postVars = { address = arguments.memberAddress };

		if ( Len( Trim( arguments.name ) ) ) {
			postVars[ "name" ] = arguments.name;
		}

		if ( StructKeyExists( arguments, "vars" ) ) {
			postVars[ "vars" ] = SerializeJson( arguments.vars );
		}
		if ( StructKeyExists( arguments, "subscribed" ) ) {
			postVars[ "subscribed" ] = _boolFormat( arguments.subscribed );
		}
		if ( StructKeyExists( arguments, "upsert" ) ) {
			postVars[ "upsert" ] = _boolFormat( arguments.upsert );
		}

		result = _restCall(
			  httpMethod = "POST"
			, uri        = "/lists/#arguments.listAddress#/members"
			, postVars   = postVars
			, domain     = ""
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "member" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "CreateMailingListMember() response was an in an unexpected format. Expected success message and member detail. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public struct function updateMailingListMember(
		   required string  listAddress
		,  required string  memberAddress
		,           string  newAddress    = ""
		,           string  name          = ""
		,           struct  vars
		,           boolean subscribed
	){

		var result = "";
		var getVars = {};

		if( Len( Trim( arguments.newAddress ) ) ) {
			getVars[ "address" ] = arguments.newAddress;
		}
		if( Len( Trim( arguments.name ) ) ) {
			getVars[ "name" ] = arguments.name;
		}
		if( StructKeyExists( arguments, "vars" ) ) {
			getVars[ "vars" ] = SerializeJson( arguments.vars );
		}
		if( StructKeyExists( arguments, "subscribed" ) ) {
			getVars[ "subscribed" ] = _boolFormat( arguments.subscribed );
		}

		result = _restCall(
			  httpMethod = "PUT"
			, uri        = "/lists/#arguments.listAddress#/members/#arguments.memberAddress#"
			, domain     = ""
			, getVars    = getVars
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "member" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "UpdateMailingListMember() response was an in an unexpected format. Expected success message and member detail. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);

		return result;

	}


	public struct function deleteMailingListMember( required string listAddress, required string memberAddress ){
		var result = _restCall(
			  httpMethod = "DELETE"
			, uri        = "/lists/#arguments.listAddress#/members/#arguments.memberAddress#"
			, domain     = ""
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "member" ) and IsStruct( result.member ) and StructKeyExists( result.member, "address" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "DeleteMailingListMember() response was an in an unexpected format. Expected success message and member address. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);
	}


	public struct function bulkCreateMailingListMembers( required string listAddress, required array members, required boolean subscribed, boolean upsert ){
		var result        = "";
		var member        = "";
		var cleanedMember = {};
		var postVars = {
			  subscribed = _boolFormat( arguments.subscribed )
			, members    = []
		};

		for( member in arguments.members ){
			cleanedMember = {};

			if ( StructKeyExists( member, "name" ) and Len( Trim( member.name ) ) ) {
				cleanedMember[ "name" ] = member.name;
			}
			if ( StructKeyExists( member, "address" ) and Len( Trim( member.address ) ) ) {
				cleanedMember[ "address" ] = member.address;
			}
			if ( StructKeyExists( member, "vars" ) and IsStruct( member.vars ) and not StructIsEmpty( member.vars ) ) {
				cleanedMember[ "vars" ] = member.vars;
			}

			if ( StructKeyExists( cleanedMember, "address" ) ) {
				ArrayAppend( postVars.members, cleanedMember );
			}
		}

		postVars.members = SerializeJson( postVars.members );

		if ( StructKeyExists( arguments, "upsert" ) ) {
			postVars[ "upsert" ] = _boolFormat( arguments.upsert );
		}

		result = _restCall(
			  httpMethod = "POST"
			, uri        = "/lists/#arguments.listAddress#/members.json"
			, domain     = ""
			, postVars   = postVars
		);

		if ( IsStruct( result ) and StructKeyExists( result, "message" ) and StructKeyExists( result, "list" ) ) {
			return result;
		}

		_throw(
			  type      = "unexpected"
			, message   = "BulkCreateMailingListMembers() response was an in an unexpected format. Expected success message and list details. Instead, recieved: [#SerializeJson( result )#]"
			, errorCode = 500
		);



		return result;
	}

	private struct function _restCall(
		  required string httpMethod
		, required string uri
		,          string domain   = ""
		,          struct postVars = {}
		,          struct getVars  = {}
		,          struct files    = {}
	){
		var httpResult = "";
		var key        = "";
		var i          = "";

		http url       = _getRestUrl( arguments.uri, arguments.domain )
			 method    = arguments.httpMethod
			 timeout   = _getHttpTimeout()
			 result    = "httpResult"
			 username  = "api"
			 password  = _getApiKey()
			 multipart = ( StructCount( arguments.files) gt 0 ){

			for( key in arguments.postVars ){

				if( IsArray( arguments.postVars[ key ] ) ){
					for ( i=1; i<=ArrayLen( arguments.postVars[ key ] ); i++ ) {
						httpparam name=key value=arguments.postVars[ key ][ i ] type="formfield";
					}
				}else{
					httpparam name=key value=arguments.postVars[ key ] type="formfield";
				}
			}

			for( key in arguments.getVars ){

				if( IsArray( arguments.getVars[ key ] ) ){
					for( i=1; i<=ArrayLen(arguments.getVars[ key ] ); i++ ){
						httpparam name=key value=arguments.getVars[ key ][ i ] type="url";
					}
				} else {
					httpparam name=key value=arguments.getVars[ key ] type="url";
				}
			}

			for( key in arguments.files ){
				if( IsArray( arguments.files[ key ] ) ){
					for( var path in arguments.files[ key ] ){
						httpparam name=key file=path type="file";
					}
				}else{
					httpparam name=key file=arguments.files[ key ] type="file";
				}
			}

		}

		return _processApiResponse( argumentCollection=httpResult );
	}


	private any function _processApiResponse( string filecontent = "", string status_code = "" ){
		_checkErrorStatusCodes( argumentCollection = arguments );

		try {
			return DeserializeJSON( arguments.fileContent );

		} catch ( any e ) {
			_throw(
				  type    = "unexpected"
				, message = "Unexpected error processing mailjet API response. mailjet response body: [#arguments.fileContent#]"
			);
		}
	}


	private void function _checkErrorStatusCodes( required string status_code, required string filecontent ){
		var errorParams = {};
		var deserialized = "";

		if ( arguments.status_code NEQ 200 ) {
			switch( arguments.status_code ) {
				case 400:
					errorParams.type    = "badrequest";
					errorParams.message = "mailjet request failure. ";
				break;

				case 401:
					errorParams.type    = "unauthorized";
					errorParams.message = "mailjet authentication failure, i.e. a bad API Key was supplied. ";
				break;

				case 402:
					errorParams.type    = "requestfailed";
					errorParams.message = "mailjet request failed (unexpected). ";
				break;

				case 404:
					errorParams.type    = "resourcenotfound";
					errorParams.message = "mailjet requested resource not found (404). This might be caused by an invalid domain or incorrectly programmed API call. ";
				break;

				case 500: case 502: case 503: case 504:
					errorParams.type    = "servererror";
					errorParams.message = "An unexpected error occurred on the mailjet server. ";
				break;

				default:
					errorParams.type    = "unexpected";
					errorParams.message = "An unexpted response was returned from the mailjet server. ";

			}

			try {
				deserialized = DeserializeJson( arguments.fileContent );
			} catch ( any e ){}

			if ( IsStruct( deserialized ) and StructKeyExists( deserialized, "message" ) ) {
				errorParams.message &= "[" & deserialized.message & "]";
			} else {
				errorParams.message &= "mailjet response body: [#arguments.filecontent#]"
			}

			if ( Val( arguments.status_code ) ) {
				errorParams.errorCode = arguments.status_code;
			} else {
				errorParams.errorCode = 500;
			}

			_throw( argumentCollection = errorParams );
		}
	}


	private string function _getRestUrl( required string uri, required string domain ){
		var restUrl = _getBaseUrl();

		if ( Len( Trim( arguments.domain ) ) ) {
			restUrl &= "/" & arguments.domain;
		}

		restUrl &= arguments.uri;

		return restUrl;
	}


	private void function _throw( required string type, string message = "", numeric errorcode = 500 ){
		throw(
			  type      = "cfmailjet.#arguments.type#"
			, message   = arguments.message
			, errorcode = arguments.errorcode
		);
	}


	public any function _formatDate( required date theDate ){
		var gmtDate = DateAdd( "s", GetTimeZoneInfo().UTCTotalOffset, theDate );

		return DateFormat( gmtDate, "ddd, dd mmm yyyy" ) & " " & TimeFormat( gmtDate, "HH:mm:ss")  & " GMT";
	}


	private string function _getApiKey(){
		return _getSettings().mailjet_api_key;
	}


	private string function _getDefaultDomain(){
		return _getSettings().mailjet_default_domain;
	}


	private boolean function _getForceTestMode(){
		var testMode = _getSettings().mailjet_test_mode;

		return IsBoolean( testMode ) && testMode;
	}

	private struct function _getSettings(){
		if ( !request.keyExists( "_mailjetServiceProviderSettings" ) ) {
			var settings = _getEmailServiceProviderService().getProviderSettings( "mailjet" );

			request._mailjetServiceProviderSettings = {
				  mailjet_api_key        = settings.mailjet_api_key        ?: ""
				, mailjet_api_public_key = settings.mailjet_api_public_key ?: ""
				, mailjet_default_domain = settings.mailjet_default_domain ?: ""
				, mailjet_test_mode      = settings.mailjet_test_mode      ?: ""
			};
		}

		return request._mailjetServiceProviderSettings;
	}


	public string function _boolFormat( required boolean bool ){
	   return LCase( YesNoFormat( arguments.bool ) );
	}

	private void function _setBaseUrl( required string baseUrl ) {
		_baseUrl = arguments.baseUrl;
	}

	private string function _getBaseUrl() {
		return _baseUrl;
	}

	private void function _setHttpTimeout( required string httpsTimeout ) {
		_httpTimeout = arguments.httpsTimeout;

	}

	private numeric function _getHttpTimeout() {
		return _httpTimeout;
	}

	private any function _getEmailServiceProviderService() {
		return _emailServiceProviderService;
	}
	private void function _setEmailServiceProviderService( required any emailServiceProviderService ) {
		_emailServiceProviderService = arguments.emailServiceProviderService;
	}
}