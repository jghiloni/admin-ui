require 'date'

module AdminUI
  class DevelopersTab < AdminUI::BaseTab
    def do_items
      spaces_developers = @cc.spaces_developers
      users             = @cc.users

      # spaces_developers and users have to exist.  Other record types are optional
      return result unless spaces_developers['connected'] && users['connected']

      organizations = @cc.organizations
      spaces        = @cc.spaces

      organization_hash = Hash[*organizations['items'].map { |item| [item['guid'], item] }.flatten]
      space_hash        = Hash[*spaces['items'].map { |item| [item['guid'], item] }.flatten]
      user_hash         = Hash[*users['items'].map { |item| [item['id'], item] }.flatten]

      items = []

      spaces_developers['items'].each do |space_developer|
        user = user_hash[space_developer['user_guid']]

        if user
          row = []

          row.push(user['email'])

          space = space_hash[space_developer['space_guid']]

          if space
            row.push(space['name'])

            organization = organization_hash[space['organization_guid']]

            if organization
              row.push(organization['name'])
              row.push("#{ organization['name'] }/#{ space['name'] }")
            else
              row.push(nil, nil)
            end
          else
            row.push(nil, nil, nil)
          end

          row.push(DateTime.parse(user['created']).rfc3339)

          if user['last_modified']
            row.push(DateTime.parse(user['last_modified']).rfc3339)
          else
            row.push(nil)
          end

          row.push(user)

          items.push(row)
        end
      end

      result(items, (0..5).to_a, (0..5).to_a)
    end
  end
end
