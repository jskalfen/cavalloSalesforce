import { LightningElement, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getStaleAccounts from "@salesforce/apex/AccountActivityTrackerController.getStaleAccounts";

export default class AccountActivityTracker extends NavigationMixin(LightningElement) {
    @track accounts = [];
    @track selectedFilter = "30";
    @track selectedUser = "ALL";
    @track userOptions = [];
    @track isAdmin = false;
    @track totalCount = 0;
    @track isLoading = true;
    @track errorMessage = "";

    @wire(getStaleAccounts, { dayFilter: "$selectedFilter", userFilter: "$selectedUser" })
    wiredAccounts(result) {
        this.isLoading = false;
        if (result.data) {
            this.errorMessage = "";
            this.isAdmin = result.data.isAdmin;
            this.totalCount = result.data.totalCount;
            if (result.data.trackedUsers) {
                this.userOptions = result.data.trackedUsers;
            }
            this.accounts = result.data.accounts.map((acct) => ({
                ...acct,
                accountUrl: "/" + acct.accountId,
                displayDays: acct.daysSinceLastContact != null
                    ? acct.daysSinceLastContact + " days"
                    : "Never",
                daysBadgeClass: this._getBadgeClass(acct.daysSinceLastContact),
            }));
        } else if (result.error) {
            this.errorMessage = this._reduceErrors(result.error);
            this.accounts = [];
            this.totalCount = 0;
        }
    }

    get hasUserOptions() {
        return this.isAdmin && this.userOptions && this.userOptions.length > 0;
    }

    get hasAccounts() {
        return !this.isLoading && this.accounts && this.accounts.length > 0;
    }

    get showEmptyState() {
        return !this.isLoading && !this.errorMessage && (!this.accounts || this.accounts.length === 0);
    }

    get countLabel() {
        return this.totalCount === 1
            ? "1 account"
            : this.totalCount + " accounts";
    }

    get thirtyDayVariant() {
        return this.selectedFilter === "30" ? "brand" : "neutral";
    }

    get sixtyDayVariant() {
        return this.selectedFilter === "60" ? "brand" : "neutral";
    }

    get ninetyDayVariant() {
        return this.selectedFilter === "90" ? "brand" : "neutral";
    }

    get neverVariant() {
        return this.selectedFilter === "NEVER" ? "brand" : "neutral";
    }

    handleFilterChange(event) {
        const filter = event.target.dataset.filter;
        if (filter && filter !== this.selectedFilter) {
            this.isLoading = true;
            this.selectedFilter = filter;
        }
    }

    handleUserFilterChange(event) {
        const value = event.detail.value;
        if (value !== this.selectedUser) {
            this.isLoading = true;
            this.selectedUser = value;
        }
    }

    handleNavigateToRecord(event) {
        event.preventDefault();
        const recordId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: recordId,
                objectApiName: "Account",
                actionName: "view",
            },
        });
    }

    _getBadgeClass(days) {
        if (days == null || days >= 90) {
            return "badge-danger";
        } else if (days >= 60) {
            return "badge-warning";
        }
        return "badge-default";
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
