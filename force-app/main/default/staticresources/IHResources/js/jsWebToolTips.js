/////////////////////////////////////////////////////////////////////////////////////////////////////
// FUNCTIONS FOR CREATING IMPROVED HELP "WINDOWS" CLIENT SIDE
//
// Martin Little for Improved Apps
// May 2012
// Copyright (c.) Improved Apps Limited 2012. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

(function(IHWebToolTips, $, undefined) {


// --------------------------------------------------------------------------------------------------
// Function to check whether an attempt to reach a given page will result in a login request.
// This effectively checks whether the user's current session is valid.
// Returns an XMLHttp session state code (zero if there is a failure = login required)
// --------------------------------------------------------------------------------------------------
	IHWebToolTips.checkSessionState = function (TestURL) {
		
		// 1.24.n - allow login checking to be switched off via a global setting:
		// If requested, skip the test and just return success 
		if (IHSettings[doLoginChecks] == 'false') {
			return 4;
		}
		
		// To do the check, make an HTTP request to a known SF page and check for a known result:
		// Let's use the IHQAMSettings page with a bogus callback function (that we can look for
		// in the returned text)

		var xmlhttp;

		if (window.XMLHttpRequest)
		{
			xmlhttp=new XMLHttpRequest();
		} else {
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}

		xmlhttp.onreadystatechange=function() {httpReady(xmlhttp);}

		try {
			xmlhttp.open("GET",TestURL,false);
			xmlhttp.send();

		} catch (e) {
			//alert('checkSessionState ERROR: ' + e);
			// 1.20: On failure, we must continue (not do infinite loop)
			IHCSblnReady = true;
		}

	
		do {} while (IHCSblnReady == false);

		return IHCSReadyStatus;
	}
		

// --------------------------------------------------------------------------------------------------
// Shows a popup tool tips window: typically to be called via mouse event (click, over etc).
//
// TipFrameID       = ID of the IFRAME that is to be used to show the tip
// U                = URL of the web page that is to act as the tip
// EntryStyle       = Integer (as a string) representing one of several recognised ways for tips to become visible
// W                = Integer (as number) - the width in pixels of the tip
// H                = Integer (as number) - the height in pixels of the tip
//
// Returns nothing
// --------------------------------------------------------------------------------------------------
	IHWebToolTips.DoTips = function (TipFrameID, U, EntryStyle, W, H, evt) {
		
	    var finished;
	    var L;
	    var T;
	    var tip = document.getElementById(TipFrameID);
		var dWait = document.getElementById('IHTipPending');						    
		var btn = null;
		var elem;
			

		try {
			// Take note of the element that fired this call
			if(!evt) evt = window.event;
			elem = evt.srcElement || evt.target;
			
			
			// We cannot do anything if we don't find the requested tip IFRAME
			if (tip + '' == 'null') {
				return;
			}

			
			// For callouts, set high z-index
			if (tip.id == 'tfrm') {
				$IAIHj(tip).css('zIndex', 70000);
			}
			
						
			// We should act if there's been a loss of session (logout, timeout):
			// check session here and if it's not valid, advise user to refresh / login.
			// This will NOT work for VF pages embedded in SF page layouts - so don't 
			// make the check in these cases...
			if (document.URL.indexOf('servlet/servlet.Integration') == -1) {
				
				// 1.24.n - handle this check "in-line" below for the most popular types
				if (EntryStyle != '2' && EntryStyle != '3') {
					var checkS = IHWebToolTips.checkSessionState(document.URL);
					if (checkS == 0) {
						var Msg = Internationalise('[QAMMessageLoggedOut]');					
						alert(Msg);
						return;
					}
				}
			}
	

			if (EntryStyle == '7') {
				// Show a close button, if entry style = dialogue
				btn = document.getElementById('IHDialogueWrapper');
				tip.onmouseout = '';
	
			} else {
				// Otherwise, this is a callout: 
				// Therefore we should respond to callout closure behaviour as set in global settings.
				// See also DT, which responds to the same setting 
				// as regards the Helped Element (not the tip it produces) setting on click as required.
				// See also DoFieldStats / DoPageStats for stats mode				
				setClosureBehaviourForTip(tip);
			}
		
		
			// We should also check that we actually got an IFRAME as opposed to any other element
			if (tip.tagName.toUpperCase() != 'IFRAME') {
				return;
			}
		
		
			// Note the current tip styling
		    tStyle = EntryStyle;
				 
		
		    // Move the tip to a default source to start with, so it doesn't show with the wrong page...
	        tip.src = defaultTipSrc;
	
	        
		    switch (tStyle) {
		
		        case "1":
		            //Tip to be shown as tool tip at right of screen
		            var PS;

		  			try {
						document.body.removeChild(tip);
					} catch (e) {
		    		}
		
					document.body.appendChild(tip);
		
					PS = getPageScroll();
				    tip.style.position = 'absolute';
					tip.style.top = evt.clientY + PS[1] + 10 + 'px';
					tip.style.left = ((100 - W) + 0.75) + '%';
					tip.style.width = (W - 1.5) + '%';
		
		            break;
		
		
		        case "2":
		            //Tip to be shown as tool tip to the right of mouse click
		            var PS;
					var tipW;
					var mousePct;
					var WW;
					
		  			
					try {
						document.body.removeChild(tip);
					} catch (e) {
		    		}		
					document.body.appendChild(tip);
		  			try {
						document.body.removeChild(dWait);
					} catch (e) {
		    		}		
					document.body.appendChild(dWait);

					
					PS = getPageScroll();
				    tip.style.position = 'absolute';
					
					//We want tip to be at specified % width (less "padding" / margins) - but we are
					//dependent on left of where mouse was clicked: so, we limit the width so that
					//specified % is maximum - we cut this to fill to right of screen (not overflow it)
					//if required...
					
					//Calculate mouse position as % of available screen W
				    WW = GetWinSize('W');
					mousePct = evt.clientX / WW;

					//Make tip specified %W x (1 - mouse pos %) - but only if required					
					if (W > (1 - mousePct) * 100) {
						tipW = ((1 - mousePct) * 100) - 2;
					} else {
						tipW = W - 2;
					}
					
					// Top position depends on whether we've been asked to snap to element (or mouse)
					tip.style.display = ('none');
					
					if ($IAIHj(elem).hasClass('IHSnapToElement')) {
						tip.style.top = $IAIHj(elem).offset().top + $IAIHj(elem).height() + 'px';
						tip.style.left = $IAIHj(elem).offset().left + 'px';
						tip.style.width = (WW - $IAIHj(elem).offset().left) * (W/100) + 'px';						

					} else {
						tip.style.top = evt.clientY + PS[1] + 10 + 'px';
						tip.style.left = evt.clientX + PS[0] + 20 + 'px';						
						tip.style.width = tipW + '%';
					}					


					dWait.style.position = tip.style.position;
					dWait.style.top = tip.style.top;
					dWait.style.left = tip.style.left;
					dWait.style.height = '0px';
					dWait.style.width = tip.style.width;
					dWait.style.background = 'rgba(255,255,255,0.7) url(/resource/iahelp__IHResources/img/loading.gif) no-repeat left';
					
					dWait.style.display = 'block';
					
					$IAIHj("#IHTipPending").animate({height: H + 'px'}, function() {
					
						var checkS = IHWebToolTips.checkSessionState(document.URL);
						if (checkS == 0) {
							var Msg = Internationalise('[QAMMessageLoggedOut]');					
							alert(Msg);
							dWait.style.display = 'none';
							return;

						} else {
							tip.style.display = 'block';
							tip.style.height = H + 'px';	
							dWait.style.display = 'none';
						}
					});
					
		            break;
		
		
		        case "3":                    
		            //Make tip by adding row to table and placing tip frame there...		        

		            var TB;
					var TR;
					var TD1;
					var rIdx = -1;
					var cIdx = 0;
					var NumCols = 0;
					
		 			//First, remove any existing added row
					TR = document.getElementById('tipRow');
		 			if (TR + '' != 'null') {	
						TB = TR;
						do {
							TB = TB.parentNode;
						}
						while (TB.tagName.toUpperCase() != 'TABLE');
				
						TB.deleteRow(TR.rowIndex);
					} 

		 			//Now add the new tip row
					TB = elem; //evt.srcElement || evt.target;	 					 			

		 			do {
						//Check we have a table element as we traverse to try to find a place to add the row.
						//It's possible that this will NOT be the case - as with some buttons:
						//These are hooked (thru DoButtonTip -> DT etc) to use a type 3 callout
						//which is fine for upper & lower button bars, BUT for buttons elsewhere
						//(e.g., list view "Go!" buttons) will not be as these are not in a table.
												
						if (TB.tagName.toUpperCase() == 'DIV' && TB.className == 'bFilterView') {
							
							// In these cases add a peer DIV into which to insert our tip
							$IAIHj('#IHListViewButtonDiv').remove();
							TD1 = $IAIHj(TB).after('<div id="IHListViewButtonDiv" />');							
							break;
						}
								 				
						// We need to find the parent table, but also			
						// get the row and column indices of the cell whilst we're here
						if (TB.tagName.toUpperCase() == 'TR') {
							rIdx = TB.rowIndex;
						}
						
						if (TB.tagName.toUpperCase() == 'TD' || TB.tagName.toUpperCase() == 'TH') {
							cIdx = TB.cellIndex;
						}
		
						TB = TB.parentNode;
					}
					while (TB.tagName.toUpperCase() != 'TABLE');
		 			
					// Take note of the number of columns in the table...		 			
					var i;
					var TRs = TB.getElementsByTagName('TR');
					var Ds;
					var Hs;
			
					for (i=0; i<TRs.length; i++) {
						Ds = TRs[i].getElementsByTagName('TD');
						Hs = TRs[i].getElementsByTagName('TH');
						if (Ds.length + Hs.length > NumCols) {NumCols = Ds.length + Hs.length;}
					}
		 			

					try {
						TR = TB.insertRow(rIdx + 1);
						TR.id='tipRow';
						
						// Insert a cell spanning all table columns
						TD1 = TR.insertCell(0);			
			            TD1.colSpan = NumCols;

					} catch (e) {
						//alert('DoTips Error inserting table row / cell: ' + e);
					}
					

					
		  			try {
						document.body.removeChild(tip);
					} catch (e) {
						//alert('DoTips Error removing tip frame: ' + e);
		    		}
					try {
						document.body.removeChild(dWait);
					} catch (e) {
						//alert('DoTips Error removing tip frame: ' + e);
					}
	
					
					// Place the tip in the new element (cell or div)
					try {
						TD1.appendChild(tip);
					} catch (e) {
						$IAIHj(TD1).append(tip);
					}
					try {
						TD1.appendChild(dWait);						
					} catch (e) {
						$IAIHj(TD1).append(dWait);
					}
					
		    		tip.style.position = 'relative';
					tip.style.top = '0px';
					tip.style.left = '0px';
					tip.style.width = '100%';
	
					// Uniquely for this entry style, use slide-in jQuery animation
					tip.src = U;	   
					tip.style.height = '0px';

					dWait.style.position = 'relative';
					dWait.style.top = '0px';
					dWait.style.left = '0px';
					dWait.style.height = '0px';
					dWait.style.width = '100%';
					dWait.style.display = 'block';
					dWait.style.background = 'url(/resource/iahelp__IHResources/img/loading.gif) no-repeat center';
					
					$IAIHj("#IHTipPending").animate({height: H + 'px'}, function() {
					
						var checkS = IHWebToolTips.checkSessionState(document.URL);
						if (checkS == 0) {
							var Msg = Internationalise('[QAMMessageLoggedOut]');					
							alert(Msg);
							dWait.style.display = 'none';
							return;

						} else {
							tip.style.display = 'block';
							tip.style.height = H + 'px';	
							dWait.style.display = 'none';
						}
					});

					break;
		
		
		        case "6":
		            //Tip to be shown as tool tip 100% width
		            var PS;
		
		  			try {
						document.body.removeChild(tip);
					} catch (e) {
		    		}

					document.body.appendChild(tip);
		
					PS = getPageScroll();

					tip.style.position = 'absolute';
					
					// Top position depends on whether we've been asked to snap to element (or mouse)
					if ($IAIHj(elem).hasClass('IHSnapToElement')) {
						tip.style.top = $IAIHj(elem).offset().top + $IAIHj(elem).height() + 'px';
					} else {
						tip.style.top = evt.clientY + PS[1] + 10 + 'px';
					}

					tip.style.left = 0;   
					tip.style.width = '100%';
					
		            break;
		
				case "7":
					// Tip to be shown as a dialogue screen, 80% width
				    // These should open Y = "centre screen"
		            var clientH;
		
		            // Take note of the current scroll position		
		    		var scrl = $IAIHj(document).scrollTop();
		            
		            
		  			try {
						document.body.removeChild(tip);
					} catch (e) {
		    		}
		
					document.body.appendChild(tip);
						
				    tip.style.position = 'absolute';
				    
					clientH = GetWinSize('H');
	
					// Top of dialogue must take scroll bar position into account...
				    tip.style.top = ((clientH / 2) - (H / 2)) + scrl + 'px';
				    
					tip.style.left = '10%';
					tip.style.width = '80%';
					
					break;
		
				case "8":
					// Tip to be shown to LEFT of mouse click
		            var PS;
					var tipW;
					var mousePct;
					var WW;
					
					
		  			try {
						document.body.removeChild(tip);
					} catch (e) {
		    		}
		
					document.body.appendChild(tip);
		
					PS = getPageScroll();
				    tip.style.position = 'absolute';
					
					//Calculate mouse position as % of available screen W
				    WW = GetWinSize('W');
					mousePct = evt.clientX / WW;
					
					// Top position depends on whether we've been asked to snap to element (or mouse)
					if ($IAIHj(elem).hasClass('IHSnapToElement')) {
						tip.style.top = $IAIHj(elem).offset().top + $IAIHj(elem).height() + 'px';
						tip.style.width = ($IAIHj(elem).offset().left + $IAIHj(elem).width()) * (W/100) + 'px';						
						tip.style.left = $IAIHj(elem).offset().left + $IAIHj(elem).width() - $IAIHj(tip).width() + 'px';
						
					} else {
						tip.style.top = evt.clientY + PS[1] + 10 + 'px';
						tip.style.left = ((mousePct * 100) - W) + '%';					
						tip.style.width = W + '%';
					}
					
		
					break;
					
				case "9":
					// Tip to be displayed within a (VF page developer) specified DIV:
					// Extract the required DIV Id from custom class name
					var D = elem.className.substring(elem.className.indexOf('HelpableToDiv_') + 14);
					if (D.indexOf(' ') != -1) {
						D = D.substring(0, D.indexOf(' '));
					}					
					D = document.getElementById(D);
					
					tip.style.width = $IAIHj(D).width() + 'px';
					tip.style.height = $IAIHj(D).height() + 'px';
				    tip.style.position = 'absolute';					
					tip.style.top = '0px';
					tip.style.left = '0px';

		  			try {
						document.body.removeChild(tip);
					} catch (e) {
		    		}

		  			try {
						D.removeChild(tip);
					} catch (e) {
		    		}
					
					D.appendChild(tip);
					
					tip.src = U;	    	
				    tip.style.display = 'block';

					break;

				default:
		            //Do nothing if style not recognised
		            return;
		    }
		
		
		    
		    // For tips added as row or directed to a named DIV, these attributes are handled in line above
			if (tStyle != "3" && tStyle != "9") {
			    tip.style.height = H + 'px';
			    tip.src = U;	    	
			    tip.style.display = 'block';
			}
				    
			
		    // Show the close button if required
		    if(btn + '' != 'null'){
		    	var Y = getTipPos(tip, 'Y');
		    	var H = getTipPos(tip, 'H');
		    		    	
		    	btn.style.left = tip.style.left;
		    	btn.style.width = tip.style.width;
		    	btn.style.height = (H + 15) + 'px';
		    		    	
		    	btn.style.top = (Y - 10) + 'px';
		    	btn.style.position = tip.style.position;
		    	btn.style.display = 'block';
		    }
	
		    	    
	        // Set focus to the tip frame
	        tip.focus();
			
		} catch (e) {
			var Msg = Internationalise('[QAMMessageGenericError]');
			alert(Msg + ' - (Do Tip) ' + e);
		}

	    return;
	}


// --------------------------------------------------------------------------------------------------
// Moves browser's scroll bar to specified position
// --------------------------------------------------------------------------------------------------
	IHWebToolTips.moveScroll = function (scrollPos) {
		$IAIHj(document).scrollTop(scrollPos);
		window.clearInterval(iQAMDocScroll);
		return;
	}


// --------------------------------------------------------------------------------------------------
// Hides a given popup tool tips window: typically to be called via mouse out event.
//
// TipFrameID       = ID of the IFRAME that is to be used to show the tip
//
// Returns nothing
// --------------------------------------------------------------------------------------------------
	IHWebToolTips.StopTips = function (TipFrameID) {
	    var tip = document.getElementById(TipFrameID);
        UnPin(TipFrameID);             	
	    return;
	}


// --------------------------------------------------------------------------------------------------
// PRIVATE MEMBERS:
// --------------------------------------------------------------------------------------------------
	

	var tStyle;                         // The current tool tip style
	var IHCSblnReady = false;			// For checking SF session details - see checkSessionState etc
	var IHCSReadyStatus;				// For checking SF session details - see checkSessionState etc
	var defaultTipSrc = '';				// URL of the "default" page to use when moving between tips
	
	// 1.23 - adding new signature as login addresses may change with My Domains (but hopefully all login pages have same title)
	var IHCSLoginPageSignatures = "window.location.replace('https://login.salesforce.com/?^var url = 'https://login.salesforce.com^<title>salesforce.com - Customer Secure Login Page</title>";

	// 1.24.n - additional signature as SF classic checks no longer seem to work
	IHCSLoginPageSignatures += "^...................................................................................................";

	
// --------------------------------------------------------------------------------------------------
// "Ready" function used as part of checkSessionState:
// Sets a variable to say that HTTP request status is set to "complete" and thus that the 
// return / success code can be checked.
// NB: ultimate return code is set to XMLHttp request state - BUT as SF pages can return success
// even when login is required, this function will set a failure code if the signature of a SF
// login page is noted in the body content returned by the web request.
// --------------------------------------------------------------------------------------------------
	function httpReady(req) {

		try {
			IHCSReadyStatus = req.status;
			
			if (req.readyState == 4) {
				
				var loginSigs = IHCSLoginPageSignatures.split('^');
				var i;
	
				// SF pages may return status = OK (200) even when a logout has occurred:
				// So: check content for signs of a login page and, if found, set status manually
				for(i=0; i<loginSigs.length; i++) {
					if (req.responseText.indexOf(loginSigs[i]) != -1) {
						IHCSReadyStatus = 0;
						break;
					}							
				}

				IHCSblnReady = true;
			}
			
		} catch (e) {
			// On error (browser support etc) just return ready
			IHCSReadyStatus = 4;
		}

		return;
	}
	
	
// --------------------------------------------------------------------------------------------------
// Unpins a tip window that has been pinned open
//
// TipFrameID       = ID of the IFRAME that is to be used to show the tip
//
// Returns nothing
// --------------------------------------------------------------------------------------------------
	function UnPin(TipFrameID) {
	
	    var tip = document.getElementById(TipFrameID);	
	
		// We cannot do anything if we don't find the requested tip element 
		// (IFRAME or related close button) 
		if (tip + '' == 'null') {
			return;
		}
	
	    tip.style.display = 'none';
	
	    switch (tStyle) {
	        case "3":
	        	// No further action required
	        	break;
	    
	        case "5":
	            tip.style.top = GetWinSize('H') + 'px';
	        	break;
	        	        	
	        default:
	            tip.style.left = GetWinSize('W') + 'px';
	            break;
	    }
	
	    return;
	}


// --------------------------------------------------------------------------------------------------
// Returns the width or height of the browser window (as opposed to the screen)
//
// Coord            = 'W' to request width, 'H' to request the height
//
// Returns this coordinate as an integer. Returns 0 if a coordinate other than W or H requested.
// --------------------------------------------------------------------------------------------------
	function GetWinSize(Coord) {
	
	    var retVal;
	
	    switch (Coord) {
	        case 'W':
	            if (document.body && document.body.offsetWidth) {
	                retVal = document.body.offsetWidth;
	            }
	            if (document.compatMode == 'CSS1Compat' && document.documentElement & document.documentElement.offsetWidth) {
	                retVal = document.documentElement.offsetWidth;
	            }
	            if (window.innerWidth && window.innerHeight) {
	                retVal = window.innerWidth;
	            }
	            break;
	            
	        case 'H':
	            if (document.body && document.body.offsetHeight) {
	                retVal = document.body.offsetHeight;
	            }
	            if (document.compatMode == 'CSS1Compat' && document.documentElement & document.documentElement.offsetHeight) {
	                retVal = document.documentElement.offsetHeight;
	            }
	            if (window.innerWidth && window.innerHeight) {
	                retVal = window.innerHeight;
	            }
	            break;
	            
	        default:
	            retVal = 0;
	    }
	
	    return retVal;
	}


// --------------------------------------------------------------------------------------------------
// Returns the requested sizing attribute of the referenced tip frame
//
// TipFrame           = the IFRAME (NOT just its ID) that is being used to show the tip
// Coord              = the requested coordinate (X, Y, W or H)
//
// Returns the integer (just the number) representing the number of pixels applicable to the requested coordinate
// --------------------------------------------------------------------------------------------------
	function getTipPos(TipFrame, Coord) {
	
	    var C;
	    var iC = 0;
	
	
	    switch (Coord) {
	        case 'X':
	            C = TipFrame.style.left;
	            break;
	
	        case 'Y':
	            C = TipFrame.style.top;
	            break;
	
	        case 'W':
	            C = TipFrame.style.width;
	            break;
	
	        case 'H':
	            C = TipFrame.style.height;
	            break;
	
	        default:
	
	    }
	    
	    
	    if (C.indexOf('px') != -1) {
	        C = C.substr(0, C.length - 2);
	    }
	
	    if (C.length == 0) {
	        C = '0';
	    }
	
	    iC = new Number(C);
	
	    return iC;
	}


// --------------------------------------------------------------------------------------------------
// Returns an array containing details in pixels of scroll bar offsets
// --------------------------------------------------------------------------------------------------
	function getPageScroll() { 
	
		var xScroll;
	    var yScroll; 
	
	    if (self.pageYOffset) { 
			yScroll = self.pageYOffset; 
			xScroll = self.pageXOffset;
			 
	    } else if (document.documentElement && document.documentElement.scrollTop) { 
			yScroll = document.documentElement.scrollTop; 
			xScroll = document.documentElement.scrollLeft;
			 
	    } else if (document.body) {// all other Explorers 
			yScroll = document.body.scrollTop; 
			xScroll = document.body.scrollLeft; 
	    } 
	    
	    return new Array(xScroll,yScroll) 
	} 

	
//}(window.IHWebToolTips = window.IHWebToolTips || {}, jQuery));

}(window.IHWebToolTips = window.IHWebToolTips || {}));

