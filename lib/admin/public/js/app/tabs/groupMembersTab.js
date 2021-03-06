
function GroupMembersTab(id)
{
    Tab.call(this, id, Constants.FILENAME__GROUP_MEMBERS, Constants.URL__GROUP_MEMBERS_VIEW_MODEL);
}

GroupMembersTab.prototype = new Tab();

GroupMembersTab.prototype.constructor = GroupMembersTab;

GroupMembersTab.prototype.getColumns = function()
{
    return [
               {
                   "title":  "Name",
                   "width":  "200px",
                   "render": Format.formatGroupString
               },
               {
                   "title":  "GUID",
                   "width":  "200px",
                   "render": Format.formatString
               },
               {
                   "title":  "Name",
                   "width":  "200px",
                   "render": Format.formatUserString
               },
               {
                   "title":  "GUID",
                   "width":  "200px",
                   "render": Format.formatString
               },
               {
                   "title":  "Created",
                   "width":  "180px",
                   "render": Format.formatString
               }
           ];
};

GroupMembersTab.prototype.clickHandler = function()
{
    this.itemClicked(-1, 1, 3);
};

GroupMembersTab.prototype.showDetails = function(table, objects, row)
{
    var group            = objects.group;
    var group_membership = objects.group_membership;
    var user             = objects.user_uaa;

    var groupLink = this.createFilterLink(Format.formatStringCleansed(group.displayname), group.id, AdminUI.showGroups);
    var details = document.createElement("div");
    $(details).append(groupLink);
    $(details).append(this.createJSONDetailsLink(objects));

    this.addRow(table, "Group", details, true);

    this.addPropertyRow(table, "Group GUID", Format.formatString(group.id));
    this.addFilterRow(table, "User", Format.formatStringCleansed(user.username), user.id, AdminUI.showUsers);
    this.addPropertyRow(table, "User GUID", Format.formatString(user.id));
    this.addPropertyRow(table, "Created", Format.formatDateString(group_membership.added));
};
