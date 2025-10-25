classdef IgnoreWarnings < handle
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    properties
        RethrowWarning = true;
        IDsToIgnore = {};
    end
    
    properties (Access = protected)
        LastState;
        LastString
        LastIdentifier;
    end
    
    methods
        
        function this = IgnoreWarnings(varargin)
            
            % Suppress new warnings and capture the old states.
            this.LastState = warning('off');
            [this.LastString, this.LastIdentifier] = lastwarn;
            lastwarn('', '');
            
            % If passed, store all the ids the caller wants to ignore.
            % Always ignore JavaFrame warning.
            this.IDsToIgnore = [varargin {'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame'}];
        end
        
        function [str, id] = getLastWarning(this)
            [str, id] = lastwarn;
            
            ignore = this.IDsToIgnore; 
            if any(strcmp(id, ignore))
                str = '';
                id  = '';
            end
        end
        
        function clear(this)
            lastwarn('', '');
        end
        
        function throwLastWarning(this, hideStack)
            warning(this.LastState);
            if nargin > 1 && hideStack
                backtraceState = warning('off', 'backtrace');
            else
                backtraceState = [];
            end
            [newstr, newid] = lastwarn;
            
            ignore = this.IDsToIgnore; 
            
            % If there is no new warning or the new warning is one of the
            % warnings to ignore, reset the warning state that came in so
            % that the warnings are transparent.
            if isempty(newstr) || any(strcmp(newid, ignore))
                lastwarn(this.LastString, this.LastIdentifier);
            elseif this.RethrowWarning
                
                % If the new warning isn't on the ignore list and we are
                % supposed to rethrow the warning call warning again.
                warning(newid, strrep(newstr, '\', '\\'));
            end
            if ~isempty(backtraceState)
                warning(backtraceState);
            end
            warning('off');
        end
        
        function delete(this)
            throwLastWarning(this);
            warning(this.LastState);
        end
    end
end

% [EOF]
