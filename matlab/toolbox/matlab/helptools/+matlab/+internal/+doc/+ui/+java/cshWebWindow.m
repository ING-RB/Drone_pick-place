function cshWebWindow(help_path, varargin)
%


%   Copyright 2020-2021 The MathWorks, Inc.

% Perform setup required before launching a help UI.
matlab.internal.doc.ui.setupForHelpUI;

options = examineInputs(varargin);

docPage = matlab.internal.doc.url.parseDocPage(help_path);
docPage.ContentType = "Standalone";
launcher = matlab.internal.doc.ui.DocPageLauncher.getLauncherForDocPage(docPage);
if ~isempty(options.size)
    launcher.Size = options.size;
end
if ~isempty(options.location)
    launcher.Location = options.location;
end        
launcher.Title = options.title;
launcher.openDocPage;

end

%--------------------------------------------------------------------------

function options = examineInputs(originalInputs)
    % Initialize defaults.
    options = struct;
    options.size = [];
    options.location = [];
    options.title = '';
    
    size = [];
    location = [];

    width = '';
    height = '';
    xloc = '';
    yloc = '';
    
    i = 1;
    while i <= length(originalInputs)  
        switch char(originalInputs{i})
            case 'size' 
                i = i + 1;
                if i <= length(originalInputs)
                    size = originalInputs{i};
                end
            case 'location' 
                i = i + 1;
                if i <= length(originalInputs)
                    location = originalInputs{i};
                end                
            case 'title' 
                i = i + 1;
                if i <= length(originalInputs)
                    options.title = char(originalInputs{i});
                end                
            case 'width' 
                i = i + 1;
                if i <= length(originalInputs)
                    width = str2num(originalInputs{i});
                end
            case 'height' 
                i = i + 1;
                if i <= length(originalInputs)
                    height = str2num(originalInputs{i});
                end
            case 'xloc' 
                i = i + 1;
                if i <= length(originalInputs)
                    xloc = str2num(originalInputs{i});
                end
            case 'yloc' 
                i = i + 1;
                if i <= length(originalInputs)
                    yloc = str2num(originalInputs{i});
                end
        end        
        i = i + 1;
    end
        
    options.size = resolveSize(size, width, height);
    options.location = resolveLocation(location, xloc, yloc);
end

%--------------------------------------------------------------------------

function resolved_size = resolveSize(size, width, height)
    resolved_size = [];
    if ~isempty(size)
        resolved_size = size;
    elseif ~isempty(width) && ~isempty(height)
        resolved_size = [width height];
    end
end

%--------------------------------------------------------------------------

function resolved_location = resolveLocation(location, xloc, yloc) 
    resolved_location = [];
    if ~isempty(location)
        resolved_location = location;
    elseif ~isempty(xloc) && ~isempty(yloc)
        resolved_location = [xloc yloc];
    end
end