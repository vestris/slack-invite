Fabricator(:invitation) do
  email { Faker::Internet.email }
  team { Team.first || Fabricate(:team) }
end
