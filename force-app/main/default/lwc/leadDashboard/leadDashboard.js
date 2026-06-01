import { LightningElement, track } from 'lwc';
import { loadScript }              from 'lightning/platformResourceLoader';
import CHARTJS                     from '@salesforce/resourceUrl/chartjs';

import getLeadDashboardStats from '@salesforce/apex/LeadController.getLeadDashboardStats';
import getLeads              from '@salesforce/apex/LeadController.getLeads';
import reassignLeads         from '@salesforce/apex/LeadController.reassignLeads';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID            from '@salesforce/user/Id';

const COLUMNS = [
    {
        label: 'Name', fieldName: 'nameUrl', type: 'url',
        typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' },
        sortable: true
    },
    { label: 'Company',   fieldName: 'Company',          type: 'text'    },
    { label: 'Email',     fieldName: 'Email',            type: 'email'   },
    { label: 'Status',    fieldName: 'Status',           type: 'text'    },
    {
        label: 'Score', fieldName: 'Lead_Score__c', type: 'number',
        cellAttributes: { alignment: 'center' }, sortable: true
    },
    { label: 'Category',  fieldName: 'Score_Category__c', type: 'text'  },
    { label: 'Follow Up', fieldName: 'Follow_Up_Date__c', type: 'date'  },
    { label: 'Source',    fieldName: 'LeadSource',        type: 'text'  },
    { label: 'Duplicate?',fieldName: 'Is_Duplicate__c',   type: 'boolean'},
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'View',         name: 'view'    },
            ]
        }
    }
];

// Chart colors — pie aur bar dono ke liye
const CHART_COLORS = [
    '#0176d3', '#ff5a1f', '#dd7a01', '#4bca81',
    '#9050e9', '#706e6b', '#e8384f', '#00a1e0'
];

export default class LeadDashboard extends LightningElement {

    @track stats        = {};
    @track leads        = [];
    @track isLoading    = true;
    @track selectedRows = [];

    searchTerm   = '';
    statusFilter = 'All';
    scoreFilter  = '';

    currentPage = 1;
    pageSize    = 10;
    totalCount  = 0;

    columns       = COLUMNS;
    currentUserId = USER_ID;

    // Chart instances — destroy karne ke liye save karte hain
    pieChartInstance = null;
    barChartInstance = null;

    chartJsLoaded = false;

