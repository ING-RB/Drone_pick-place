classdef MATFileVariable
    %MATFILEVARIABLE Used to store information about variables in a
    %MATFile.  Used by the MATFileWorkspace to cache the whos information
    %and be returned if the bytes are larger than MAX_BYTES_FOR_DISPLAY
    %then this object is returned instead.  Overwrites class and size
    %methods in order to return cached values.

     % Copyright 2023-2025 The MathWorks, Inc.

    properties (SetAccess=protected)
        Name
        WhosInfo
    end
    
    methods
        function this = MATFileVariable(name, whosInfo)
            this.Name = name;
            this.WhosInfo = whosInfo;
        end

        function c = class(this)
            c = this.WhosInfo.class;
        end

        function s = size(this, varargin)
            s = this.WhosInfo.size;
            if nargin > 1
                if isempty(s)
                    s = [0 0];
                end
                s = s(varargin{1});
            end
            if isempty(s)
                s = ["" ""];
            end

        end
    end
end

