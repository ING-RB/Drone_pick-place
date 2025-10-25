function b = dotReference(t,varargin)  %#codegen
%SUBSREFDOT Subscripted reference for a table.

%   Copyright 2019-2021 The MathWorks, Inc.
 
% '.' is a reference to a table variable or property.  Any sort of
% subscripting may follow.  Row labels for cascaded () or {} subscripting on
% a variable are inherited from the table.

% This method handles RHS subscripting expressions such as
%    t.Var
%    t.Var.Field
%    t.Var{rowindices} or t.Var{rowindices,...}
%    t.Var{rownames}   or t.Var{rownames,...}
% or their dynamic var name versions, and also when there is deeper subscripting such as
%    t.Var.Field[anything else]
%    t.Var{...}[anything else]
% However, dotParenReference is called directly for RHS subscripting expressions such as
%    t.Var(rowindices) or t.Var(rowindices,...)
%    t.Var(rownames)   or t.Var(rownames,...)
% or their dynamic var name versions, and also when there is deeper subscripting such as
%    t.Var(...)[anything else]

%if ~isstruct(s), s = struct('type','.','subs',s); end

% Translate variable (column) name into an index. Avoid overhead of
% t.varDim.subs2inds in this simple case.
%varName = convertStringsToChars(varargin{1});
coder.extrinsic('matlab.internal.coder.datatypes.scanLabels');
varName = varargin{1};

coder.internal.assert(coder.internal.isConst(varName), 'MATLAB:table:NonconstantVarIndex');

if isnumeric(varName)
    % Allow t.(i) where i is an integer
    varIndex = varName;    
    coder.internal.assert(matlab.internal.datatypes.isScalarInt(varIndex,1), ...
        'MATLAB:table:IllegalVarIndex');
    coder.internal.errorIf(varIndex > t.varDim.length, 'MATLAB:table:VarIndexOutOfRange');
else
    coder.internal.assert(ischar(varName) && (isrow(varName) || isequal(varName,'')) , ...
        'MATLAB:table:IllegalVarSubscript'); % isCharString(varName)
        
    % handle .Properties first
    if strcmp(varName,'Properties')
        b = t.getProperties;
        return
    end
    
    % varIndex = find(strcmp(varName,t.varDim.labels));
    varIndex = coder.const(matlab.internal.coder.datatypes.scanLabels(varName,t.varDim.labels));
    if varIndex == 0
        % no such var        
        if strcmp(varName,t.metaDim.labels{1})
            % If it's the row dimension name, return the row labels
            varIndex = 0;
        elseif strcmp(varName,t.metaDim.labels{2})
            % If it's the vars dimension name, return t{:,:}. Deeper subscripting
            % is not supported, use explicit braces for that.
            coder.internal.assert(isscalar(varargin), ...
                'MATLAB:table:NestedSubscriptingWithDotVariables',t.metaDim.labels{2});
            varIndex = -1;
        else
            % check for .Properties, but with wrong case
            coder.internal.errorIf(strcmpi(varName,'Properties'), ...
                'MATLAB:table:UnrecognizedVarNamePropertiesCase',varName);
            
            % check property names
            coder.unroll();
            for i = 1:numel(t.propertyNames)
                if strcmpi(varName, t.propertyNames{i})
                    exactmatch = strcmp(varName, t.propertyNames{i});
                    % a valid property name
                    coder.internal.errorIf( exactmatch, ...
                       'MATLAB:table:IllegalPropertyReference',varName); 
                   % a property name, but with wrong case
                    coder.internal.errorIf( ~exactmatch, ...
                       'MATLAB:table:IllegalPropertyReferenceCase',varName,...
                       t.propertyNames{i});
                end
            end
            
            % check variable names
            coder.unroll();
            for i = 1:numel(t.varDim.labels)
                coder.internal.errorIf(strcmpi(varName,t.varDim.labels{i}), ...
                    'MATLAB:table:UnrecognizedVarNameCase',varName,t.varDim.labels{i});
            end

            % check default row dim name
            coder.internal.errorIf(strcmp(varName,t.defaultDimNames{1}), ...
                t.RowDimNameNondefaultExceptionID, varName, t.metaDim.labels{1});
            
            % check method names
            methodList = matlab.internal.coder.table.getMethodNamesList;
            for i = 1:numel(coder.const(methodList))
                % a method name
                coder.internal.errorIf(strcmpi(varName, methodList{i}), ...
                    'MATLAB:table:IllegalDotMethod',varName,...
                    methodList{i});
            end
            
            % no obvious match
            coder.internal.errorIf(varIndex == 0,'MATLAB:table:UnrecognizedVarName',varName);
        end
    end
end

if varIndex > 0
    b = t.data{varIndex};
elseif varIndex == 0
    b = t.rowDim.labels;
else % varIndex == -1
    b = t.extractData(1:t.varDim.length);
end