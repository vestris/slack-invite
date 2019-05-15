Fabricator(:invitation) do
  name { Faker::Name.name }
  email { Faker::Internet.email }
  team { Team.first || Fabricate(:team) }
end
