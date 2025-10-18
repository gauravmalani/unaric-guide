import { LightningElement , api } from 'lwc';

export default class IHEventTracker extends LightningElement {
   @api clickedElements = [];
   @api  scrollEvents = [];
   @api  keyEvents = [];
   @api  hoverEvents = [];
   @api  lastScrollEventTime = 0;
   @api  lastHoverEventTime = 0;
   @api evtdescription
   @api distribution
   @api summary

    connectedCallback() {
            console.log("IHEventTracker LWC connected!");
        window.addEventListener('click', this.handleClick);
        window.addEventListener('scroll', this.handleScroll);
        window.addEventListener('keydown', this.handleKeydown);
        window.addEventListener('mouseover', this.handleHover);

    }

    disconnectedCallback() {
        window.removeEventListener('click', this.handleClick);
        window.removeEventListener('scroll', this.handleScroll);
        window.removeEventListener('keydown', this.handleKeydown);
        window.removeEventListener('mouseover', this.handleHover);

        // console.log("IHEventTracker LWC disconnected!");
        let summary = this.generateSummaryDescription();
   // console.log("Summary on disconnect:", summary);
         //this.generateSummaryDescription().then(summary => {
   // console.log('Event Summary:', summary);
//}).catch(error => {
   // console.error('Error:', error);
//});

            
            // Dispatching the custom event as a standard DOM event so Aura can capture it
    // const summary = this.generateSummaryDescription();
    // const event = new CustomEvent("eventsummary", { 
    //     detail: summary, 
    //     bubbles: true, 
    //     composed: true 
    // });
    // this.dispatchEvent(event);
    }

      @api
    resetEvents() {
        this.clickedElements = [];
        this.scrollEvents = [];
        this.keyEvents = [];
        this.hoverEvents = [];
        this.lastScrollEventTime = 0;
        this.lastHoverEventTime = 0;
      //  console.log('Event tracker data reset.');
    }


    handleClick = (event) => {
        this.clickedElements = [...this.clickedElements, {
            mouseXPercentage: ((event.clientX / window.innerWidth) * 100).toFixed(2) + '%',
            mouseYPercentage: ((event.clientY / window.innerHeight) * 100).toFixed(2) + '%',
            timeStamp: new Date().toLocaleString()
        }];
    }

    handleScroll = () => {
        const now = Date.now();
        if (now - this.lastScrollEventTime >= 7000) {
            const scrollHeight = document.documentElement.scrollHeight - window.innerHeight;
            const scrollPercentage = ((window.scrollY / scrollHeight) * 100).toFixed(2);
            this.scrollEvents = [...this.scrollEvents, {
                scrollPercentage: `${scrollPercentage}%`,
                timeStamp: new Date().toLocaleString()
            }];
            this.lastScrollEventTime = now;
        }
    }

    handleKeydown = (event) => {
        this.keyEvents = [...this.keyEvents, {
            key: event.key,
            code: event.code,
            timeStamp: new Date().toLocaleString()
        }];
    }

    handleHover = (event) => {
        const now = Date.now();
        if (now - this.lastHoverEventTime >= 5000) {
            this.hoverEvents = [...this.hoverEvents, {
                mouseXPercentage: ((event.clientX / window.innerWidth) * 100).toFixed(2) + '%',
                mouseYPercentage: ((event.clientY / window.innerHeight) * 100).toFixed(2) + '%',
                timeStamp: new Date().toLocaleString()
            }];
            this.lastHoverEventTime = now;
        }
    }

 @api
generateSummaryDescription(summary) {
     //console.log('generate summary called in lwc',summary);

    // Initialize evtdescription
    let evtdescription = summary || `Page URL: ${window.location.href}\n\n`;
    evtdescription += `Total Mouse Clicks: ${this.clickedElements.length}\n`;
    evtdescription += `Total Keystrokes: ${this.keyEvents.length}\n`;
    evtdescription += `Total Mouse Hovers: ${this.hoverEvents.length}\n`;
    evtdescription += `Between ${this.getFirstEventTime()} to ${this.getLastEventTime()}\n\n`;

    // Function to calculate distribution
    const calculateDistribution = (events, type, valueKey, valueRange) => {
        if (events.length === 0) return '';
        let distribution = `${type} distribution:\n`;
        valueRange.forEach(([min, max], index) => {
            const percentage = (events.filter(e => parseFloat(e[valueKey]) > min && parseFloat(e[valueKey]) <= max).length / events.length * 100).toFixed(2);
            distribution += `${percentage}% of Time in range ${min}-${max}%\n`;
        });
       // console.log("Generated Summary distribution:\n", distribution);
        return distribution;
    };

    // Add distribution summaries to evtdescription
    evtdescription += `\n${calculateDistribution(this.clickedElements, 'Mouse Clicks', 'mouseYPercentage', [[0, 25], [25, 50], [50, 75], [75, 100]])}`;
    evtdescription += `\n${calculateDistribution(this.hoverEvents, 'Mouse Hovers', 'mouseYPercentage', [[0, 25], [25, 50], [50, 75], [75, 100]])}`;
    evtdescription += `\n${calculateDistribution(this.scrollEvents, 'Scroll', 'scrollPercentage', [[0, 0], [1, 25], [25, 50], [50, 75], [75, 100]])}`;

   // console.log("Generated Summary Description:\n", evtdescription);
   
    return evtdescription;
}


    getFirstEventTime() {
        const allEvents = [...this.clickedElements, ...this.keyEvents, ...this.hoverEvents, ...this.scrollEvents];
        return allEvents.length ? allEvents.sort((a, b) => new Date(a.timeStamp) - new Date(b.timeStamp))[0].timeStamp : 'N/A';
    }

    getLastEventTime() {
        const allEvents = [...this.clickedElements, ...this.keyEvents, ...this.hoverEvents, ...this.scrollEvents];
        return allEvents.length ? allEvents.sort((a, b) => new Date(a.timeStamp) - new Date(b.timeStamp)).slice(-1)[0].timeStamp : 'N/A';
    }
}