import TickerSymbol from '@salesforce/schema/Account.TickerSymbol';
import { LightningElement, api, track } from 'lwc';
export default class GlobalMultiLookup extends LightningElement {
    @api label;
    @api showAddNew = false;
    @api searchData = [];
    @api backupSearchData = [];
    @api selectedData = [];
    @track localData = [];
    @api singleLookup = false;
    @api showImage = false;
    @api isRequired = false;
    selectedCount = 0;
    showOptions = false;
    showPicklist = false;
    loadOnce = false;
    @track showSelected = false;
    @api disabledmode = false;
    @api readonlymode = false;
    @api isPicklist = false;

    renderedCallback(){
        console.log("@@Rendered this.selectedData---->"  + JSON.stringify(this.selectedData));
        console.log("@@disabled mode--->"  + this.disabledmode);
        console.log('@label:'+this.label);
        if(this.disabledmode){
          
          this.template.querySelector('.custom-dropdown').classList.add('disabled');
           this.template.querySelector('.multiSelectDropdown').classList.remove('autocomplete');
       
        }

          if(this.readonlymode){
           this.template.querySelectorAll('.abcd').forEach(element => {
            element.classList.add('disabled'); //Contains HTML elements
          });
          //this.template.querySelector('.custom-dropdown').classList.add('disabled');
           this.template.querySelectorAll('.multiSelectDropdown').forEach(element => {
            element.classList.remove('autocomplete'); //Contains HTML elements
          });
          // this.template.querySelector('.multiSelectDropdown').classList.remove('autocomplete');
        }else{
             this.template.querySelectorAll('.abcd').forEach(element => {
             element.classList.remove('disabled'); //Contains HTML elements
    });
        }

        if(this.selectedData.length > 0 && !this.loadOnce){
            let dd = JSON.stringify(this.selectedData);
            this.selectedData = [];
            this.selectedData = JSON.parse(dd);
            console.log('rendered call back -> ' + this.label + '  Selected Data ' + JSON.stringify(this.selectedData));
            this.loadOnce = true;
            this.template.querySelector('label')?.classList.add('form-control-label');
            this.template.querySelector('input').placeholder = '';
            this.managePicklistValues();
        }
        if(!this.showImage){
            this.template.querySelector(".drop-value-selected")?.classList.add("hide-icon");
        }
    }

    get showSelectedValue(){
        if(this.selectedData.length > 0)
            return true;
        else
            return false;
    }

    @api validateInput(){
        if(this.isRequired && (this.selectedData.length == 0 || !this.selectedData)){
            this.template.querySelector(".throw-error")?.classList?.remove("slds-hide");
            return false;
        }
        else{
            this.template.querySelector(".throw-error")?.classList?.add("slds-hide");
            return true;
        }
        
    }

    @api resetErrorMsg(){
          this.template.querySelector(".throw-error")?.classList?.add("slds-hide");
    }

    get count(){
        if(this.selectedData.length >= 2){
            this.selectedCount = this.selectedData.length - 1;
            // this.template.querySelector('.showcount')?.classList.remove('st-hide');
            return this.selectedCount;
        }else{
            this.selectedCount = 0;
            // this.template.querySelector('.showcount')?.classList.add('st-hide');
            return this.selectedCount;
        }
    }

    get showCount(){
        if(this.selectedData?.length >= 2)
            return true;
        else
            return false;            
    }

    get showSelectedValues(){
        if(this.selectedData.length > 0){
            this.showSelected = true;
        }
        else{
            this.showSelected = false;
        }
        return this.showSelected;  
    }

    focusField(){
        this.template.querySelector('input')?.focus();
        this.template.querySelector('input').placeholder = '';
    }

    mouseUpBlock(){

    }

    openPicklist(){
        if(this.backupSearchData && this.backupSearchData.length == 0 || !this.backupSearchData){
            this.backupSearchData = this.searchData;
        }
        if(this.showAddNew)
            this.showPicklist = true;
        
        if(this.isPicklist){
            this.showPicklist = true;
            this.showOptions = true;
        }
    }

