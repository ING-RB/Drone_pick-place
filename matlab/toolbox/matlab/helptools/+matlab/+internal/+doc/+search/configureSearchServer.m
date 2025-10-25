function configureSearchServer(force)
    arguments
        force (1,1) logical = false
    end
    
    persistent knownIds
    tbxs = findCustomToolboxes;

    currentIds = string({tbxs.id});

    if force || ~isequal(knownIds, currentIds)
        if isempty(tbxs)
            matlab.internal.doc.search.sendSearchMessage('addons', 'Body', '[]');
        else
            if isscalar(tbxs)
                % Ensure that the data will be JSON encoded as an array.
                tbxs = {tbxs};
            end
            matlab.internal.doc.search.sendSearchMessage('addons', 'Body', tbxs);
        end
        knownIds = currentIds;
    end
end

function tbxInfo = findCustomToolboxes()
    tbxs = matlab.internal.doc.project.getCustomToolboxes;

    tbxInfo = struct('id', {}, 'helplocations', {}, 'urlpath', {}, 'displayname', {});
    for i = length(tbxs):-1:1
        tbx = tbxs(i);
        landingPage = string.empty;

        helpLocs = struct('helpfolder', {}, 'contenttype', {}, 'landingpage', {});
        for j = length(tbx.toolboxHelpLocations):-1:1
            helpLoc = tbx.toolboxHelpLocations(j);
            helpLocs(j) = struct('helpfolder', helpLoc.locationOnDisk, ...
                                 'contenttype', helpLoc.contentType, ...
                                 'landingpage', helpLoc.landingPage);
        end

        if isscalar(helpLocs)
            helpLocs = {{helpLocs}};
        end
        
        tbxInfo(i) = struct('id', tbx.uniqueId, ...
                            'urlpath', tbx.urlpath, ...
                            'helplocations', helpLocs, ...
                            'displayname', string(tbx.name));
    end
end
