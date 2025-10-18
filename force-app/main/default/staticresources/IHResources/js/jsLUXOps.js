/////////////////////////////////////////////////////////////////////////////////////////////////////
// UTILITIES FOR VF PAGES THAT MAKE USE OF LIGHTNING OUT
//
// Martin Little for Improved Apps
// October 2017
// Copyright (c.) Improved Apps Limited 2017. All Rights Reserved.
/////////////////////////////////////////////////////////////////////////////////////////////////////

"use strict";

(function(IHLUXOps, $, undefined) {

// --------------------------------------------------------------------------------------------------
// Converts delimited parameters [Attribute~Value^] into an object for use in building LUX controls
// --------------------------------------------------------------------------------------------------
    IHLUXOps.getParmsMap = function (parms) {
    	
        var retVal;
        var i;
        var s = '';
        var Ps;
        var parm;
                
        console.log('IHLUXOps.getParmsMap - entry... ');
        
        try {
            Ps = parms.split('^');
                
            for (i=0; i < Ps.length; i++) {
                parm = Ps[i].split('~');
                
                // Boolean parameters need special treatment (no enclosing quotes)
                if (parm[1] == 'true' || parm[1] == 'false') {
                    s += '"' + decodeURI(parm[0]) + '":' + decodeURI(parm[1]) + ','
                } else {
                    s += '"' + decodeURI(parm[0]) + '":"' + decodeURI(parm[1]) + '",'
                }
            }
                   
            s = s.substring(0, s.length - 1);
            s = '{' + s + '}';
    
            retVal = JSON.parse(s);
        
        } catch (e) {
            retVal = '';
        }
        
        
        console.log('IHLUXOps.getParmsMap - returning "' + retVal + '"... ');
        return retVal;
        
    }

}(window.IHLUXOps = window.IHLUXOps || {}));    