    // ─────────────────────────────────────────
    // LIFECYCLE
    // ─────────────────────────────────────────
    connectedCallback() {
        // Pehle Chart.js load karo
        // Phir data load karo
        loadScript(this, CHARTJS)
            .then(() => {
                this.chartJsLoaded = true;
                this.loadDashboard();
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    'Chart.js load nahi hua: ' + error,
                    'error'
                );
                // Chart.js fail ho toh bhi data load karo
                this.loadDashboard();
            });
    }

    // ─────────────────────────────────────────
    // DASHBOARD LOAD
    // ─────────────────────────────────────────
    loadDashboard() {
        this.isLoading = true;
        Promise.all([
            this.loadStats(),
            this.loadLeads()
        ]).finally(() => {
            this.isLoading = false;
        });
    }

    async loadStats() {
        try {
            const result  = await getLeadDashboardStats();
            this.stats    = result;

            // Stats aane ke baad charts draw karo
            // setTimeout — DOM render hone ka wait karo
            setTimeout(() => {
                this.renderCharts();
            }, 100);

        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || 'Stats load nahi hue',
                'error'
            );
        }
    }

    async loadLeads() {
        try {
            const result = await getLeads({
                searchTerm:   this.searchTerm,
                statusFilter: this.statusFilter,
                scoreFilter:  this.scoreFilter,
                pageNumber:   this.currentPage,
                pageSize:     this.pageSize
            });

            this.leads = result.leads.map(lead => ({
                ...lead,
                nameUrl: '/' + lead.Id
            }));

            this.totalCount = result.totalCount;

        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || 'Leads load nahi hue',
                'error'
            );
        }
    }

    // ─────────────────────────────────────────
    // CHARTS RENDER
    // ─────────────────────────────────────────
    renderCharts() {
        // Chart.js load nahi hua toh skip karo
        if (!this.chartJsLoaded) return;

        // Data nahi hai toh skip karo
        if (!this.stats.bySource || !this.stats.byStatus) return;

        this.renderPieChart();
        this.renderBarChart();
    }

    renderPieChart() {
        // Purana chart destroy karo — nahi toh overlap hoga
        if (this.pieChartInstance) {
            this.pieChartInstance.destroy();
        }

        // Canvas element lo
        const canvas = this.template.querySelector('.pieChart');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        // Data prepare karo
        const labels = this.stats.bySource.map(item => item.source || 'Unknown');
        const data   = this.stats.bySource.map(item => item.total);

        // Chart banao
        // eslint-disable-next-line no-undef
        this.pieChartInstance = new Chart(ctx, {
            type: 'pie',
            data: {
                labels: labels,
                datasets: [{
                    data:            data,
                    backgroundColor: CHART_COLORS,
                    borderColor:     '#ffffff',
                    borderWidth:     2
                }]
            },
            options: {
                responsive:          true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding:   12,
                            font:      { size: 11 },
                            boxWidth:  12
                        }
                    },
                    tooltip: {
                        callbacks: {
                            // Tooltip mein percentage bhi dikhao
                            label: function(context) {
                                const total = context.dataset.data
                                    .reduce((a, b) => a + b, 0);
                                const pct = Math.round(
                                    (context.parsed / total) * 100
                                );
                                return context.label + ': ' +
                                       context.parsed + ' (' + pct + '%)';
                            }
                        }
                    }
                }
            }
        });
    }

    renderBarChart() {
        // Purana chart destroy karo
        if (this.barChartInstance) {
            this.barChartInstance.destroy();
        }

        const canvas = this.template.querySelector('.barChart');
        if (!canvas) return;

        const ctx = canvas.getContext('2d');

        // Data prepare karo
        const labels = this.stats.byStatus.map(
            item => item.status || 'Unknown'
        );
        const data   = this.stats.byStatus.map(item => item.total);

        // Chart banao
        // eslint-disable-next-line no-undef
        this.barChartInstance = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: labels,
                datasets: [{
                    label:           'Leads',
                    data:            data,
                    backgroundColor: CHART_COLORS,
                    borderColor:     CHART_COLORS,
                    borderWidth:     1,
                    borderRadius:    4
                }]
            },
            options: {
                responsive:          true,
                maintainAspectRatio: true,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                return 'Count: ' + context.parsed.y;
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            // Sirf whole numbers dikhao
                            stepSize: 1,
                            font: { size: 11 }
                        },
                        grid: {
                            color: 'rgba(0,0,0,0.06)'
                        }
                    },
                    x: {
                        ticks: {
                            font:       { size: 10 },
                            // Lamba label wrap karo
                            maxRotation: 45
                        },
                        grid: { display: false }
                    }
                }
            }
        });
    }

    // ─────────────────────────────────────────
    // FILTER HANDLERS
    // ─────────────────────────────────────────
    handleSearch(event) {
        this.searchTerm  = event.detail.value;
        this.currentPage = 1;
        this.loadLeads();
    }

    handleStatusFilter(event) {
        this.statusFilter = event.detail.value;
        this.currentPage  = 1;
        this.loadLeads();
    }

    handleScoreFilter(event) {
        this.scoreFilter = event.detail.value;
        this.currentPage = 1;
        this.loadLeads();
    }

    handleRefresh() {
        this.loadDashboard();
    }

    // ─────────────────────────────────────────
    // PAGINATION
    // ─────────────────────────────────────────
    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadLeads();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.loadLeads();
        }
    }

    // ─────────────────────────────────────────
    // ROW SELECTION
    // ─────────────────────────────────────────
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows.map(row => row.Id);
    }

    handleClearSelection() {
        this.selectedRows = [];
    }

    // ─────────────────────────────────────────
    // BULK REASSIGN
    // ─────────────────────────────────────────
    async handleReassign() {
        try {
            await reassignLeads({
                leadIds:    this.selectedRows,
                newOwnerId: this.currentUserId
            });
            this.showToast(
                'Success ✅',
                this.selectedRows.length + ' lead(s) reassigned',
                'success'
            );
            this.selectedRows = [];
            this.loadDashboard();
        } catch (error) {
            this.showToast(
                'Error',
                error.body?.message || 'Reassign fail hua',
                'error'
            );
        }
    }

    // ─────────────────────────────────────────
    // ROW ACTIONS
    // ─────────────────────────────────────────
    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row        = event.detail.row;

        if (actionName === 'view') {
            window.open('/' + row.Id, '_blank');
        }
    }

    // ─────────────────────────────────────────
    // COMPUTED PROPERTIES
    // ─────────────────────────────────────────
    get totalPages() {
        return Math.ceil(this.totalCount / this.pageSize) || 1;
    }

    get isFirstPage()    { return this.currentPage === 1;               }
    get isLastPage()     { return this.currentPage >= this.totalPages;  }
    get hasSelectedRows(){ return this.selectedRows.length > 0;         }
    get selectedCount()  { return this.selectedRows.length;             }

    get statusOptions() {
        return [
            { label: 'All',                    value: 'All'                    },
            { label: 'New',                    value: 'New'                    },
            { label: 'Working',                value: 'Working'                },
            { label: 'Nurturing',              value: 'Nurturing'              },
            { label: 'Closed - Converted',     value: 'Closed - Converted'     },
            { label: 'Closed - Not Converted', value: 'Closed - Not Converted' }
        ];
    }

    get scoreOptions() {
        return [
            { label: 'All Scores',       value: ''     },
            { label: '🔥 HOT (70+)',     value: 'HOT'  },
            { label: '🌡️ WARM (40-69)', value: 'WARM' },
            { label: '❄️ COLD (<40)',    value: 'COLD' }
        ];
    }

    // ─────────────────────────────────────────
    // TOAST HELPER
    // ─────────────────────────────────────────
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({ title, message, variant })
        );
    }
}