    removeLookupRecord(event){
        
        event.stopPropagation();

        let selectRecId = [];
        let selectedRecords = [];

        selectedRecords = [...this.selectedData];

        for (let i = 0; i < selectedRecords.length; i++) {
            console.log('In Submitted by remove'+event.target.dataset.id);
            if (event.target.dataset.id != selectedRecords[i].recId)
                selectRecId.push(selectedRecords[i]);
        }
        console.log('selectRecId'+JSON.stringify(selectRecId));

        this.selectedData = [...selectRecId];
        console.log('selectedData'+JSON.stringify(this.selectedData));

        if (this.selectedData.length == 0) {
            // var elm1 = this.template.querySelector(".CSTdrop");
            // elm1.classList.remove("st-show");                
        }
        if(this.selectedData.length <= 1){
            var eml = this.template.querySelector('.multiselectedDropValue');
            eml.classList.add('st-hide');
            eml.classList.remove('st-show');
        }
        this.validateInput();
        this.managePicklistValues();
    }

    removeAll(){
       
        this.selectedData = [];
        this.selectedCount = 0;
        if(this.backupSearchData.length == 0){
            this.backupSearchData = this.searchData;
        }
    }

    displayTitle(){
        this.template.querySelector('label')?.classList.add('form-control-label');
        this.template.querySelector('input').placeholder = '';        
    }

    searchLookup(event){
        const selectedEvent = new CustomEvent('search', { detail: event.target.value });
        this.dispatchEvent(selectedEvent);
        this.showOptions = true;
        this.showPicklist = true;
        console.log('searchLookUp'+JSON.stringify(this.searchData));
    }

    addNewClicked(event){
        const selectedEvent = new CustomEvent('addnew');
        this.dispatchEvent(selectedEvent);
        this.showOptions = true;
        this.showPicklist = true;
    }

    handleFocusOut(){
        window.setTimeout(() => {
            try {
                this.template.querySelector("input").value = "";
                this.showOptions = false;
                this.showPicklist = false;
                this.template.querySelector('.multiselectedDropValue').classList.remove('st-show')
            }catch(err){}
        }, 500);
    }

    opeMultiSelectPop(){
        var eml = this.template.querySelector('.multiselectedDropValue');
        //eml.classList.remove('st-hide');
        eml.classList.toggle('st-show')
    }   

    @api hideOptions(){
        this.showOptions = false;
        this.showPicklist = false;
        var eml = this.template.querySelector('.multiselectedDropValue');
        eml.classList.add('st-hide');
        eml.classList.remove('st-show');
    }

    @api setSelectedValues(data){
        this.selectedData = [];
        JSON.parse(JSON.stringify(data))?.forEach(element => {
            this.selectedData.push(element);
        });
        this.selectedData = JSON.parse(JSON.stringify(data));
        this.showSelected = true;       
        console.log('@@ setSelectedValues --> ' + JSON.stringify(this.selectedData));
    }

    @api fetchSelectedValues(){
        console.log('label' + this.label);
        console.log('fetchSelectedValues selected data -> ' + JSON.stringify(this.selectedData));
        return this.selectedData;
    }

    setSelectedSubmittedByRecord(event){
        if(this.selectedData && this.selectedData.length == 0 || !this.selectedData)
            this.selectedData = [];
        let recId = event.currentTarget.dataset.id;

        const index = this.selectedData.findIndex(elem => elem.recId == recId);

        if(index == -1)
        {
            this.searchData.forEach(element => {
                if (element.recId == recId) {
                    if(this.singleLookup)
                        this.selectedData = [];

                    this.selectedData.push(JSON.parse(JSON.stringify(element)));
                }
            });
        }
        
        if(!this.isPicklist){
            this.searchData =[];
        }
        this.managePicklistValues();
        this.template.querySelector(".throw-error").classList.add("slds-hide");
        
        this.showOptions = false;
        this.showPicklist = false;
        console.log('setSelectedSubmittedByRecord this.selectedData -> ' + JSON.stringify(this.selectedData));
        
        this.validateInput();
    }

    managePicklistValues(){
        if(this.backupSearchData && this.backupSearchData.length == 0 || !this.backupSearchData){
            this.backupSearchData = this.searchData;
        }

        if(this.isPicklist){    
            let newArray = this.backupSearchData.filter(e => {
                let idx = this.selectedData.findIndex(elem => elem.label == e.label);
                if (idx != - 1)
                    return false;
                else
                    return true;
            });

            this.searchData = newArray;
            if(this.selectedData.length == 0){
                this.searchData = this.backupSearchData;
            }
        }
    }

    @api addRecordToList(obj){
        console.log('addRecordToList --> ' + JSON.stringify(obj));
        if(this.singleLookup || this.selectedData.length == 0){
            this.selectedData = [];
        }
        obj = JSON.parse(JSON.stringify(obj));
        this.selectedData.push(obj);

        var eml = this.template.querySelector('.multiselectedDropValue');
        eml.classList.add('st-hide');
        eml.classList.remove('st-show');
    }
}