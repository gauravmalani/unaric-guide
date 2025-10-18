({

	// Validates a URL string, ensuring it begins with a valid protocol (http or https)
	// NB: this function also exist in IHCard helper - but we are not a card!
	ensureProtocol : function (U) {

        var retVal = U;      
        if (retVal == null) retVal = '';    
         
        if (retVal != '') {
	        try {
	        
	        	// NB: allow for some common SF paths (e.g., images as docs)
	            if (! (retVal.toUpperCase().startsWith('HTTP://') 
	            			|| retVal.toUpperCase().startsWith('HTTPS://')
	            			|| retVal.toUpperCase().startsWith('/SERVLET/SERVLET.FILEDOWNLOAD?FILE=')
	            			)) {
	                retVal = 'https://' + retVal;
	            }
	        } catch (e) {         
	        }
        }
        
        return retVal;
	}, 
	
})