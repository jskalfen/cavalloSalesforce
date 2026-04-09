import { LightningElement, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getPaidInvoices from "@salesforce/apex/PaidInvoiceModalController.getPaidInvoices";
import markInvoiceChecked from "@salesforce/apex/PaidInvoiceModalController.markInvoiceChecked";

export default class PaidInvoiceModal extends NavigationMixin(LightningElement) {
    @track invoices = [];
    @track selectedFilter = "THIS_MONTH";
    @track isAdmin = false;
    @track userRoleType = "";
    @track totalCount = 0;
    @track isLoading = true;
    @track errorMessage = "";

    _wiredResult;

    @wire(getPaidInvoices, { dateFilter: "$selectedFilter" })
    wiredInvoices(result) {
        this._wiredResult = result;
        this.isLoading = false;
        if (result.data) {
            this.errorMessage = "";
            this.isAdmin = result.data.isAdmin;
            this.userRoleType = result.data.userRoleType;
            this.totalCount = result.data.totalCount;
            this.invoices = result.data.invoices.map((inv) => ({
                ...inv,
                invoiceUrl: "/" + inv.invoiceId,
                accountUrl: "/" + inv.accountId,
                isSaving: false,
            }));
        } else if (result.error) {
            this.errorMessage = this._reduceErrors(result.error);
            this.invoices = [];
            this.totalCount = 0;
        }
    }

    get hasInvoices() {
        return !this.isLoading && this.invoices && this.invoices.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.errorMessage && (!this.invoices || this.invoices.length === 0);
    }

    get showCheckboxColumn() {
        return !this.isAdmin;
    }

    get countLabel() {
        return this.totalCount === 1
            ? "1 invoice"
            : this.totalCount + " invoices";
    }

    get lastMonthVariant() {
        return this.selectedFilter === "LAST_MONTH" ? "brand" : "neutral";
    }

    get thisMonthVariant() {
        return this.selectedFilter === "THIS_MONTH" ? "brand" : "neutral";
    }

    get thisQuarterVariant() {
        return this.selectedFilter === "THIS_QUARTER" ? "brand" : "neutral";
    }

    handleFilterChange(event) {
        const filter = event.target.dataset.filter;
        if (filter && filter !== this.selectedFilter) {
            this.isLoading = true;
            this.selectedFilter = filter;
        }
    }

    handleCheckboxChange(event) {
        const invoiceId = event.target.dataset.id;
        const checked = event.target.checked;
        if (!checked) {
            return;
        }

        this.invoices = this.invoices.map((inv) =>
            inv.invoiceId === invoiceId ? { ...inv, isSaving: true } : inv
        );

        markInvoiceChecked({ invoiceId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "Invoice marked as reviewed.",
                        variant: "success",
                    })
                );
                return refreshApex(this._wiredResult);
            })
            .catch((error) => {
                this.invoices = this.invoices.map((inv) =>
                    inv.invoiceId === invoiceId ? { ...inv, isSaving: false } : inv
                );
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error",
                        message: this._reduceErrors(error),
                        variant: "error",
                    })
                );
            });
    }

    handleNavigateToRecord(event) {
        event.preventDefault();
        const recordId = event.currentTarget.dataset.id;
        const objectApiName =
            event.currentTarget.dataset.object || "chargebeeapps__CB_Invoice__c";
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName,
                actionName: "view",
            },
        });
    }

    _reduceErrors(error) {
        if (!error) return "Unknown error";
        if (typeof error === "string") return error;
        if (error.message) return error.message;
        if (error.body) {
            if (error.body.message) return error.body.message;
            if (error.body.fieldErrors) return JSON.stringify(error.body.fieldErrors);
        }
        if (Array.isArray(error)) {
            return error.map((e) => this._reduceErrors(e)).join(", ");
        }
        return JSON.stringify(error);
    }
}
