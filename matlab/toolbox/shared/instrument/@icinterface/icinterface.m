classdef icinterface < instrument
    %ICINTERFACE Construct icinterface object.
    %
    %   ICINTERFACE constructs the parent class for interface objects.
    %   Interface objects include: serial port, GPIB, VISA, TCPIP, UDP
    %   I2C and BLUETOOTH objects.
    %
    %   Note, the GPIB, VISA, TCPIP, UDP, I2C and BLUETOOTH objects are included
    %   with the Instrument Control Toolbox.
    %
    %   An interface object is instantiated with the SERIAL, GPIB, VISA,
    %   TCPIP, UDP I2C and BLUETOOTH constructors. This constructor should not
    %   be called directly by users.
    %
    %   See also SERIAL.
    %
    
    %   Copyright 1999-2017 The MathWorks, Inc.

    properties(SetAccess = 'private', GetAccess = 'protected')
        DocIDSomeData = [];
        DocIDNoData = [];
    end
    
    methods
        function obj = icinterface(validname)
            obj = obj@instrument(validname);
            obj.store = {};
        end
    end
    
    methods (Access = 'protected')
        function obj = setDocID(varargin)
            narginchk(2,3);
            if nargin == 3
                visaType = varargin{3};
            else
                visaType = [];
            end
            obj = varargin{1};
            icinterfaceClass = varargin{2};

            % Get the doc IDs for no-data and some-data returned.
            [obj.DocIDNoData, obj.DocIDSomeData] = ...
                instrument.internal.warningMessagesHelpers.getReadWarningDocLinks(icinterfaceClass, visaType);
        end
    end
    methods (Static, Hidden)
        % The empty static method is implemented by MATLAB for all objects
        % and needs to be overloaded here for the correct behavior.
        function empty(varargin)
            throwAsCaller(MException(message('instrument:icinterface:icinterface:emptyNotValidConstructor')));
        end
    end
    
    methods (Hidden)
        % The NUMEL method is implemented by MATLAB for all objects
        % and needs to be overloaded here for the correct behavior.
        function n = numel(obj)
            n = length(obj);
        end
        
        % Implement the method numArgumentsFromSubscript to ensure that the
        % custom implementation of NUMEL doesn't break SUBSREF and SUBSASGN.
        function n = numArgumentsFromSubscript(obj, indexingSubStruct, context)
            switch context
                case {matlab.mixin.util.IndexingContext.Statement ...   % Ex: objs(1:n).prop
                      matlab.mixin.util.IndexingContext.Assignment}     % Ex: objs(1:n).prop = value
                    n = 1;
                case {matlab.mixin.util.IndexingContext.Expression}     % Ex: objA(arrayfun(@(x) ~isequal(x.Tag,''), objA)).Tag = 'newTag'
                    if isequal(indexingSubStruct(1).type,'.')
                        n = 1;
                    else
                        % perform one level of indexing, then forward result to builtin numArgumentsFromSubscript
                        x  = subsref(obj, indexingSubStruct(1));
                        n = numArgumentsFromSubscript(x,indexingSubStruct(2:end),context);
                    end
            end
        end
        
    end
    
end

