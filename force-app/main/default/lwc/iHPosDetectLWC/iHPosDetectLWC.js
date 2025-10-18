import { LightningElement, api, wire, track } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import passthroughMessage from '@salesforce/messageChannel/MyMessageChannel__c';
import logHelpInteractions from '@salesforce/apex/ControllerLUXOps.logHelpInteractions';
import getOrgSettings from '@salesforce/apex/ControllerLUXOps.getOrgSettings';
import isGeoEnabled from '@salesforce/apex/ServiceSecurity.isGeoEnabled';
import updateInteractionDescription from '@salesforce/apex/ControllerLUXOps.updateInteractionDescription';
import { CurrentPageReference } from 'lightning/navigation';

export default class IHPosDetectLWC extends LightningElement {
    @api positioningrole;
    @api positioningGroup; // Positioning Group
    @api helpContext;      // Help Context (Help Topic ID)
    @api logContextInteraction;
    @api contextcheckinterval;
    @api label = '';       // Button text
    @api tooltipText = 'Help for this area..'; // Tooltip
    @api color = '';       // Optional custom color (hex without #)
    @api HelpButtonTextSize = 'Small';
    @api HelpButtonTextStyle = 'Ellipsis';
    @api HelpButtonTextWidth = '250';
    @api HelpButtonPosition = 'Right';
    @api UXTheme;
    @api BackgroundStyle;

    @api globalSettings;

    @track lastUrl = '';
    @track lastContext = '';
    @track helpCueIssued = false;
    @track contextInteractionLogged = false;
    @track contextCheckTimer;
    @track counter = 0;
    @track isInitialised = false;
    @track lastSavesHelpInteractionId = '';
    @track currentInteractionId = null;
    @wire(MessageContext) messageContext;
    @wire(CurrentPageReference) pageRef;

    eventTracker;

    connectedCallback() {
        this.lastUrl = window.location.pathname + window.location.search;
        this.lastContext = this.deriveContext();
        window.addEventListener('visibilitychange', this.handleVisibilityChange);
        getOrgSettings()
            .then(result => {
                this.globalSettings = result;
                this.initializeComponent();
            })
            .catch(error => {
                console.error('Error fetching org settings:', error);
            });
        if (this.contextCheckTimer) {
            clearInterval(this.contextCheckTimer);
            this.contextCheckTimer = null;
        }
        if (this.contextcheckinterval > 0) {
            this.contextCheckTimer = window.setInterval(() => {
                this.checkContext();
            }, this.contextcheckinterval);
        }
    }

    handleVisibilityChange = () => {
        if (document.visibilityState === 'hidden' && this.currentInteractionId) {
            this.updateDepartureTime(this.currentInteractionId);
        }
    };

           //The PositionGroup value is not accessible inside checkContext() due to the reset flag to avoid duplication of interaction Logging 
    //hence, using rendered callback function.
    async renderedCallback() {
        if (this.positioningrole === 'Help Cue') {
            this.eventTracker = this.template.querySelector('c-i-h-event-tracker');
            this.handleVisibilityCheck();
        }
        try {
            var currentUrl = window.location.pathname + window.location.search;
            var newContext = this.deriveContext();
            var contextChanged = newContext !== this.lastContext;

            if (currentUrl !== this.lastUrl) {
                if (this.currentInteractionId) {
                    await this.updateDepartureTime(this.currentInteractionId);
                }

                if (contextChanged) {
                    var description = this.eventTracker?.generateSummaryDescription() + '^' + this.positioningGroup || newContext;
                    if (this.eventTracker) {
                        this.eventTracker.resetEvents();
                    }

                    this.lastContext = newContext;
                    this.counter = 0;
                } else {
                    if (this.logContextInteraction) {
                        var description = this.eventTracker?.generateSummaryDescription() + '^' + this.positioningGroup || "List View Filter Change";
                    }
                }
            } else {
                if (this.logContextInteraction && this.currentInteractionId) {
                    var description = this.eventTracker?.generateSummaryDescription() || this.lastContext;
                    await updateInteractionDescription({
                        interactionId: this.currentInteractionId,
                        newDescription: description
                    });
                }
                this.counter++;
            }

            this.lastUrl = currentUrl;
        } catch (Exception) {
            console.log('Error in updating interactions in rendered callback');
        }
    }

    disconnectedCallback() {
        if (this.contextCheckTimer) {
            clearInterval(this.contextCheckTimer);
            this.contextCheckTimer = null;
        }
        window.removeEventListener('visibilitychange', this.handleVisibilityChange);

        if (this.currentInteractionId) {
            this.updateDepartureTime(this.currentInteractionId);
        }
    }

    initializeComponent() {
        if (this.positioningrole === 'Help Cue') {
            this.isInitialised = true;
            // Trigger initial cue if visible
            this.handleVisibilityCheck();
        }
    }

    handleVisibilityCheck() {
        if (this.positioningrole !== 'Help Cue') return;

        var vizCheck = this.template.querySelector('.vizCheck');
        if (this.isElementVisible(vizCheck)) {
            if (!this.helpCueIssued) {
                this.helpCueIssued = true;
                this.cueContextHelp();
            }
        } else {
            this.helpCueIssued = false;
        }
    }

