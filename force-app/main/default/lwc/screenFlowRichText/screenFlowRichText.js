import { LightningElement,api } from 'lwc';
export default class ScreenFlowRichText extends LightningElement {
    @api fieldValue = "";
    @api fieldLabel;
    @api required;
    @api visibleLines;
    @api recordId;
}