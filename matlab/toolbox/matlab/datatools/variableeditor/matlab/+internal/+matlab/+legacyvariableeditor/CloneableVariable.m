classdef CloneableVariable < internal.matlab.legacyvariableeditor.Variable
    % CloneableVariable
    % An base class defining the methods for a Cloneable Variable
    % 

    % Copyright 2018 The MathWorks, Inc.

    % Public Abstract Methods
    methods(Access='public')
        % getCloneData
        function varargout = getCloneData(this,varargin)
            if nargout > 0
                varargout{1} = this.getData(varargin);
            end
        end

        % getCloneSize
        function size = getCloneSize(this)
            size = this.getSize();
        end
    end
end %classdef
