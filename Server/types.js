const whatsapp = require("whatsapp-web.js");

class WEvent {
    type;
    content;

    constructor(event_type, event_content) {
        this.type = event_type;
        this.content = event_content;
    }

    toJSON() {
        return JSON.stringify({
            "type": this.type,
            "content": this.content
        });
    }
}
