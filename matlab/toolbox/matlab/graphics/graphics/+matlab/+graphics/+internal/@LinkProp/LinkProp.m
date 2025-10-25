classdef LinkProp < hgsetget
%

% Copyright 2014-2024 The MathWorks, Inc.

% This class implements linkprop

    properties(Dependent)
        Enabled;
    end
    
    properties(Access = private)
        Enabled_ = 'on';
    end
    
    properties (SetAccess=private)
        PropertyNames
    end
    
    properties (Transient,Hidden)
        Listeners
    end
    
    properties (Hidden)
        LinkAutoChanges = 'on'
        PreserveLinks = 'off';
    end
    properties(SetAccess = private)
        Targets
    end
    
    properties (Transient,Hidden)
        CleanedTargets
        HasPostUpdateListeners
        SharedValues
        TargetDeletionListeners
        ValidProperties
        UpdateFcn = @localUpdateListeners
    end
    
    methods
        function set.Enabled(h,val)
            
            val = CheckOnOff( val );
            h.Enabled_ = val;
            localSetAllEnableState( h.Listeners, val );
            if strcmp( val, 'on' )
                % Call to pseudo-private method
                feval( h.UpdateFcn, h );
                % synchronize property values
                localSync(h);
            end
        end

        function val = get.Enabled(h)
            val = h.Enabled_;
        end

        
        function set.LinkAutoChanges(h,val)
            
            val = CheckOnOff( val );
            h.LinkAutoChanges = val;
        end
        
        function set.HasPostUpdateListeners(h,val)
            
            val = CheckOnOff( val );
            h.HasPostUpdateListeners = val;
        end
        
        function set.Targets(h, targets)
            h.Targets = targets;
            localUpdateListeners(h);
        end
    end
    
    methods
        function hThis = LinkProp(hlist, propnames, varargin)
            if ~isempty(varargin) && strcmp(varargin{1},'LinkAutoChanges')
                hThis.LinkAutoChanges = varargin{2};
                varargin(1:2) = [];
            end

            if ~isempty(varargin) && strcmp(varargin{1},'PreserveLinks')
                hThis.PreserveLinks = varargin{2};
            end

            % Cast first input argument into handle array
            hlist = handle( hlist );

            % Cast second input argument into cell array
            if ischar( propnames )
                propnames = { propnames };
            end
            if all( isobject( hlist ) )
                if ~all( isvalid( hlist ) )
                    throwAsCaller(MException(message('MATLAB:graphics:proplink')));
                end
            else
                if ~all( ishandle( hlist ) )
                    throwAsCaller(MException(message('MATLAB:graphics:proplink')));
                end
            end
            
            % Convert the input to 1xm vector for consistency
            if size( hlist, 1 )>1 || ~ismatrix(hlist)
                hlist = hlist(:)';
            end
            % Save state to object
            propnames = normalizePropertyNames(hlist, propnames);
            hThis.PropertyNames = propnames;
            hThis.CleanedTargets = {};
            hThis.Targets = hlist;
            % synchronize property values
            localSync(hThis);
        end
    end

    methods (Access=private)
        processPostUpdate(hLink,~,~)
        
        processUpdate(hLink,hProp,hEvent)
        
        processMarkedClean(hLink,obj,~)
        
        processReset(hLink,obj,~)
        
        processRemoveHandle(hLink,hTarget,~)
    end
end
