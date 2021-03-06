
function SpacesTab(id)
{
    Tab.call(this, id, Constants.FILENAME__SPACES, Constants.URL__SPACES_VIEW_MODEL);
}

SpacesTab.prototype = new Tab();

SpacesTab.prototype.constructor = SpacesTab;

SpacesTab.prototype.getInitialSort = function()
{
    return [[3, "asc"]];
};

SpacesTab.prototype.getColumns = function()
{
    return [
               {
                   "title":     Tab.prototype.formatCheckboxHeader(this.id),
                   "type":      "html",
                   "width":     "2px",
                   "orderable": false,
                   "render":    $.proxy(function(value, type, item)
                   {
                       return this.formatCheckbox(item[1], value);
                   },
                   this),
               },
               {
                   "title":  "Name",
                   "width":  "100px",
                   "render": Format.formatSpaceName
               },
               {
                   "title":  "GUID",
                   "width":  "200px",
                   "render": Format.formatString
               },
               {
                   "title":  "Target",
                   "width":  "200px",
                   "render": Format.formatTarget
               },
               {
                   "title":  "Created",
                   "width":  "180px",
                   "render": Format.formatString
               },
               {
                   "title":  "Updated",
                   "width":  "180px",
                   "render": Format.formatString
               },
               {
                   "title":  "SSH Allowed",
                   "width":  "10px",
                   "render": Format.formatBoolean
               },
               {
                   "title":     "Events",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Events Target",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Roles",
                   "width":     "90px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Default Users",
                   "width":     "90px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":  "Space Quota",
                   "width":  "90px",
                   "render": Format.formatQuotaName
               },
               {
                   "title":     "Private Service Brokers",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Security Groups",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Total",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Used",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Unused",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Instances",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Services",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Memory",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Disk",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "% CPU",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Memory",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Disk",
                   "width":     "70px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Total",
                   "width":     "80px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Started",
                   "width":     "80px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Stopped",
                   "width":     "80px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Pending",
                   "width":     "80px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Staged",
                   "width":     "80px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               },
               {
                   "title":     "Failed",
                   "width":     "80px",
                   "className": "cellRightAlign",
                   "render":    Format.formatNumber
               }
           ];
};

SpacesTab.prototype.getActions = function()
{
    return [
               {
                   text: "Rename",
                   click: $.proxy(function()
                   {
                       this.renameSingleChecked("Rename Space",
                                                "Managing Spaces",
                                                Constants.URL__SPACES);
                   },
                   this)
               },
               {
                   text: "Allow SSH",
                   click: $.proxy(function()
                   {
                       this.updateChecked("Managing Spaces",
                                          Constants.URL__SPACES,
                                          '{"allow_ssh":true}');
                   },
                   this)
               },
               {
                   text: "Disallow SSH",
                   click: $.proxy(function()
                   {
                       this.updateChecked("Managing Spaces",
                                          Constants.URL__SPACES,
                                          '{"allow_ssh":false}');
                   },
                   this)
               },
               {
                   text: "Delete",
                   click: $.proxy(function()
                   {
                       this.deleteChecked("Are you sure you want to delete the selected spaces?",
                                          "Delete",
                                          "Deleting Spaces",
                                          Constants.URL__SPACES,
                                          "");
                   },
                   this)
               },
               {
                   text: "Delete Recursive",
                   click: $.proxy(function()
                   {
                       this.deleteChecked("Are you sure you want to delete the selected spaces and their contained applications, routes, private service brokers, service instances, service bindings, service keys and route bindings?",
                                          "Delete Recursive",
                                          "Deleting Spaces and their Contents",
                                          Constants.URL__SPACES,
                                          "?recursive=true");
                   },
                   this)
               }
           ];
};

SpacesTab.prototype.clickHandler = function()
{
    this.itemClicked(-1, 2);
};

SpacesTab.prototype.showDetails = function(table, objects, row)
{
    var organization = objects.organization;
    var space        = objects.space;
    var spaceQuota   = objects.space_quota_definition;

    this.addJSONDetailsLinkRow(table, "Name", Format.formatString(space.name), objects, true);
    this.addPropertyRow(table, "GUID", Format.formatString(space.guid));

    if (organization != null)
    {
        this.addFilterRow(table, "Organization", Format.formatStringCleansed(organization.name), organization.guid, AdminUI.showOrganizations);
        this.addPropertyRow(table, "Organization GUID", Format.formatString(organization.guid));
    }

    this.addPropertyRow(table, "Created", Format.formatDateString(space.created_at));
    this.addRowIfValue(this.addPropertyRow, table, "Updated", Format.formatDateString, space.updated_at);
    this.addPropertyRow(table, "SSH Allowed", Format.formatBoolean(row[6]));
    this.addFilterRowIfValue(table, "Events", Format.formatNumber, row[7], space.guid, AdminUI.showEvents);
    this.addFilterRowIfValue(table, "Events Target", Format.formatNumber, row[8], Format.formatString(row[3]), AdminUI.showEvents);
    this.addFilterRowIfValue(table, "Roles", Format.formatNumber, row[9], space.guid, AdminUI.showSpaceRoles);
    this.addFilterRowIfValue(table, "Default Users", Format.formatNumber, row[10], Format.formatString(row[3]), AdminUI.showUsers);

    if (spaceQuota != null)
    {
        this.addFilterRow(table, "Space Quota", Format.formatStringCleansed(spaceQuota.name), spaceQuota.guid, AdminUI.showSpaceQuotas);
        this.addPropertyRow(table, "Space Quota GUID", Format.formatString(spaceQuota.guid));
    }

    this.addFilterRowIfValue(table, "Private Service Brokers", Format.formatNumber, row[12], Format.formatString(row[3]), AdminUI.showServiceBrokers);
    this.addFilterRowIfValue(table, "Security Groups", Format.formatNumber, row[13], space.guid, AdminUI.showSecurityGroupsSpaces);
    this.addFilterRowIfValue(table, "Total Routes", Format.formatNumber, row[14], Format.formatString(row[3]), AdminUI.showRoutes);
    this.addRowIfValue(this.addPropertyRow, table, "Used Routes", Format.formatNumber, row[15]);
    this.addRowIfValue(this.addPropertyRow, table, "Unused Routes", Format.formatNumber, row[16]);
    this.addFilterRowIfValue(table, "Instances Used", Format.formatNumber, row[17], Format.formatString(row[3]), AdminUI.showApplicationInstances);
    this.addFilterRowIfValue(table, "Services Used", Format.formatNumber, row[18], Format.formatString(row[3]), AdminUI.showServiceInstances);
    this.addRowIfValue(this.addPropertyRow, table, "Memory Used",     Format.formatNumber, row[19]);
    this.addRowIfValue(this.addPropertyRow, table, "Disk Used",       Format.formatNumber, row[20]);
    this.addRowIfValue(this.addPropertyRow, table, "CPU Used",        Format.formatNumber, row[21]);
    this.addRowIfValue(this.addPropertyRow, table, "Memory Reserved", Format.formatNumber, row[22]);
    this.addRowIfValue(this.addPropertyRow, table, "Disk Reserved",   Format.formatNumber, row[23]);
    this.addFilterRowIfValue(table, "Total Apps", Format.formatNumber, row[24], Format.formatString(row[3]), AdminUI.showApplications);
    this.addRowIfValue(this.addPropertyRow, table, "Started Apps", Format.formatNumber, row[25]);
    this.addRowIfValue(this.addPropertyRow, table, "Stopped Apps", Format.formatNumber, row[26]);
    this.addRowIfValue(this.addPropertyRow, table, "Pending Apps", Format.formatNumber, row[27]);
    this.addRowIfValue(this.addPropertyRow, table, "Staged Apps", Format.formatNumber, row[28]);
    this.addRowIfValue(this.addPropertyRow, table, "Failed Apps", Format.formatNumber, row[29]);
};
