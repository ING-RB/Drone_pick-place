function loadconstr(Plot,SavedData)
%LOADCONSTR  Reloads saved constraint data.

%   Copyright 1986-2024 The MathWorks, Inc.

% Clear existing constraints
delete(Plot.findconstr);

% Create and initialize new constraints
for ct=1:length(SavedData)
    % Use Editor.newconstr to recreate the constraint, this creates a
    % constraint editor
    cEditor = Plot.newconstr(SavedData(ct).Type);
    % From the constraint editor construct a view
    hC = cEditor.Requirement.getView(Plot);
    hC.load(SavedData(ct).Data);
    hC.PatchColor = Plot.Options.RequirementColor;
    render(hC) %To push patch color if the requirement is already visible
    % Add to constraint list (includes rendering)
    Plot.addconstr(hC);
    % Unselect
    hC.Selected = 'off';
end


