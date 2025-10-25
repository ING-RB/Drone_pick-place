classdef INSOptionsBase
%   This class is for internal use only. It may be removed in the future. 
%INSOPTIONBASE base class for insOptions

%   Copyright 2021 The MathWorks, Inc.    

%#codegen 

    properties
        % Datatype INS internal datatype
        % Specify the data type of the State, StateCovariance and internal
        % variables of the INS filter.
        Datatype {localMustBeTextScalar} = 'double'

        % SensorNamesSource Source for names associated with sensors
        % Specify whether the INS filter should use a default naming convention for sensors
        % or custom names given in the SensorNames property. 
        SensorNamesSource positioning.internal.SensorNamesSourceChoices = 'default' 

        % SensorNames Names of the sensors being fused
        % Specify the names of the sensors to be used by the INS filter as
        % a cell array of character vectors. The length of the SensorNames
        % must match the length of the Sensors property of the filter. Each
        % element of SensorNames must be unique. This property is only
        % active when the SensorNameSource property is set to 'property'.
        SensorNames = {''}

        % ReferenceFrame Reference frame of the INS computations 
        % Specify the reference frame for the INS computations, either
        % as 'NED' for North-East-Down or 'ENU' for East-North-Up.
        ReferenceFrame positioning.internal.ReferenceFrameChoices = 'NED'
    end

    methods (Static)
         function props = matlabCodegenNontunableProperties(~)
            props = {'ReferenceFrame', 'Datatype', 'SensorNamesSource', 'SensorNames'};
         end
    end
    
    methods
        function obj = INSOptionsBase(varargin)
            if ~isempty(varargin)
                obj = matlabshared.fusionutils.internal.setProperties(obj, ...
                    nargin, varargin{:}); 
            end
        end
        
        function obj = set.SensorNames(obj,x)
            if isstring(x)
                xc = cellstr(x);
            else
                xc = x;
            end
            coder.internal.assert(iscellstr(xc),'insframework:insEKF:expectedCellstr', 'SensorNames');
            coder.extrinsic('positioning.internal.INSOptionsBase.ensureUniqueNames');
            areUnique = coder.const(@positioning.internal.INSOptionsBase.ensureUniqueNames, x);
              coder.internal.assert(areUnique, ...
                'insframework:insEKF:NeedUniqueNames');
            obj.SensorNames = xc;
        end
        
        function obj = set.Datatype(obj,x)
            xc = char(x);
            mustBeMember(xc, {'double', 'single'});
            obj.Datatype = xc;
        end
    end
    
    methods (Static, Hidden)
        function areUnique = ensureUniqueNames(x)
            u = unique(x);
            areUnique = numel(u) == numel(x);
        end
        
        function optConst = makeConst(opt)
            % insOptions cannot be coder.const cast unless all of its
            % properties are explicitly set. This function creates a new
            % insOptions optConst that is identical to the insOptions input
            % opt, but the output can be coder.const cast. Note that
            % coder.const() should be called in the calling function.

            coder.internal.prefer_const(opt);
            optConst = insOptions;
            props = opt.matlabCodegenNontunableProperties;
            for i = 1:numel(props)
                optConst.(props{i}) = opt.(props{i});
            end
        end
    end
end

function localMustBeTextScalar(text)
% mustBeTextScalar does not support codegen : g2533276
% This is a reimplementation of mustBeTextScalar.
     isCharInput = ischar(text) && (isrow(text) || isequal(size(text),[0 0]));
     isTextScalar = isCharInput || (isstring(text) && isscalar(text));
     coder.internal.assert(isTextScalar, 'insframework:insEKF:OptsDatatype', 'Datatype');
end
