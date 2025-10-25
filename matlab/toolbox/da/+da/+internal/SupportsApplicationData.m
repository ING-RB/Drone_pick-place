classdef (Abstract) SupportsApplicationData < handle
%    Abstract interface for providing the getappdata and setappdata
%    methods to non handle graphics classes.  Previously the UDD
%    implementation would allow any type of UDD class but the HG2 class
%    does not support generic MCOS classes.  This class fills that
%    void.

%    Copyright 2019 The MathWorks, Inc.


    methods
        % This method takes a handle and the string identifying the
        % appdata.  If such a data exists, it is returned otherwise an
        % empty array is returned.
        function v = getappdata(h, name)
            arguments
            h    (1,1)
            name (1,:) char
        end
        if ~isprop(h, 'ApplicationData')
            addprop(h, 'ApplicationData');
        end
        
        
        if isfield(h.ApplicationData, name)
            v = h.ApplicationData.(name);
        else
            v = [];
        end
    end

    % This method takes an mcos handle-h, an identifier name-name and a value
    % to be stored-v.  It sets the appdata for this handle and name
    % combination so it can be queried later.
    function setappdata(h, name, v)
        arguments
        h    (1,1)
        name (1,:) char
        v
    end
    if ~isprop(h, 'ApplicationData')
        addprop(h, 'ApplicationData');
    end

    try
        if isempty(h.ApplicationData)
            % g2177841:
            % Initialize to 0 and then assign the real value to make sure
            % that you create a 1x1 struct rather than an mxn struct array.
            h.ApplicationData=struct(name, 0);
        end
        h.ApplicationData.(name) = v;
    catch e
        throw(e);
    end

end

% This function takes a handle-h and a name.  It returns a boolean
% stating whether an appdata exist for this combination of elements
function tf = isappdata(h, name)
    arguments
    h    (1,1)
    name (1,:) char
end
tf = isfield(h.ApplicationData, name);
        end
        
        
% This function takes a handle-h and a name.  It removes the object keyed
% by the string from the struct, if it exists.
function rmappdata(h, name)
    arguments
    h    (1,1)
    name (1,:) char
    end
    if isfield(h.ApplicationData, name)
        h.ApplicationData = rmfield(h.ApplicationData, name);
    end
end
        
    end
end
