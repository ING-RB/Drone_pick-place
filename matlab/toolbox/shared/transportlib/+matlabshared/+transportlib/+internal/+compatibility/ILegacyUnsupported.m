classdef (Abstract, Hidden) ILegacyUnsupported < handle
    %ILEGACYUNSUPPORTED Legacy methods that are unsupported by all
    %interfaces.

    % Copyright 2021 The MathWorks, Inc.

    %#codegen

    %% Unsupported Legacy Methods
    methods (Abstract, Hidden)
        % INSTRHELP
        instrhelp(obj, varargin)

        % READASYNC
        readasync(obj, varargin)

        % STOPASYNC
        stopasync(obj, varargin)

        % PROPINFO
        propinfo(obj, varargin)

        % RECORD
        record(obj, varargin)

        % INSTRID
        instrid(obj, varargin)

        % INSTRSUPPORT
        instrsupport(obj, varargin)

        % INSTRCALLBACK
        instrcallback(obj, varargin)

        % INSTRNOTIFY
        instrnotify(obj, varargin)

        % INSTRFIND
        instrfind(obj, varargin)

        % INSTRFINDALL
        instrfindall(obj, varargin)
    end

    methods
        %This dummy constructor is needed for codegen support
        function obj = ILegacyUnsupported
            coder.allowpcode('plain');
        end
    end
end