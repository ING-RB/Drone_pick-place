function helpview_args = getHelpviewArgs(classname, propname)
%

%   Copyright 2014-2020 The MathWorks, Inc.

    helpview_args = {};
    help_topic = string(classname);
    if nargin > 1
        help_topic = help_topic + "." + propname;
    end
    
    ht = matlab.internal.doc.reference.ReferenceTopic(help_topic);
    ref_data = ht.getReferenceData;
    if ~isempty(ref_data)
        helpview_args = {buildHelpPath(ref_data(1))};
    elseif nargin > 1
        mapkey = "mapkey:" + classname;
        mapping = matlab.internal.doc.csh.mapTopic(mapkey, propname);
        if mapping ~= ""
            helpview_args = {mapkey, propname, 'CSHelpWindow'};
        end
    end
end

function helpPath = buildHelpPath(ref_data)
    % A file path is acceptable as a helpview argument. The help system
    % will be able to translate this to a URL.
    helpPath = fullfile(docroot, ref_data.HelpLocation, ref_data.Href);
end
