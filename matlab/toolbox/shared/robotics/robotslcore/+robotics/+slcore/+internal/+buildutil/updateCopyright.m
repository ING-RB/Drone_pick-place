function updateCopyright(bdname, startyear)
    %This function is for internal use only. It may be removed in the future.
    
    %updateCopyright is a modifed version of slmodels_updatecopright, to
    %serve the need of RST libraries better.
    %   This function handles copyright with single year annotation better
    %   This function allows multiple annotation in single model, but the
    %   copyright annotation must be tagged with CopyrightAnnotation
    
    %   Copyright 2018 The MathWorks, Inc.
    
    % Find the annotation - which must be the only one in the root system.
    % The copyright annotation must be tagged with CopyrightAnnotation
    % To do so:
    % annotations = find_system(gcs,'SearchDepth',1,'FindAll','on','type','annotation');
    % for each annotation:
    % aObj = get_param(annotations(i), 'Object');
    % aObj.Text
    % If the text is copyright
    % aObj.Tag = 'CopyrightAnnotation'
    annotation = find_system(bdname,'SearchDepth',1,'FindAll','on', ...
    'type','annotation','tag','CopyrightAnnotation');
    assert(numel(annotation)==1,'There must be exactly one annotation in the root system with tag CopyrightAnnotation');
    
    % Get the current year.  In a service pack, this may not be the same as
    % the year in the release name (e.g. R2014aSP1 shipped in 2015).
    currentYear = datetime('now', 'format', 'yyyy').Year;
    
    % Update the text in the annotation.
    if currentYear == startyear
        txt = sprintf('Copyright %d The MathWorks, Inc.',...
            startyear);
    else
        txt = sprintf('Copyright %d-%d The MathWorks, Inc.',...
            startyear, currentYear);
    end
    set_param(bdname,'Lock','off');
    set_param(annotation,'Name',txt);
    
end

