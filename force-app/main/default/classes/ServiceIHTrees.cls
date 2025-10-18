/////////////////////////////////////////////////////////////////////////////////////////////////////
// CLASSES AND INTERFACES THAT CAN BE IMPLEMENTED TO DELIVER TREE BUILDING AND MANIPULATION SERVICES
//
// Martin Little for Improved Apps
// October 2017
/////////////////////////////////////////////////////////////////////////////////////////////////////


global with sharing class ServiceIHTrees {
    
    // Used by TNS implementations to apply user permissions
    static boolean isUserOnly() {
        ServiceSecurity sS = new ServiceSecurity();
        return ! sS.IsAllowed(ServiceSecurity.KnownSecureOperations.AnalyseHelp);
    }
   
   
   // Used by TNS implementations to obtain key object type information
   static string[] keyTypes() {
        string[] retVal;
        
        try {
            string ObjIds = ControllerSettings.getSettings().SFObjectIds__c;
            retVal = ObjIds.split('\\^');
        } catch (exception e) {
            retVal = new string[]{'ERR!'};
        }
        return retVal;  
   }
   
/////////////////////////////////////////////////////////////////////////////////////////////////////
// TREE NODE PROVIDER FOR HELP TOPICS - ordered alphabetically and not re-orderable
/////////////////////////////////////////////////////////////////////////////////////////////////////

    global with sharing class TNSHelpTopics implements ServiceIHLists.TreeNodeSupplier,ServiceIHLists.TreeOpsSupplier {
        // TREE OPS SUPPLIER IMPLEMENTATION
        public List<ServiceIHLists.KnownTreeOps> SupportedOperations() {
            List<ServiceIHLists.KnownTreeOps> Ops = new List<ServiceIHLists.KnownTreeOps>();
            Ops.add(ServiceIHLists.KnownTreeOps.JITFetching);
            return Ops;
        }
        
        // Setup knowledge of user permissions as we are initialised
        private boolean isUOnly;
        private boolean isUO() {return isUOnly;}
        public TNSHelpTopics() {
            isUOnly = ServiceIHTrees.isUserOnly();
        }
        
        
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {

            system.debug('-------------------------TNS Topics - entry');

            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            ServiceIHLists.ListingItem LI;
            integer levelsProcessed = 0;
            List<string> memberCheck = new List<string> ();
            
            AggregateResult[] allParentHTRs;            // Count of number of parents a given node (topic) has
            HelpRelationship__c[] allParents;           // All parent relationships that have been defined
            
            HelpRelationship__c[] treeHTRs = new HelpRelationship__c[]{};
            HelpRelationship__c[] levelHTRs;
            HelpRelationship__c[] levelChildHTRs;
            map<id,integer> ParentCounts = new map<id,integer>();
            map<id, HelpRelationship__c> deepestChildren = new map<id, HelpRelationship__c>();

            string[] keyTypes = ServiceIHTrees.keyTypes();

            string recencyMarker = 'IHCollateralUpdated';
            DateTime dTRecenyLimit = DateTime.now().addHours(Integer.valueOf(ControllerSettings.getSettings().UpdateMarkerHours__c) * -1);

            try {                    
                // Take note of ALL help relations of type "parent" so we can check whether any given node has more than 1...
                allParentHTRs = [SELECT RelatedHelpTopic__c Topic, COUNT(ReferringTopic__c) CT
                    FROM HelpRelationship__c
                    WHERE SemanticTag__r.Name = 'Parent'
                    AND (ReferringTopic__r.Active__c = true OR ReferringTopic__r.Active__c = :isUO())
                    GROUP BY RelatedHelpTopic__c
                    LIMIT 5000];
                
                for (AggregateResult AR : allParentHTRs) {
                    ParentCounts.put((id) AR.get('Topic'), (integer) AR.get('CT'));
                }
                
                
                // Get all HTRs type = parent
                allParents = [SELECT ReferringTopic__c, 
                                    RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, 
                                    RelatedHelpTopic__r.CustomStyle__c, RelatedHelpTopic__r.MasterTopicIdentifier__c,
RelatedHelpTopic__r.Active__c,                                    
                                    RelatedHelpTopic__r.LastModifiedDate                                    
                                FROM HelpRelationship__c
                                WHERE SemanticTag__r.Name = 'Parent'];
                
                system.debug('-------------------------All parents analysed');
                    
                // Add the top level node
                
/*                
                HelpTopic__c HT = [SELECT Id, Name, Summary__c, CustomStyle__c , MasterTopicIdentifier__c,LastModifiedDate 
                                    FROM HelpTopic__c 
                                    WHERE Id = :rootNode          
                                    AND (Active__c = true OR Active__c = :isUO())];
*/
ControllerHelpContent CH = new ControllerHelpContent (false);
HelpTopic__c HT;
if (CH.getTopicViaHTID(rootNode, isUO()) == true) {
    HT = CH.Hlp;
} else {
    return LIs;
}

        
                LI = new ServiceIHLists.ListingItem();
            
                LI.Id = HT.Id;                       
                LI.MasterId = HT.MasterTopicIdentifier__c;                       
                LI.Label = HT.Name;
                LI.Title = HT.Summary__c;
                LI.ActionCode = '';  
                
                if (keyTypes[0] != 'ERR!') {
                    LI.SupportedDrops = keyTypes[0];             
                } else {
                    LI.SupportedDrops = '';                 
                }             

                LI.Icon = 'fa-question';
                LI.IconTitle = '';                
                LI.StyleClass = HT.CustomStyle__c;        
                
                if (HT.LastModifiedDate > dTRecenyLimit) {LI.StyleClass += ' ' + recencyMarker;}
                        
                LI.Parameters = '';
                
                        
                // If this "top" node has a parent, make "peer" tree control (breadcrumb viewer) available
                // so user can jump back up the tree if desired
                // Also mark this as the "root" node (controls access to certain listing tools)
                if (ParentCounts.containsKey(LI.Id)) {
                
                    LI.RowState = 'HasPeers';
                
                    // Given minimal space, if a node is in more than 9 trees, label it with "+" instead of the number
                    if (ParentCounts.get(LI.Id) > 9) {
                        LI.IconLabel = '+';     
                    } else {
                        LI.IconLabel = '' + ParentCounts.get(LI.Id);     
                    }
                
                } else {
                    LI.RowState = '';           
                    LI.IconLabel = '';
                }
                        
                LIs.add(LI);

                system.debug('-------------------------Top node added');
                    
                    
                // Get children at this level
                levelHTRs = [SELECT ReferringTopic__c, RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, RelatedHelpTopic__r.CustomStyle__c, RelatedHelpTopic__r.MasterTopicIdentifier__c, RelatedHelpTopic__r.LastModifiedDate
                    FROM HelpRelationship__c
                    WHERE SemanticTag__r.Name = 'Parent'
                    AND ReferringTopic__c = :HT.Id
                    AND (RelatedHelpTopic__r.Active__c = true OR RelatedHelpTopic__r.Active__c = :isUO())];
                        
                levelsProcessed += 1;                           
    
    
                // Loop to keep recursing down children, adding them all to a single "output" collection (treeHTRs)
                do {
                    levelChildHTRs = new HelpRelationship__c[]{};
                    
                    for (HelpRelationship__c HTR : levelHTRs) {
                        
                        // Add nodes at this level to the collection:
                        treeHTRs.add(HTR);
                        
                        // Check for children of each level node among list of all parent relationships
                        for (HelpRelationship__c PHTR : allParents) {
                            if (PHTR.ReferringTopic__c == HTR.RelatedHelpTopic__c) {
if (PHTR.RelatedHelpTopic__r.Active__c == true || PHTR.RelatedHelpTopic__r.Active__c == isUO()) {                               
                                levelChildHTRs.add(PHTR);
}                                
                            }
                        }
                    }      
                    levelHTRs = levelChildHTRs; 
                            
                    // Increment the number of levels processed
                    levelsProcessed += 1;           
                                    
                    system.debug('-------------------------Levels processed: ' + levelsProcessed);
                                    
                            
                } while (levelChildHTRs.size() > 0 && (levelsProcessed <= maxLevels || maxLevels == 0));
                
                        
                // Make a map of the last set of child HTRs (which have NOT been added to the tree
                // in the above loop) for checking below
                for (HelpRelationship__c CHTR : levelHTRs) {
                    try {
                        deepestChildren.put(CHTR.ReferringTopic__c, CHTR);
                    } catch (exception ex) {}
                }
                        
                system.debug('-------------------------Deepest children produced - looping to create LIs from treeHTRs...');

                        
                // Loop through all child relations to create listing items to return
                for (HelpRelationship__c HTR : treeHTRs) {
                    LI = new ServiceIHLists.ListingItem();
                        
                    LI.Id = HTR.RelatedHelpTopic__c;                           
                    LI.MasterId = HTR.RelatedHelpTopic__r.MasterTopicIdentifier__c;                                          
                    LI.Label = HTR.RelatedHelpTopic__r.Name;
                    LI.Title = HTR.RelatedHelpTopic__r.Summary__c;
                    LI.ActionCode = '';

                    if (keyTypes[0] != 'ERR!') {
                        LI.SupportedDrops = keyTypes[0];             
                    } else {
                        LI.SupportedDrops = '';                 
                    }             
                    LI.Icon = 'fa-question';
                    LI.IconTitle = '';
                    LI.StyleClass = HTR.RelatedHelpTopic__r.CustomStyle__c; 
                    
                    if (HTR.RelatedHelpTopic__r.LastModifiedDate > dTRecenyLimit) {LI.StyleClass += ' ' + recencyMarker;} 
                                
                    LI.Parameters = HTR.ReferringTopic__c;
                    
                        
                    // Mark nodes that have more than one parent (i.e., they're in multiple hierarchies)
                    if (ParentCounts.get(LI.Id) > 1) {                    
                        LI.RowState = 'HasPeers';
    
                        // Given minimal space, if a node is in more than 9 trees, label it with "+" instead of the number
                        if (ParentCounts.get(LI.Id) > 9) {
                            LI.IconLabel = '+';     
                        } else {
                            LI.IconLabel = '' + ParentCounts.get(LI.Id);     
                        }
                    } else {
                        LI.RowState = '';     
                        LI.IconLabel = '';  
                    }   
                        
                    // Mark nodes that have children which are not included on the tree as they are "deeper" 
                    // than the max depth specified in parameters: these will be in the last set of levelHRTs - as
                    // these don't get added to the treeHTRs collection on the last run through the child finding loop, above...
                    if (deepestChildren.containsKey(LI.Id)) {
                        LI.Label += ' [...]';
                    }                                              
    


                    // Before adding any node, check that its parent does not already contain a copy:
                    // this could happen if a branch and its contents are included at >1 branch higher up the tree
                    if (memberCheck.indexOf(LI.Id + '_' + LI.Parameters) == -1) {                                            
                    
                        // Take note that this relationship has been included on the tree
                        memberCheck.add(LI.Id + '_' + LI.Parameters);
                        LIs.add(LI);
                    }                    
                }
                
            } catch (exception e) {
                // This could well be a lack of nodes: this is legitimate
                // and we simply return the nodes we have to date, if any
                system.debug('-------------------------TNS Topics error: ' + e.getMessage());
                
            }            

            system.debug('-------------------------Returning LIs');
              
            return LIs;
        }
    }


/////////////////////////////////////////////////////////////////////////////////////////////////////
// TREE NODE PROVIDER FOR HELP TOPICS - supports D&D ordering by ordinal
/////////////////////////////////////////////////////////////////////////////////////////////////////

     global with sharing class TNSHelpTopicsOrdered implements ServiceIHLists.TreeNodeSupplier,ServiceIHLists.TreeOpsSupplier{
        
        // TREE OPS SUPPLIER IMPLEMENTATION
        public List<ServiceIHLists.KnownTreeOps> SupportedOperations() {
            List<ServiceIHLists.KnownTreeOps> Ops = new List<ServiceIHLists.KnownTreeOps>();
            Ops.add(ServiceIHLists.KnownTreeOps.NodeOrdering);
            Ops.add(ServiceIHLists.KnownTreeOps.JITFetching);
            return Ops;
        }
        // Setup knowledge of user permissions as we are initialised
        private boolean isUOnly;
        private boolean isUO() {return isUOnly;}
        public TNSHelpTopicsOrdered() {
            isUOnly = ServiceIHTrees.isUserOnly();
        }
        
        
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {

            system.debug('-------------------------TNS Topics - entry');

            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            ServiceIHLists.ListingItem LI;
            integer levelsProcessed = 0;
            List<string> memberCheck = new List<string> ();
            
            AggregateResult[] allParentHTRs;            // Count of number of parents a given node (topic) has
            HelpRelationship__c[] allParents;           // All parent relationships that have been defined
            
            HelpRelationship__c[] treeHTRs = new HelpRelationship__c[]{};
            HelpRelationship__c[] levelHTRs;
            HelpRelationship__c[] levelChildHTRs;
            map<id,integer> ParentCounts = new map<id,integer>();
            map<id, HelpRelationship__c> deepestChildren = new map<id, HelpRelationship__c>();

            string[] keyTypes = ServiceIHTrees.keyTypes();
            
            string recencyMarker = 'IHCollateralUpdated';
            DateTime dTRecenyLimit = DateTime.now().addHours(Integer.valueOf(ControllerSettings.getSettings().UpdateMarkerHours__c) * -1);

            try {                    
                // Take note of ALL help relations of type "parent" so we can check whether any given node has more than 1...
                allParentHTRs = [SELECT RelatedHelpTopic__c Topic, COUNT(ReferringTopic__c) CT
                    FROM HelpRelationship__c
                    WHERE SemanticTag__r.Name = 'Parent'
                    AND (ReferringTopic__r.Active__c = true OR ReferringTopic__r.Active__c = :isUO()) GROUP BY RelatedHelpTopic__c LIMIT 5000];
                
                for (AggregateResult AR : allParentHTRs) {
                    ParentCounts.put((id) AR.get('Topic'), (integer) AR.get('CT'));
                }
                
                
                // Get all HTRs type = parent
                allParents = [SELECT ReferringTopic__c, 
                                    RelatedHelpTopic__c,Order__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, 
                                    RelatedHelpTopic__r.CustomStyle__c, RelatedHelpTopic__r.MasterTopicIdentifier__c,
RelatedHelpTopic__r.Active__c,                                                                        
                                    RelatedHelpTopic__r.LastModifiedDate                                     
                                FROM HelpRelationship__c WHERE SemanticTag__r.Name = 'Parent' ORDER BY Order__c ASC];
                
                system.debug('-------------------------All parents analysed');
                

                // Add the top level node

/*                
                HelpTopic__c HT = [SELECT Id, Name, Summary__c, CustomStyle__c , MasterTopicIdentifier__c,LastModifiedDate 
                                    FROM HelpTopic__c 
                                    WHERE Id = :rootNode          
                                    AND (Active__c = true OR Active__c = :isUO())];
*/
ControllerHelpContent CH = new ControllerHelpContent (false);
HelpTopic__c HT;
if (CH.getTopicViaHTID(rootNode, isUO()) == true) {
    HT = CH.Hlp;
} else {
    return LIs;
}

        
                LI = new ServiceIHLists.ListingItem();
            
                LI.Id = HT.Id;                       
                LI.MasterId = HT.MasterTopicIdentifier__c;                       
                LI.Label = HT.Name;
                LI.Title = HT.Summary__c;
                LI.ActionCode = '';  


                // Note data types that are allowed for D&D operations                
                if (keyTypes[0] != 'ERR!') {
                    LI.SupportedDrops = keyTypes[0];             
                } else {
                    LI.SupportedDrops = '';                 
                }             


                LI.Icon = 'fa-question';
                LI.IconTitle = '';                
                LI.StyleClass = HT.CustomStyle__c; 
                if (HT.LastModifiedDate > dTRecenyLimit) {LI.StyleClass += ' ' + recencyMarker;}
                LI.Parameters = '';
                
                        
                // If this "top" node has a parent, make "peer" tree control (breadcrumb viewer) available
                // so user can jump back up the tree if desired
                // Also mark this as the "root" node (controls access to certain listing tools)
                if (ParentCounts.containsKey(LI.Id)) {
                
                    LI.RowState = 'HasPeers';
                
                    // Given minimal space, if a node is in more than 9 trees, label it with "+" instead of the number
                    if (ParentCounts.get(LI.Id) > 9) {
                        LI.IconLabel = '+';     
                    } else {
                        LI.IconLabel = '' + ParentCounts.get(LI.Id);     
                    }
                
                } else {
                    LI.RowState = '';           
                    LI.IconLabel = '';
                }
                        
                LIs.add(LI);

                system.debug('-------------------------Top node added');
                    
                    
                // Get children at this level
                levelHTRs = [SELECT ReferringTopic__c,Order__c, RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, RelatedHelpTopic__r.CustomStyle__c, RelatedHelpTopic__r.MasterTopicIdentifier__c,RelatedHelpTopic__r.LastModifiedDate 

                    FROM HelpRelationship__c
                    WHERE SemanticTag__r.Name = 'Parent'
                    AND ReferringTopic__c = :HT.Id
                    AND (RelatedHelpTopic__r.Active__c = true OR RelatedHelpTopic__r.Active__c = :isUO()) ORDER BY Order__c ASC];
                        
                levelsProcessed += 1;                           
    
    
                // Loop to keep recursing down children, adding them all to a single "output" collection (treeHTRs)
                do {
                    levelChildHTRs = new HelpRelationship__c[]{};
                    
                    for (HelpRelationship__c HTR : levelHTRs) {
                        
                        // Add nodes at this level to the collection:
                        treeHTRs.add(HTR);
                        
                        // Check for children of each level node among list of all parent relationships
                        for (HelpRelationship__c PHTR : allParents) {
                            if (PHTR.ReferringTopic__c == HTR.RelatedHelpTopic__c) {
if (PHTR.RelatedHelpTopic__r.Active__c == true || PHTR.RelatedHelpTopic__r.Active__c == isUO()) {                                                               
                                levelChildHTRs.add(PHTR);
}                                
                            }
                        }
                    }      
                    levelHTRs = levelChildHTRs; 
                            
                    // Increment the number of levels processed
                    levelsProcessed += 1;           
                                    
                    system.debug('-------------------------Levels processed: ' + levelsProcessed);
                                    
                            
                } while (levelChildHTRs.size() > 0 && (levelsProcessed <= maxLevels || maxLevels == 0));
                
                        
                // Make a map of the last set of child HTRs (which have NOT been added to the tree
                // in the above loop) for checking below
                for (HelpRelationship__c CHTR : levelHTRs) {
                    try {
                        deepestChildren.put(CHTR.ReferringTopic__c, CHTR);
                    } catch (exception ex) {}
                }
                        
                system.debug('-------------------------Deepest children produced - looping to create LIs from treeHTRs...');

                        
                // Loop through all child relations to create listing items to return
                for (HelpRelationship__c HTR : treeHTRs) {
                    LI = new ServiceIHLists.ListingItem();
                        
                    LI.Id = HTR.RelatedHelpTopic__c;                           
                    LI.MasterId = HTR.RelatedHelpTopic__r.MasterTopicIdentifier__c;                                          
                    LI.Label = HTR.RelatedHelpTopic__r.Name;
                    LI.Title = HTR.RelatedHelpTopic__r.Summary__c;
                    LI.ActionCode = '';
                    
                    //Added as part of non-alphabet ordering
                    LI.SortValue = HTR.Order__c+'';

                    // Note data types that are allowed for D&D operations
                    if (keyTypes[0] != 'ERR!') {
                        LI.SupportedDrops = keyTypes[0];             
                    } else {
                        LI.SupportedDrops = '';                 
                    }             
                  
                    LI.Icon = 'fa-question';
                    LI.IconTitle = '';
                    LI.StyleClass = HTR.RelatedHelpTopic__r.CustomStyle__c;  
                    
                    // Style recently added nodes
                    if (HTR.RelatedHelpTopic__r.LastModifiedDate > dTRecenyLimit) {LI.StyleClass += ' ' + recencyMarker;}           
                    
                    LI.Parameters = HTR.ReferringTopic__c;
                    
                        
                    // Mark nodes that have more than one parent (i.e., they're in multiple hierarchies)
                    if (ParentCounts.get(LI.Id) > 1) {                    
                        LI.RowState = 'HasPeers';
    
                        // Given minimal space, if a node is in more than 9 trees, label it with "+" instead of the number
                        if (ParentCounts.get(LI.Id) > 9) {
                            LI.IconLabel = '+';     
                        } else {
                            LI.IconLabel = '' + ParentCounts.get(LI.Id);     
                        }
                    } else {
                        LI.RowState = '';     
                        LI.IconLabel = '';  
                    }   
                        
                    // Mark nodes that have children which are not included on the tree as they are "deeper" 
                    // than the max depth specified in parameters: these will be in the last set of levelHRTs - as
                    // these don't get added to the treeHTRs collection on the last run through the child finding loop, above...
                    if (deepestChildren.containsKey(LI.Id)) {
                        LI.Label += ' [...]';
                    }                                              
    


                    // Before adding any node, check that its parent does not already contain a copy:
                    // this could happen if a branch and its contents are included at >1 branch higher up the tree
                    if (memberCheck.indexOf(LI.Id + '_' + LI.Parameters) == -1) {                                            
                    
                        // Take note that this relationship has been included on the tree
                        memberCheck.add(LI.Id + '_' + LI.Parameters);
                        LIs.add(LI);
                    }                    
                }
                
            } catch (exception e) {
                // This could well be a lack of nodes: this is legitimate
                // and we simply return the nodes we have to date, if any
                system.debug('-------------------------TNS Topics error: ' + e.getMessage());
                
            }            
              
            return LIs;
        }
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TREE NODE PROVIDER FOR HELP TOPICS - PRINTABLE
/////////////////////////////////////////////////////////////////////////////////////////////////////

    global with sharing class TNSPrintableHelpTopics implements ServiceIHLists.TreeNodeSupplier {

        // Setup knowledge of user permissions as we are initialised
        private boolean isUOnly;
        private boolean isUO() {return isUOnly;}
        // Added as part of sorted print view code changes
        IASetIHOrg__c theIAS = IASetIHOrg__c.getInstance('EnabledElements');
        private string sortingType = theIAS.iahelp__DefaultHelpTopicTreeProvider__c;
        public TNSPrintableHelpTopics() {
            isUOnly = ServiceIHTrees.isUserOnly();
        }
        
        
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {
            system.debug(' sortingType '+sortingType);
            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            ServiceIHLists.ListingItem LI;
            integer levelsProcessed = 0;
            
            AggregateResult[] allParentHTRs;            // Count of number of parents a given node (topic) has
            HelpRelationship__c[] allParents;           // All parent relationships that have been defined
            
            HelpRelationship__c[] treeHTRs = new HelpRelationship__c[]{};
            HelpRelationship__c[] levelHTRs;
            HelpRelationship__c[] levelChildHTRs;
            map<id,integer> ParentCounts = new map<id,integer>();
            map<id, HelpRelationship__c> deepestChildren = new map<id, HelpRelationship__c>();

                    
            // Take note of ALL help relations of type "parent" so we can check whether any given node has more than 1...
            allParentHTRs = [SELECT RelatedHelpTopic__c Topic, COUNT(ReferringTopic__c) CT
                FROM HelpRelationship__c
                WHERE SemanticTag__r.Name = 'Parent'
                AND (ReferringTopic__r.Active__c = true OR ReferringTopic__r.Active__c = :isUO())
                GROUP BY RelatedHelpTopic__c
                LIMIT 5000];
            
            for (AggregateResult AR : allParentHTRs) {
                ParentCounts.put((id) AR.get('Topic'), (integer) AR.get('CT'));
            }
            
            //Below if block added as part of sorted print view 
            if(sortingType=='ServiceIHTrees.TNSHelpTopicsOrdered'){
                // Get all HTRs type = parent
                allParents = [SELECT Order__c,ReferringTopic__c, RelatedHelpTopic__c, 
                                    RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, RelatedHelpTopic__r.Description__c,
                                    RelatedHelpTopic__r.ImageURL__c, RelatedHelpTopic__r.CustomStyle__c,
RelatedHelpTopic__r.Active__c                                
                                FROM HelpRelationship__c
                                WHERE SemanticTag__r.Name = 'Parent' ORDER BY Order__c ASC];
                }
            else
            {
                 // Get all HTRs type = parent
                 allParents = [SELECT ReferringTopic__c, RelatedHelpTopic__c, 
                                RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, RelatedHelpTopic__r.Description__c,
                                RelatedHelpTopic__r.ImageURL__c, RelatedHelpTopic__r.CustomStyle__c,
RelatedHelpTopic__r.Active__c                                
                            FROM HelpRelationship__c
                            WHERE SemanticTag__r.Name = 'Parent'];
            }
                
            // Add the top level node
            HelpTopic__c HT = [SELECT Id, Name, Summary__c, Description__c, ImageURL__c, CustomStyle__c 
                                    FROM HelpTopic__c 
                                    WHERE Id = :rootNode
                                    AND (Active__c = true OR Active__c = :isUO())];
            
    
            LI = new ServiceIHLists.ListingItem();
        
            LI.Id = HT.Id;         
            LI.Label = HT.Name;
            LI.Title = HT.Summary__c;
            LI.ActionCode = '';
            LI.SupportedDrops = '';           
            LI.Icon = HT.ImageURL__c;
            
            if (HT.Description__c + '' != 'null') {
                LI.IconTitle = string.escapeSingleQuotes('' + HT.Description__c);
            } else {
                LI.IconTitle = '';
            }
                        
            LI.StyleClass = HT.CustomStyle__c;           
            LI.Parameters = '';
            
                    
            // If this "top" node has a parent, make "peer" tree control (breadcrumb viewer) available
            // so user can jump back up the tree if desired
            // Also mark this as the "root" node (controls access to certain listing tools)
            if (ParentCounts.containsKey(LI.Id)) {
            
                LI.RowState = 'HasPeers';
            
                // Given minimal space, if a node is in more than 9 trees, label it with "+" instead of the number
                if (ParentCounts.get(LI.Id) > 9) {
                    LI.IconLabel = '+';     
                } else {
                    LI.IconLabel = '' + ParentCounts.get(LI.Id);     
                }
            
            } else {
                LI.RowState = '';           
                LI.IconLabel = '';
            }
                    
            LIs.add(LI);
            
          //Below if block added as part of sorted print view   
            if(sortingType=='ServiceIHTrees.TNSHelpTopicsOrdered'){
                system.debug(' Inside sortingType=ServiceIHTrees.TNSHelpTopicsOrdered');
                // Get children at this level
                levelHTRs = [SELECT ReferringTopic__c,Order__c, RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c,
                             RelatedHelpTopic__r.Description__c, RelatedHelpTopic__r.ImageURL__c,RelatedHelpTopic__r.CustomStyle__c, RelatedHelpTopic__r.MasterTopicIdentifier__c
                                FROM HelpRelationship__c
                                WHERE SemanticTag__r.Name = 'Parent'
                                AND ReferringTopic__c = :HT.Id
                                AND (RelatedHelpTopic__r.Active__c = true OR RelatedHelpTopic__r.Active__c = :isUO()) ORDER BY Order__c ASC];
            }
            else{
            // Get children at this level
            levelHTRs = [SELECT ReferringTopic__c, RelatedHelpTopic__c, 
                            RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, RelatedHelpTopic__r.Description__c, 
                            RelatedHelpTopic__r.ImageURL__c, RelatedHelpTopic__r.CustomStyle__c
                FROM HelpRelationship__c
                WHERE SemanticTag__r.Name = 'Parent'
                AND ReferringTopic__c = :HT.Id
                AND (RelatedHelpTopic__r.Active__c = true OR RelatedHelpTopic__r.Active__c = :isUO())];
            }   
                    
            levelsProcessed += 1;                           


            // Loop to keep recursing down children, adding them all to a single "output" collection (treeHTRs)
            do {
                levelChildHTRs = new HelpRelationship__c[]{};
                
                for (HelpRelationship__c HTR : levelHTRs) {
                    
                    // Add nodes at this level to the collection
                    treeHTRs.add(HTR);
                    
                    // Check for children of each level node among list of all parent relationships
                    for (HelpRelationship__c PHTR : allParents) {
                        if (PHTR.ReferringTopic__c == HTR.RelatedHelpTopic__c) {
if (PHTR.RelatedHelpTopic__r.Active__c == true || PHTR.RelatedHelpTopic__r.Active__c == isUO()) {                                                                                           
                            levelChildHTRs.add(PHTR);
}                            
                        }
                    }
                }      
                levelHTRs = levelChildHTRs; 
                        
                // Increment the number of levels processed
                levelsProcessed += 1;                           
                        
            } while (levelChildHTRs.size() > 0 && (levelsProcessed <= maxLevels || maxLevels == 0));
            
                    
            // Make a map of the last set of child HTRs (which have NOT been added to the tree
            // in the above loop) for checking below
            for (HelpRelationship__c CHTR : levelHTRs) {
                try {
                    deepestChildren.put(CHTR.ReferringTopic__c, CHTR);
                } catch (exception ex) {}
            }
                    
                    
            // Loop through all child relations to create listing items to return
            for (HelpRelationship__c HTR : treeHTRs) {
                LI = new ServiceIHLists.ListingItem();
                    
                LI.Id = HTR.RelatedHelpTopic__c;      
                LI.Label = HTR.RelatedHelpTopic__r.Name;
                LI.Title = HTR.RelatedHelpTopic__r.Summary__c;
                LI.ActionCode = '';
                LI.SupportedDrops = '';
                LI.Icon = HTR.RelatedHelpTopic__r.ImageURL__c;
                // Added as part of sorted print view code changes
                if(sortingType=='ServiceIHTrees.TNSHelpTopicsOrdered'){
                    //Added as part of non-alphabet ordering
                    LI.SortValue = HTR.Order__c+'';
                }
                if (HTR.RelatedHelpTopic__r.Description__c + '' != 'null') {
                    LI.IconTitle = string.escapeSingleQuotes('' + HTR.RelatedHelpTopic__r.Description__c);
                } else {
                    LI.IconTitle = '';
                }
                                   
                LI.StyleClass = HTR.RelatedHelpTopic__r.CustomStyle__c;
                LI.Parameters = HTR.ReferringTopic__c;

                    
                // Mark nodes that have more than one parent (i.e., they're in multiple hierarchies)
                if (ParentCounts.get(LI.Id) > 1) {                    
                    LI.RowState = 'HasPeers';

                    // Given minimal space, if a node is in more than 9 trees, label it with "+" instead of the number
                    if (ParentCounts.get(LI.Id) > 9) {
                        LI.IconLabel = '+';     
                    } else {
                        LI.IconLabel = '' + ParentCounts.get(LI.Id);     
                    }
                } else {
                    LI.RowState = '';     
                    LI.IconLabel = '';  
                }   
                    
                // Mark nodes that have children which are not included on the tree as they are "deeper" 
                // than the max depth specified in parameters: these will be in the last set of levelHRTs - as
                // these don't get added to the treeHTRs collection on the last run through the child finding loop, above...
                if (deepestChildren.containsKey(LI.Id)) {
                    LI.Label += ' [...]';
                }                                              

                
                
                LIs.add(LI);
            }
              
            return LIs;
         
        }
        
    }


/////////////////////////////////////////////////////////////////////////////////////////////////////
// TREE NODE PROVIDER FOR A SINGLE READING LIST
/////////////////////////////////////////////////////////////////////////////////////////////////////

    global with sharing class TNSReadingLists implements ServiceIHLists.TreeNodeSupplier, ServiceIHLists.TreeOpsSupplier {
        
        // TREE OPS SUPPLIER IMPLEMENTATION
        public List<ServiceIHLists.KnownTreeOps> SupportedOperations() {
            List<ServiceIHLists.KnownTreeOps> Ops = new List<ServiceIHLists.KnownTreeOps>();
            Ops.add(ServiceIHLists.KnownTreeOps.NodeOrdering);
            return Ops;
        }
        
                
        // TREE NODE SUPPLIER IMPLEMENTATION
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {

            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            ServiceIHLists.ListingItem LI;
            integer levelsProcessed = 0;
            string[] keyTypes = ServiceIHTrees.keyTypes();

            // Add a root
            LI = new ServiceIHLists.ListingItem();

string marker = 'rL_';
//marker = '';
                        
            LI.Id = marker + rootNode;
            LI.Label = 'Reading Lists';
            LI.Title = 'Reading Lists defined for this Org';
            LI.ActionCode = '';
            
            // One cannot drop onto the root - it is a pseudo node
            LI.SupportedDrops = '';
            
            LI.Icon = '';
            LI.IconTitle = '';
            LI.IconLabel = '';
            LI.StyleClass = '';
            LI.Parameters = '';         
            LI.RowState = '';           

            LIs.add(LI);
                
                
            // Obtain the desired RL
            HelpReadingList__c[] RLs = [SELECT Id, Name, Description__c FROM HelpReadingList__c WHERE Id = :rootNode];
            
            for (HelpReadingList__c RL : RLs) {
                LI = new ServiceIHLists.ListingItem();
                    
                LI.Id = RL.Id;
                LI.Label = RL.Name;
                LI.Title = RL.Description__c;
                LI.ActionCode = '';

                // One can drop a topic onto a reading list to add an entry
                if (keyTypes[0] != 'ERR!') {
                    LI.SupportedDrops = keyTypes[0];             
                } else {
                    LI.SupportedDrops = '';                 
                }             

                LI.Icon = 'fa-list-ol';
                LI.IconTitle = '';
                LI.IconLabel = '';
                LI.StyleClass = '';
                LI.Parameters = marker +  rootNode;         
                LI.RowState = '';           

                LIs.add(LI);
            }
                
            // Add RLEs
            HelpReadingListEntry__c[] RLEs = [SELECT Id, HelpReadingList__c, HelpTopic__c, ReadingOrder__c, 
                                                HelpTopic__r.Name, HelpTopic__r.Summary__c
                        FROM HelpReadingListEntry__c 
                        WHERE HelpReadingList__c = :rootNode                        
                        ORDER BY HelpReadingList__c, ReadingOrder__c];
                
            for (HelpReadingListEntry__c RLE : RLEs) {
                LI = new ServiceIHLists.ListingItem();
                        
                LI.Id = RLE.HelpTopic__c;
                LI.Label = RLE.HelpTopic__r.Name;
                LI.Title = RLE.HelpTopic__r.Summary__c;
                LI.ActionCode = '';
                
                // One cannot drop onto an entry - it has no children
                LI.SupportedDrops = '';
                
                // Reading list entries should be sorted by reading order - not name
                LI.SortValue = '' + RLE.ReadingOrder__c;
                
                LI.Icon = 'fa-question-circle';
                LI.IconTitle = '';
                LI.IconLabel = '';
                LI.StyleClass = '';
                LI.Parameters = RLE.HelpReadingList__c;         
                

                LI.RowState = RLE.Id;           
    
                LIs.add(LI);
            }
    
            return LIs;
            
        }
    }


/////////////////////////////////////////////////////////////////////////////////////////////////////
// TREE NODE PROVIDER FOR A SINGLE HELPED PAGE LAYOUT:
// SUPPLY A HPL ID AS ROOT NODE TO SEE ALL ELEMENTS ON THE LAYOUT
// SUPPLY A HELPED ELEMENT ID AS ROOT NODE TO SEE ELEMENTS WITH SAME IDENTIFIER ON SAME LAYOUT ONLY
// SUPPLY HPL IDENTIFIER PLUS HELPED ELEMENT IDENTIFIER AS ROOT NODE TO SEE ELEMENTS WITH SAME IDENTIFIER ON SAME LAYOUT ONLY 
/////////////////////////////////////////////////////////////////////////////////////////////////////

    global with sharing class TNSHelpedPageLayouts implements ServiceIHLists.TreeNodeSupplier {
        
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {

            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            ServiceIHLists.ListingItem LI;
            integer levelsProcessed = 0;
            
            string HPLCode = ServiceSchema.getObjectIdByName('iahelp__HelpedPageLayout__c');
            string HECode = ServiceSchema.getObjectIdByName('iahelp__HelpedElement__c');
            HelpedPageLayout__c HPL;
            HelpedElement__c[] HEs;
            string D1 = '^';
            string D2 = ':';
            
            
            /*
            We may have been supplied with a root node that is:
                - a helped page layout ID (in which case we want HPL and all elements on it)
                - a helped element ID (in which case we want only that element and its HPL)
                - data about a DDF fail, in which case we'll have Layout Identifier ^ Element Identifier, and we'll
                    want to return all elements with the specifier identifier
            */

            if ((rootNode.indexOf(D1) != -1 || rootNode.indexOf(D2) != -1) && ! rootNode.startsWith(HPLCode)) {
                // DDF fail
                string[] idents;
                if(rootNode.indexOf(D1) != -1){             
                    idents = rootNode.split('\\^');
                }
                if(rootNode.indexOf(D2) != -1){             
                    idents = rootNode.split('\\:');
                }
                system.debug('idents '+idents);
                HPL = [SELECT Id, Name FROM HelpedPageLayout__c WHERE PageLayoutIdentifier__c = :idents[0]];
            
                HEs = [SELECT Id, Name, HelpedPageLayout__c, HelpFilter__c, 
                            HelpTopic__c, HelpTopic__r.Name, HelpTopic__r.Summary__c 
                        FROM HelpedElement__c 
                        WHERE HelpedPageLayout__c = :HPL.Id
                        AND Identifier__c = :idents[1]];
                system.debug('HEs'+HEs);
            } else if (rootNode.startsWith(HPLCode)) {
                // Root node is a HPL ID - return that layout and all elements
                HPL = [SELECT Id, Name FROM HelpedPageLayout__c WHERE Id = :rootNode];
                HEs = [SELECT Id, Name, HelpedPageLayout__c, HelpFilter__c,
                            HelpTopic__c, HelpTopic__r.Name, HelpTopic__r.Summary__c 
                        FROM HelpedElement__c 
                        WHERE HelpedPageLayout__c = :rootNode];
                
            } else if (rootNode.startsWith(HECode)) {
                // Root node is element ID - return only elements with same identifier and layout
                HelpedElement__c desiredHE = [SELECT Id, HelpedPageLayout__c, ElementType__c, Identifier__c FROM HelpedElement__c WHERE Id = :rootNode];
                HPL = [SELECT Id, Name FROM HelpedPageLayout__c WHERE Id = :desiredHE.HelpedPageLayout__c];
            
                HEs = [SELECT Id, Name, HelpedPageLayout__c, HelpFilter__c,
                            HelpTopic__c, HelpTopic__r.Name, HelpTopic__r.Summary__c                  
                        FROM HelpedElement__c 
                        WHERE HelpedPageLayout__c = :desiredHE.HelpedPageLayout__c
                        AND ElementType__c = :desiredHE.ElementType__c
                        AND Identifier__c = :desiredHE.Identifier__c];
                    
            } 

                
            // Add HPL as root
            LI = new ServiceIHLists.ListingItem();
                
            LI.Id = HPL.Id;
            LI.Label = HPL.Name;
            LI.Title = '';
            LI.ActionCode = '';
            LI.SupportedDrops = '';
            LI.Icon = 'fa-table';
            LI.IconTitle = '';
            LI.IconLabel = '';
            LI.StyleClass = '';
            LI.Parameters = '';         
            LI.RowState = '';           

            LIs.add(LI);

                
            // Add HEs
            for (HelpedElement__c HE : HEs) {
                LI = new ServiceIHLists.ListingItem();
                        
                LI.Id = HE.Id;
                LI.Label = HE.Name;
                LI.Title = '';
                LI.ActionCode = '';
                LI.SupportedDrops = '';
                LI.Icon = 'fa-wrench';
                LI.IconTitle = '';
                LI.IconLabel = '';
                LI.StyleClass = '';
                LI.Parameters = HE.HelpedPageLayout__c;         
                LI.RowState = '';           
    
                LIs.add(LI);

                // Add topic info for each HE
                if (HE.HelpTopic__c + '' != '' && HE.HelpTopic__c != null) {
    
                    LI = new ServiceIHLists.ListingItem();
                            
                    LI.Id = HE.HelpTopic__c;
                    LI.Label = HE.HelpTopic__r.Name;
                    LI.Title = '';
                    LI.ActionCode = '';
                    LI.SupportedDrops = '';
                    LI.Icon = 'fa-question-circle';
                    LI.IconTitle = '';
                    LI.IconLabel = '';
                    LI.StyleClass = '';
                    LI.Parameters = HE.Id;         
                    LI.RowState = '';           
        
                    LIs.add(LI);                
                }
            }
            



            // Add filters & criteria:
            // Create a map with details of all help filters
            map<id,iahelp__HelpFilter__c> mapOfHelpFilter = new map<id,iahelp__HelpFilter__c> ([
                    SELECT Id, Name, iahelp__FilterLogic__c, iahelp__FilterIdentifier__c, iahelp__FilteredObject__c, iahelp__FilteredObjectIdentifier__c 
                    FROM iahelp__HelpFilter__c LIMIT 50000
                    ]);
        
            // Create a map with details of each filter criterion in each filter
            map<id,list<iahelp__HelpFilterCriterion__c>> mapOfHFAndHFC = new map<id,list<iahelp__HelpFilterCriterion__c>>();
            
            for (iahelp__HelpFilter__c hf : [
                    SELECT id,(
                        SELECT Id, Name, iahelp__HelpFilter__c, iahelp__FilteredField__c, 
                                iahelp__Operator__c, iahelp__CriterionNumber__c, iahelp__FilterValue__c,
                                iahelp__FilteredFieldType__c 
                        FROM iahelp__HelpFilterCriteria__r 
                        ORDER BY iahelp__CriterionNumber__c ASC LIMIT 50000) 
                    FROM iahelp__HelpFilter__c LIMIT 50000]){
                                                    
                if(hf.iahelp__HelpFilterCriteria__r!=null){
                    mapOfHFAndHFC.put(hf.id,hf.iahelp__HelpFilterCriteria__r);
                }
            }
            
            // Map of criteria that have already been processed / added to their parents
            set<string> ProcessedFilters = new set<string>();
    
            // Loop through elements to add filters & criteria, where required
            for (HelpedElement__c HE : HEs) {
                
                if (HE.HelpFilter__c != null) {
                    
                    // Add help filter node, if filter is present
                    LI = new ServiceIHLists.ListingItem();
                                
                    LI.Id = mapOfHelpFilter.get(HE.HelpFilter__c).Id;
                    LI.Label = mapOfHelpFilter.get(HE.HelpFilter__c).FilterIdentifier__c;
                    LI.Title = '';
                    LI.ActionCode = '';
                    LI.SupportedDrops = '';
                    LI.Icon = 'fa-filter';
                    LI.IconTitle = '';
                    LI.IconLabel = '';
                    LI.StyleClass = '';
                    LI.Parameters = HE.Id;         
                    LI.RowState = '';           
            
                    LIs.add(LI);                    
                    
                    // Add nodes for each of filter's criteria
                    // As filters can be reused on multiple helped elements, make sure this filter node hasn't been 'built'
                    // to include its child criteria already as we don't want to add duplicate children
            
                    if (! ProcessedFilters.contains(HE.HelpFilter__c)) {
            
                        for(HelpFilterCriterion__c HFC : mapOfHFAndHFC.get(HE.HelpFilter__c)) {             
                            LI = new ServiceIHLists.ListingItem();
                                            
                            LI.Id = HFC.Id;
                            LI.Label = HFC.CriterionNumber__c + ': ' + HFC.FilteredField__c + ' ' + HFC.Operator__c + ' ' + HFC.FilterValue__c;
                            LI.Title = '';
                            LI.ActionCode = '';
                            LI.SupportedDrops = '';
                            LI.Icon = 'fa-filter fa-rotate-270';
                            LI.IconTitle = '';
                            LI.IconLabel = '';
                            LI.StyleClass = '';
                            LI.Parameters = mapOfHelpFilter.get(HE.HelpFilter__c).Id;         
                            LI.RowState = '';           
                        
                            LIs.add(LI);                                
                        }
                
                        //Add this criteria to a collection to say it's been processed / added to its parent already
                        ProcessedFilters.add(HE.HelpFilter__c);
                    }        
                }
            }

            return LIs;            
        }
    }


/////////////////////////////////////////////////////////////////////////////////////////////////////
// CHATTER TESTS
/////////////////////////////////////////////////////////////////////////////////////////////////////


    global with sharing class TNSChatter implements ServiceIHLists.TreeNodeSupplier {
        
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {

            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            ServiceIHLists.ListingItem LI;
            integer levelsProcessed = 0;
            string sTest;
            boolean doAdd;
/*            
            // Add a root
            LI = new ServiceIHLists.ListingItem();
                        
            LI.Label = 'Chatter Posts';
            LI.Title = 'Matching Chatter Posts';
            LI.ActionCode = '';
            LI.Icon = 'fa-commenting';
            LI.IconLabel = '';
            LI.IconTitle = '';
            LI.Parameters = '';         
            LI.StyleClass = '';
            LI.Id = 'CPs';
            LI.RowState = '';           
    
            LIs.add(LI);
            
            
            // Add child groupings for known objects of interest
            LI = new ServiceIHLists.ListingItem();
            LI.Label = 'Accounts';
            LI.Title = 'Posts to Accounts';
            LI.ActionCode = '';
            LI.Icon = 'fa-building-o';
            LI.IconLabel = '';
            LI.IconTitle = '';
            LI.Parameters = 'CPs';         
            LI.StyleClass = '';
            LI.Id = 'Accounts';
            LI.RowState = '';           
            LIs.add(LI);

            LI = new ServiceIHLists.ListingItem();
            LI.Label = 'Leads';
            LI.Title = 'Posts to Leads';
            LI.ActionCode = '';
            LI.Icon = 'fa-bullseye';
            LI.IconLabel = '';
            LI.IconTitle = '';
            LI.Parameters = 'CPs';         
            LI.StyleClass = '';
            LI.Id = 'Leads';
            LI.RowState = '';           
            LIs.add(LI);

            LI = new ServiceIHLists.ListingItem();
            LI.Label = 'Contacts';
            LI.Title = 'Posts to Contacts';
            LI.ActionCode = '';
            LI.Icon = 'fa-heart-o';
            LI.IconLabel = '';
            LI.IconTitle = '';
            LI.Parameters = 'CPs';         
            LI.StyleClass = '';
            LI.Id = 'Contacts';
            LI.RowState = '';           
            LIs.add(LI);

            LI = new ServiceIHLists.ListingItem();
            LI.Label = 'Opportunities';
            LI.Title = 'Posts to Opportunities';
            LI.ActionCode = '';
            LI.Icon = 'fa-rocket';
            LI.IconLabel = '';
            LI.IconTitle = '';
            LI.Parameters = 'CPs';         
            LI.StyleClass = '';
            LI.Id = 'Opportunities';
            LI.RowState = '';           
            LIs.add(LI);
            
            LI = new ServiceIHLists.ListingItem();
            LI.Label = 'Other';
            LI.Title = 'Other Posts';
            LI.ActionCode = '';
            LI.Icon = 'fa-random';
            LI.IconLabel = '';
            LI.IconTitle = '';
            LI.Parameters = 'CPs';         
            LI.StyleClass = '';
            LI.Id = 'Other';
            LI.RowState = '';           
            LIs.add(LI);
            
                
            // Add Posts
            FeedItem[] FIs = [SELECT Id, ParentId, Title, Body 
                                FROM FeedItem
                                LIMIT 100];
                    
            for (FeedItem FI : FIs) {
                
                // Only add if we have a title or a body
                sTest = '';
                
                if (FI.Title == '' || FI.Title == null) {
                    if (FI.Body != '' && FI.Body != null) {
                        sTest = FI.Body;
                        if (sTest.length() > 50) {
                            sTest = sTest.substring(0, 50);
                        }
                    }               
                } else {
                    sTest = FI.Title;
                }
                
                
                if (sTest != '') {
                    LI = new ServiceIHLists.ListingItem();
                            
                    LI.Label = sTest;
                    LI.Title = FI.Body;
                    LI.ActionCode = 'FeedItem';
                    LI.Icon = 'fa-commenting-o';
                    LI.IconLabel = '';
                    LI.IconTitle = '';
                    
                    sTest = FI.ParentId;
                    if (sTest.subString(0, 3) == '001') {
                        LI.Parameters = 'Accounts';    
                    } else if (sTest.subString(0, 3) == '003') {
                        LI.Parameters = 'Contacts';    
                    } else if (sTest.subString(0, 3) == '00Q') {
                        LI.Parameters = 'Leads';    
                    } else if (sTest.subString(0, 3) == '006') {
                        LI.Parameters = 'Opportunities';    
                    } else {
                        LI.Parameters = 'Other';    
                    }
                         
                    LI.StyleClass = '';
                    LI.Id = FI.ParentId;
                    LI.RowState = '';           
        
                    LIs.add(LI);                    
                }
            }

*/                
            return LIs;
            
        }
    }

 
/////////////////////////////////////////////////////////////////////////////////////////////////////
// FOR SHOWING TOPICS AND THEIR RELATED RESOURCES
/////////////////////////////////////////////////////////////////////////////////////////////////////

    global with sharing class TNSTopicRelatives implements ServiceIHLists.TreeNodeSupplier {
        
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {

            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            ServiceIHLists.ListingItem LI;
            integer levelsProcessed = 0;
            string sTest;
            boolean doAdd;
            
            map<id, HelpTopic__c> TreeHTs = new map<id, HelpTopic__c>();
            map<id, string> RootHTs = new map<id, string>();
            string[] rootNs;
            integer i;
            
            
            // Add the "absolute" root
            LI = new ServiceIHLists.ListingItem();
                        
            LI.Id = 'Root';
            LI.Label = 'Topics and Resources';
            LI.Title = 'Help Topics and their related Resources';
            LI.ActionCode = '';
            LI.SupportedDrops = '';
            LI.Icon = 'fa-tree';
            LI.IconTitle = '';
            LI.IconLabel = '';
            LI.StyleClass = '';
            LI.Parameters = '';         
            LI.RowState = '';           
    
            LIs.add(LI);
            
            // Extract specified root topics into map
            rootNs = rootNode.split(',');
            for (i=0; i< rootNs.size(); i++) {
                rootHTs.put(rootNs[i], rootNs[i]);
            }
            
            // Add the root topics as children of the "absolute" root
            HelpTopic__c[] HTs = [SELECT Id, Name, Summary__c 
                                FROM HelpTopic__c
                                WHERE Id IN :RootHTs.keyset()];
                    
            for (HelpTopic__c HT : HTs) {
                
                LI = new ServiceIHLists.ListingItem();
                        
                LI.Id = HT.Id;
                LI.Label = HT.Name;
                LI.Title = HT.Summary__c;
                LI.ActionCode = '';
                LI.SupportedDrops = '';
                LI.Icon = 'fa-question';
                LI.IconTitle = '';
                LI.IconLabel = '';
                LI.StyleClass = '';
                LI.Parameters = 'Root';         
                LI.RowState = '';           
    
                LIs.add(LI); 
                
                
                // Add a child "relatives root" for each topic
                LI = new ServiceIHLists.ListingItem();
                        
                LI.Id = 'RelRes_' + HT.Id;
                LI.Label = 'Related Resources';
                LI.Title = 'Resources related to the selected Topic';
                LI.ActionCode = '';
                LI.SupportedDrops = '';
                LI.Icon = 'fa-map-signs';
                LI.IconTitle = '';
                LI.IconLabel = '';
                LI.StyleClass = '';
                LI.Parameters = HT.Id;         
                LI.RowState = '';           
    
                LIs.add(LI); 
                
                // Keep HT Id
                TreeHTs.put(HT.Id, HT);
                                   
            }
            
            
            // Obtain all related resources
            HelpTopicResource__c[] HTRs = [SELECT Id, HelpTopic__c, HelpResource__c, UsageNotes__c,
                                                HelpResource__r.Name, HelpResource__r.ResourceURL__c
                                            FROM HelpTopicResource__c
                                            WHERE HelpTopic__c IN :TreeHTs.keyset()];

            // Add a child node for each related resource                                           
            for (HelpTopicResource__c HTR : HTRs) {
                
                LI = new ServiceIHLists.ListingItem();
                        
                LI.Id = HTR.Id;
                LI.Label = HTR.HelpResource__r.Name;
                LI.Title = HTR.UsageNotes__c;
                LI.ActionCode = '';
                LI.SupportedDrops = '';
                LI.Icon = 'fa-map-signs';
                LI.IconTitle = '';
                LI.IconLabel = '';
                LI.StyleClass = '';
                LI.Parameters = 'RelRes_' + HTR.HelpTopic__c;         
                LI.RowState = '';           
    
                LIs.add(LI); 
            }
            
            return LIs;
            
        }
    }
 
    
    
/////////////////////////////////////////////////////////////////////////////////////////////////////
// FOR SHOWING SCHEMA ELEMENTS
/////////////////////////////////////////////////////////////////////////////////////////////////////

    global with sharing class TNSOrgSchema implements ServiceIHLists.TreeNodeSupplier {
        
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {

            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            ServiceIHLists.ListingItem LI;
            
            ServiceSchema svsS = new ServiceSchema();
            Schema.DescribeSObjectResult[] results = svsS.getAllObjects();    
               
            
            // Add the "absolute" root
            LI = new ServiceIHLists.ListingItem();
                        
            LI.Id = 'Root';
            LI.Label = 'Schema';
            LI.Title = 'Your org\'s objects and fields';
            LI.ActionCode = '';
            LI.SupportedDrops = '';
            LI.Icon = 'fa-globe';
            LI.IconTitle = '';
            LI.IconLabel = '';
            LI.StyleClass = '';
            LI.Parameters = '';         
            LI.RowState = '';           
    
            LIs.add(LI);
            
            
            // Add a node for each object
            for (Schema.DescribeSObjectResult R : results) {

                if ('' + R.getKeyPrefix() != 'null') {
                    LI = new ServiceIHLists.ListingItem();
                                
                    LI.Id = '' + R.getKeyPrefix();
                    LI.Label = R.getLabel() + ' (' + R.getKeyPrefix() + ' - ' + R.getName() + ')';
                    LI.Title = '';
                    LI.ActionCode = '';
                    LI.SupportedDrops = '';
                    LI.Icon = 'fa-table';
                    LI.IconTitle = '';
                    LI.IconLabel = '';
                    LI.StyleClass = '';
                    LI.Parameters = 'Root';         
                    LI.RowState = '';           
            
                    LIs.add(LI);                    
                }
            }            
                            
            return LIs;
            
        }
    } 
    

/////////////////////////////////////////////////////////////////////////////////////////////////////
// TREE OF TAG POOLS AND THEIR MEMBER TAGS, PLUS TOPICS WITH THOSE TAGS SET
/////////////////////////////////////////////////////////////////////////////////////////////////////

    global with sharing class TNSTagPools implements ServiceIHLists.TreeNodeSupplier {
        
        // NOTE: in this case, 'rootNode' is the current context help topic - because
        // our root is always the same (we just show all tag pools under a 'pools' root...)

        // FOR TAG POOLS:
        //      - Pool topic is defined by: having member relationships, i.e. ...
        //      - A member tag is defined by: topic with relationship of type 'member' - referring topic = pool, related = member
        //      - A tagged item is defined by: topic with relationshio of type 'relative' - referring topic = tagged item, related topic = tag
        
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {

            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();         // List of nodes to return
            List<ServiceIHLists.ListingItem> LIsTemp = new List<ServiceIHLists.ListingItem> ();     // Working / temporary node list
            ServiceIHLists.ListingItem LI;
            
            map<id,string> mapPools = new map<id,string>();             // Map of topics forming pools
            map<id,string> mapMembers = new map<id,string>();           // Map of topics forming member tags
            map<id,string> mapCxtRels = new map<id,string>();           // Map of topics related to context help topic
            map<id,string> mapHasTaggedItems = new map<id,string>();    // Map of Pool-defining topics with at least 1 member tag checked
            
            SemanticTag__c memTag = [SELECT Id FROM SemanticTag__c WHERE Name = 'Member'];
            SemanticTag__c relTag = [SELECT Id FROM SemanticTag__c WHERE Name = 'Relative'];
            
            // Add the "absolute" root
            LI = new ServiceIHLists.ListingItem();
                        
            LI.Id = 'Root';
            LI.Label = 'Tags';
            LI.Title = 'Tag Pools and their Member Tags';
            LI.ActionCode = '';
            LI.SupportedDrops = '';
            LI.Icon = 'fa-tags';
            LI.IconTitle = '';
            LI.IconLabel = '';
            LI.StyleClass = '';
            LI.Parameters = '';         
            LI.RowState = '';           
    
            LIs.add(LI);

            
            // Get all context topic's relatives(which will include tags set for it) and put into a map
            for (HelpRelationship__c Rel : [SELECT RelatedHelpTopic__c, RelatedHelpTopic__r.Name 
                                            FROM HelpRelationship__c
                                            WHERE SemanticTag__c = :relTag.Id
                                            AND ReferringTopic__c = :rootNode]) {

                if (mapCxtRels.get(Rel.RelatedHelpTopic__c) == null) {                  
                    mapCxtRels.put(Rel.RelatedHelpTopic__c, Rel.RelatedHelpTopic__r.Name);
                }               
            }
                        
            
            // Get all relationships representing member tags 
            for (HelpRelationship__c Rel : [SELECT Id, 
                                                ReferringTopic__c, ReferringTopic__r.Name, ReferringTopic__r.Summary__c, ReferringTopic__r.CustomStyle__c,
                                                RelatedHelpTopic__c, RelatedHelpTopic__r.Name, RelatedHelpTopic__r.Summary__c, RelatedHelpTopic__r.CustomStyle__c
                                            FROM HelpRelationship__c
                                            WHERE SemanticTag__c = :memTag.Id]) {
                
                // (If we haven't already) add a parent node for each member relationship's parent tag pool                                             
                if (mapPools.get(Rel.ReferringTopic__c) == null) {
                    
                    mapPools.put(Rel.ReferringTopic__c, Rel.ReferringTopic__r.Name);
                    
                    LI = new ServiceIHLists.ListingItem();
                                
                    LI.Id = Rel.ReferringTopic__c;
                    LI.Label = Rel.ReferringTopic__r.Name;
                    LI.Title = Rel.ReferringTopic__r.Summary__c;                  
                    LI.ActionCode = 'TagPoolSelected';
                    LI.SupportedDrops = '';
                    LI.Icon = 'fa-tags';
                    LI.IconTitle = '';
                    LI.IconLabel = '';
                    LI.StyleClass = Rel.ReferringTopic__r.CustomStyle__c;       
                    LI.Parameters = 'Root';         
                    LI.RowState = '';    
            
                    LIs.add(LI);                    
                }
                
                
                // (Always) add a node for each child member tag, plus add to map of members
                mapMembers.put(Rel.RelatedHelpTopic__c, Rel.RelatedHelpTopic__r.Name);               
                LI = new ServiceIHLists.ListingItem();
                            
                LI.Id = Rel.RelatedHelpTopic__c;
                LI.Label = Rel.RelatedHelpTopic__r.Name;
                LI.Title = Rel.RelatedHelpTopic__r.Summary__c;               
                LI.ActionCode = 'ToggleTag';
                LI.SupportedDrops = '';
                LI.Icon = 'fa-tag';
                LI.IconTitle = '';
                LI.IconLabel = '';

                // Mark tags that are set on the current context help topic:
                // Is there a 'relative' relationship where:
                //      - Referrer      = Current context topic
                //      - Related       = This (Rel's) Related topic
                                       
                if (mapCxtRels.get(Rel.RelatedHelpTopic__c) != null) {
                    LI.StyleClass = 'Tagged ' + Rel.RelatedHelpTopic__r.CustomStyle__c;
                    
                    // Note the fact that this item's pool is 'in use' / has at least 1 member tagged
                    if (mapHasTaggedItems.get(Rel.ReferringTopic__c) == null) {
                        mapHasTaggedItems.put(Rel.ReferringTopic__c, Rel.ReferringTopic__r.Name);
                    }
                    
                } else {
                    LI.StyleClass = Rel.RelatedHelpTopic__r.CustomStyle__c; 
                }                    
                

                LI.Parameters = Rel.ReferringTopic__c;   
                LI.RowState = '';           
        
                LIs.add(LI);    
            }


            // Get all topics marked with any tag (keys identified above) for use below
            HelpRelationship__c[] allTaggedItems = new HelpRelationship__c[]{};
            try {
                allTaggedItems = [SELECT ReferringTopic__c, ReferringTopic__r.Name, ReferringTopic__r.Summary__c, ReferringTopic__r.CustomStyle__c,
                                        RelatedHelpTopic__c
                                    FROM HelpRelationship__c
                                    WHERE SemanticTag__c = :relTag.Id
                                    AND RelatedHelpTopic__c IN :mapMembers.keySet()
                                    AND ReferringTopic__c != NULL
                                    ];               
            } catch (exception ex){}

            
            // Loop through all nodes created
            for (ServiceIHLists.ListingItem L : LIs) {
            
                if (L.Parameters == 'Root') {
                    
                    // For nodes that define a pool, add an 'in use' style where appropriate:               
                    // These have at least 1 child marked as tagged, as noted above             
                    if (mapHasTaggedItems.get(L.Id) != null) {
                        L.StyleClass += ' PoolInUse';
                    } else {
                        L.StyleClass += ' PoolNotInUse';    
                    }    
                                            
                } else {

                    // For member tags, add any topics that use the tag
                    for (HelpRelationship__c Rel : allTaggedItems) {
                        
                        if (L.Id != 'Root') {                       
                            if (L.Id == Rel.RelatedHelpTopic__c) {
    
                                // Add node
                                LI = new ServiceIHLists.ListingItem();
                
                                LI.Id = Rel.ReferringTopic__c;         
                                LI.Label = Rel.ReferringTopic__r.Name;
                                LI.Title = Rel.ReferringTopic__r.Summary__c;
                                LI.ActionCode = '';
                                LI.SupportedDrops = '';
                                LI.Icon = 'fa-question';
                                LI.IconTitle = '';
                                LI.IconLabel = '';
                                LI.StyleClass = Rel.ReferringTopic__r.CustomStyle__c;
                                LI.Parameters = L.Id;
                                LI.RowState = '';           
                            
                                LIsTemp.add(LI);
                                
                            }
                        }                       
                    }                   
                }
            }
            
            // Add any child tagged topic nodes from the temporary collection to our output
            for (ServiceIHLists.ListingItem L : LIsTemp) {
                LIs.add(L);
            }
            
            return LIs;
        }
    } 




/////////////////////////////////////////////////////////////////////////////////////////////////////
// Just in time topics and relatives
/////////////////////////////////////////////////////////////////////////////////////////////////////

    global with sharing class TNSJITHelpRecords implements ServiceIHLists.TreeNodeSupplier {
        
        public List<ServiceIHLists.ListingItem> getTreeNodes (string rootNode, integer maxLevels) {

            List<ServiceIHLists.ListingItem> LIs = new List<ServiceIHLists.ListingItem> ();
            ServiceIHLists.ListingItem LI;
                        
            // Add the "absolute" root
            LI = new ServiceIHLists.ListingItem();

            // Obtain root dependent on type requested
            string[] keyTypes = ServiceIHTrees.keyTypes();
            sObject obj;

            string strTable;
            
            // Known types:
            // 0 = topics
            // 1 = RLs
            // 2 = Resources
            // 3 = Topic templates
            // 4 = Signatures
            // 5 = Help vote sets
            // 6 = Interactions
            
            
            if (keyTypes[0] != 'ERR!') {
                
                if (rootNode.startsWith(keyTypes[0])) {
                    //strTable = 'iahelp__HelpTopic__c';
                    obj = [SELECT Id, Name FROM HelpTopic__c WHERE Id =:rootNode];
                    LI.Icon = 'fa-question';
            
                } else if (rootNode.startsWith(keyTypes[1])) {
                    //strTable = 'iahelp__HelpReadingList__c';
                    obj = [SELECT Id, Name FROM HelpReadingList__c WHERE Id =:rootNode];
                    LI.Icon = 'fa-list-ol';
            
                } else if (rootNode.startsWith(keyTypes[2])) {
                    //strTable = 'iahelp__HelpResource__c';
                    obj = [SELECT Id, Name FROM HelpResource__c WHERE Id =:rootNode];
                    LI.Icon = 'fa-map-signs';
                    
                } else {
                    strTable = 'Unsupported Type';
                }
                
                
                if (strTable != 'Unsupported Type') {
            
                    //strSOQL += strTable + ' WHERE Id = \'' + rootNode + '\'';
                    //obj = database.query(strSOQL);
                    
                    LI.Id = obj.Id;
                    LI.Label = '' + obj.get('Name');
                    LI.Title = 'Expand to see related items...';
                    
                    LI.ActionCode = 'TreeGetChildNodes';
                    LI.SupportedDrops = '';
                    LI.IconTitle = '';
                    LI.IconLabel = '';
                    LI.StyleClass = '';
                    LI.Parameters = '';         
                    LI.RowState = '';           
                            
                } else {
                    LI.Label = strTable;
                }
                                
            } else {
                LI.Label = 'ERROR!';                
            }             

                        
    
            LIs.add(LI);
            
                            
            return LIs;
            
        }
    } 

}