    isElementVisible(element) {
        if (!element) return false;

        var rect = element.getBoundingClientRect();
        return (
            rect.top >= 0 &&
            rect.left >= 0 &&
            rect.bottom <= (window.innerHeight || document.documentElement.clientHeight) &&
            rect.right <= (window.innerWidth || document.documentElement.clientWidth)
        );
    }

    async checkContext() {
        if (this.isCheckingContext) return;
        this.isCheckingContext = true;
        try {
            var currentUrl = window.location.pathname + window.location.search;
            var newContext = this.deriveContext();
            var contextChanged = newContext !== this.lastContext;

            if (currentUrl !== this.lastUrl) {
                if (this.currentInteractionId) {
                    await this.updateDepartureTime(this.currentInteractionId);
                }

                if (contextChanged) {
                    var description = this.eventTracker?.generateSummaryDescription() + '^' + this.positioningGroup || newContext;
                    var result = await this.logLUXInteractions(19, description, newContext, null);
                    if (result) {
                        var parts = result.split('__');
                        this.currentInteractionId = parts.length > 1 ? parts[1] : null;
                    }

                    if (this.eventTracker) {
                        this.eventTracker.resetEvents();
                    }

                    this.lastContext = newContext;
                    this.counter = 0;
                } else {
                    if (this.logContextInteraction) {
                        var description = this.eventTracker?.generateSummaryDescription() + '^' + this.positioningGroup || "List View Filter Change";
                        var result = await this.logLUXInteractions(19, description, newContext, null);
                        if (result) {
                            var parts = result.split('__');
                            this.currentInteractionId = parts.length > 1 ? parts[1] : null;
                        }
                    }
                }
            } else {
                if (this.logContextInteraction && this.currentInteractionId) {
                    var description = this.eventTracker?.generateSummaryDescription() || this.lastContext;
                    await updateInteractionDescription({
                        interactionId: this.currentInteractionId,
                        newDescription: description
                    });
                }
                this.counter++;
            }

            this.lastUrl = currentUrl;
        } finally {
            this.isCheckingContext = false;
        }
    }


    async updateDepartureTime(interactionId) {
        try {
            await updateDepartureTime({ interactionId });
            console.log('Departure time updated for', interactionId);
        } catch (error) {
            console.error('Error updating departure time:', error);
        }
    }

    deriveContext() {
        if (!this.pageRef) {
            return window.location.pathname + window.location.search;
        }

        // Handle record pages
        if (this.pageRef.type === 'standard__recordPage') {
            return this.pageRef.attributes.recordId;
        }

        // Handle list views
        if (this.pageRef.type === 'standard__objectPage') {
            const objectApiName = this.pageRef.attributes.objectApiName;
            return `__LUX__${objectApiName}`;
        }

        // Handle other page types
        return window.location.pathname + window.location.search;
    }

    async cueContextHelp() {
        if (this.positioningrole !== 'Help Cue') return;

        let cmpId = this.positioningGroup;
        let helpContext = this.helpContext;

        try {
            // Check for author overrides
            var authorConfig = await getAuthorConfig({ ComponentId: cmpId });
            if (authorConfig) {
                var parts = authorConfig.split('~');
                if (parts[0] === 'HelpRecordId') {
                    helpContext = parts[1];
                }
            }
        } catch (error) {
            console.error('Error fetching author config:', error);
        }

        // Publish help cue message
        publish(this.messageContext, passthroughMessage, {
            SourceComponent: cmpId,
            ActionCode: 'CueContextHelp',
            Parameters: helpContext
        });

        // Log interaction if required
        if (this.logContextInteraction && !this.contextInteractionLogged) {
            this.contextInteractionLogged = true;
            var description = `${helpContext}`;
            this.logLUXInteractions(19, description, cxt, null);
        }
    }


