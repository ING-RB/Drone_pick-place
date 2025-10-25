function choices = listRepositoryStringChoices()
    allRepos = mpmListRepositories;
    choices = [allRepos.Name, allRepos.Location];
    choices(ismissing(choices)) = [];
    choices = unique(choices);
end