function choices = mpmListStringChoices()

%   Copyright 2024 The MathWorks, Inc.

    allPackages = mpmlist;
    choices = [allPackages.Name];
end