    @api
    async logLUXInteractions(iTyp, description, IHContext, HTID) {
        console.log('logLUXInteractions invoked with:', {
            iTyp,
            description,
            IHContext,
            HTID
        });
        try {
            var locationTracking = this.globalSettings?.iahelp__Location_Tracking__c;
            var userLocationTrackingCheck = await isGeoEnabled();
            var enableHighAccuracy = this.globalSettings?.iahelp__Geo_EnableHighAccuracy__c;
            var geoTimeout = this.globalSettings?.iahelp__Geo_Timeout__c;

            console.log('Location Tracking setting:', locationTracking);
            console.log('User Location Tracking (Geo Enabled):', userLocationTrackingCheck);
            console.log('High Accuracy Enabled:', enableHighAccuracy);
            console.log('Geo Timeout (ms):', geoTimeout);

            let restparam = {};
            var geoCmp = this.template.querySelector('c-i-h-geolocation');

            if (locationTracking && geoCmp) {
                console.log('Getting geolocation using geoCmp...');
                var location = await geoCmp.getCurrentLocation({
                    iahelp__Geo_EnableHighAccuracy__c: enableHighAccuracy,
                    iahelp__Geo_Timeout__c: geoTimeout
                });

                var userAgent = geoCmp.getisUserAgent();
                console.log('Geolocation retrieved:', location);
                console.log('User agent:', userAgent);
                restparam = {
                    latitude: location.latitude,
                    longitude: location.longitude,
                    accuracy: location.accuracy,
                    altitude: location.altitude,
                    userAgent: userAgent,
                    contextURL: window.location.pathname + window.location.search
                };
            } else {
                console.log('Geolocation not enabled or geoCmp not found. Using fallback values.');
                var userAgent = geoCmp?.getisUserAgent?.() || 'Unknown';
                restparam = {
                    latitude: null,
                    longitude: null,
                    accuracy: null,
                    altitude: null,
                    userAgent: userAgent,
                    contextURL: window.location.pathname + window.location.search
                };
            }

            console.log('Logging with restparam:', restparam);

            var result = await logHelpInteractions({
                iTyp: +iTyp,
                Description: description,
                IHContext: IHContext,
                restInteractionParam: JSON.stringify(restparam),
                HTID: HTID
            });

            console.log('logHelpInteractions success:', result);
            return result;
        } catch (e) {
            console.error('Primary call failed. Using fallback.', e);

            var fallbackRestParam = {
                latitude: null,
                longitude: null,
                accuracy: null,
                altitude: null,
                userAgent: null,
                contextURL: window.location.pathname + window.location.search
            };

            try {
                var result = await logHelpInteractions({
                    iTyp: +iTyp,
                    Description: description,
                    IHContext: IHContext,
                    restInteractionParam: JSON.stringify(fallbackRestParam),
                    HTID: HTID
                });

                console.log('Fallback logHelpInteractions success:', result);
                return result;
            } catch (innerErr) {
                console.error('Fallback failed:', innerErr);

            }
        }
    }
    get hasLabel() {
        return !!(this.label && this.label.trim());
    }


    get computedDivId() {
        // Generate ID using properties
        return `ihPosDiv_${this.positioningGroup || 'none'}_${this.positioningrole || 'none'}`;
    }

    get textSizeStyle() {
        const sizeStyle = (() => {
            switch (this.HelpButtonTextSize?.toLowerCase()) {
                case 'medium':
                    return 'font-size: 1.2rem;';
                case 'large':
                    return 'font-size: 1.5rem;';
                case 'small':
                default:
                    return 'font-size: 0.8rem;';
            }
        })();

        // Only apply width for styles that support it
        const textStyle = this.HelpButtonTextStyle?.toLowerCase();
        const widthStyle =
            textStyle === 'ellipsis' || textStyle === 'wrap fixed width'
                ? ` width: ${this.HelpButtonTextWidth}px;`
                : '';

        return `${sizeStyle}${widthStyle}`;
    }


    get textStyleClass() {
        const style = (this.HelpButtonTextStyle || '').toLowerCase();
        console.log('Detected HelpButtonTextStyle:', style);
        switch (style) {
            case 'wrap fixed width':
                return 'ToolButtonTextWrapSetWidth';
            case 'wrap 100%':
                return 'ToolButtonTextWrap';
            case 'ellipsis':
            default:
                return 'ToolButtonTextEllipsis';
        }
    }

    get helpButtonStyleClass() {
        switch (this.HelpButtonPosition?.toLowerCase()) {
            case 'left':
                return 'ToolButtonLeft';
            case 'right':
                return 'ToolButtonRight';
            case 'above left':
                return 'ToolButtonAboveLeft';
            case 'above right':
                return 'ToolButtonAboveRight';
            case 'inline':
                return 'ToolButtonInline';
            default:
                return 'ToolButtonRight';
        }
    }

    get helpButtonContainerStyle() {
        if (this.helpButtonStyleClass === 'ToolButtonInline') {
            return `width: CALC(${this.HelpButtonTextWidth}px + 4em);`;
        }
        return '';
    }
    get bubbleContainerClass() {
        return `bubble-container ${this.helpButtonStyleClass}`;
    }
    get bubbleTextClass() {
        return `bubble-text ${this.textStyleClass}`;
    }
    get positioningClass() {
        return this.helpButtonStyleClass;
    }

    get computedColor() {

        let color = '#0070d2'; // Salesforce standard blue
        if (this.UXTheme && this.UXTheme.toLowerCase() === 'dark') {
            color = '#1b3f78'; // Dark blue
        }
        return `background-color: ${color}; border-radius: 50%;`;
    }

    get toolsContainerClass() {
        let baseClass = 'ToolsContainer';
        if (this.BackgroundStyle === 'Transparent') {
            return `${baseClass} ToolsContainerTransparent`;
        } else {
            return `${baseClass} ToolsContainerColoured`;
        }
    }

    get showHelpButton() {
        return (this.positioningrole || '').toLowerCase() === 'help button';
    }




    handleClick() {
        const message = {
            SourceComponent: this.positioningGroup,
            ActionCode: 'CueContextHelp',
            Parameters: this.helpContext
        };

        console.log('LWC: Publishing LMS message →', JSON.stringify(message));

        publish(this.messageContext, passthroughMessage, message);
        console.log('after publish', message);
    }
}