%#codegen
%MATLAB Code Generation Private Class

%   Copyright 2023-2024 The MathWorks, Inc.

classdef dictionary < ...
        coder.mixin.internal.indexing.Paren...
      & matlab.mixin.internal.indexing.ParenAssign ...
      & matlab.mixin.internal.indexing.Paren ...
      & coder.mixin.internal.indexing.Brace
properties(Access=private)
    kvPairs
    configured
    matlabCodegenUserReadableName
end
methods
    function this = dictionary(varargin)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
         coder.internal.assert(coder.areUnboundedVariableSizedArraysSupported, ...
                    'Coder:toolbox:dictionaryNeedsMalloc', 'IfNotConst', 'Fail');  
        %assume keys, values for now
        if nargin == 0
            this.configured = coder.ignoreConst(false);
            this.matlabCodegenUserReadableName = 'dictionary';
            return;
        end
        this.configured = coder.ignoreConst(true);
        this = buildKVPairs(this, varargin{:});
        this.matlabCodegenUserReadableName =  ['dictionary ',...
            class(this.kvPairs.getExampleKey), ' -> ',...
            class(this.kvPairs.getExampleValue)];

    end
    %write/delete
    function this = parenAssign(this, values, keys)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        coder.internal.cfunctionname('write');
        if coder.internal.isConstTrue(isempty(values)) && isa(values, 'double') %Note: Needs to be [] exactly for deletion. How to differentiate between [] and double.empty()?
            this = this.parenDelete(keys);
            return
        end

        this = this.insert(keys, values);
    end

    function this = insert(varargin)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        coder.internal.errorIf(coder.internal.isInParallelRegion, 'Coder:toolbox:dictionaryParfor');
        this = insertForceConfigured(varargin{1}, false, varargin{2:end}); %does moving the argument parsing matter?
    end
    function out = parenReference(this, keys)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        coder.internal.cfunctionname('read');
        coder.internal.assert(this.isConfigured, 'MATLAB:dictionary:UnconfiguredLookupNotSupported');
        coder.assumeDefined(this.kvPairs);
        out = lookup(this, keys);
    end

    function out = lookup(this, rawKeys, varargin)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        coder.internal.assert(this.isConfigured, 'MATLAB:dictionary:UnconfiguredLookupNotSupported');
        coder.assumeDefined(this.kvPairs);
        if ~coder.target('MATLAB') && coder.internal.prop_has_class(this, 'kvPairs')
            egKeyC = coder.internal.homogeneousCellBase(this.kvPairs.keys);
            if ~isOfType(rawKeys, egKeyC)
                keys = castToEg(rawKeys, egKeyC, 'Lookup');
            else
                keys = rawKeys;
            end
        else
            keys = rawKeys;
        end


        outSz = size(keys);


        coder.internal.errorIf(...
            canNotBeArray(this.kvPairs.getExampleValue) && prod(outSz) ~= 1,... 
            'Coder:toolbox:dictionaryStringArrayLookup');


        if iscell(this.kvPairs.getExampleValue)
            out = coder.nullcopy(cell(outSz));
        elseif isstring(this.kvPairs.getExampleValue)
            out = coder.nullcopy(string(blanks(coder.internal.ignoreRange(1))));
        else
            if coder.internal.isConstTrue(prod(outSz)==1)
                out = coder.nullcopy(this.kvPairs.getExampleValue); %after g3359991 this branch can be removed
                %NOTE: this nullcopy puts objects in a "bad" state and
                %paren assign might not completely assign them, do not use
                %paren assign below. after g2279374 we might change this?
            else
                out = coder.nullcopy(eml_expand(this.kvPairs.getExampleValue, outSz));
            end
        end

        isscalarLookup = isscalar(keys);
        if ischar(keys)
            for jdx = 1:prod(outSz(2:end), 'all')
                for idx = 1:outSz(1)
                    if iscell(out)
                        tmp = this.lookupScalarKey(string(keys(idx, :, jdx)),...
                            isscalarLookup, idx,...
                            varargin{:});
                        out{idx, jdx} = tmp{1};
                    else
                        if canNotBeArray(out)
                            out = this.lookupScalarKey(string(keys(idx, :, jdx)),...
                                isscalarLookup, idx,...
                                varargin{:});
                        else
                            out(idx, jdx) = this.lookupScalarKey(string(keys(idx, :, jdx)),...
                                isscalarLookup, idx,...
                                varargin{:});
                        end
                    end
                end
            end
        elseif iscell(keys) %do we need one for structs too?
            for idx=1:numel(keys)
                if iscell(out)
                    tmp = this.lookupScalarKey({keys{idx}},...
                        isscalarLookup, idx,...
                        varargin{:});
                    out{idx} = tmp{1};
                else
                    if canNotBeArray(out)
                        out = this.lookupScalarKey({keys{idx}},...
                            isscalarLookup, idx,...
                            varargin{:});
                    else
                        out(idx) = this.lookupScalarKey({keys{idx}},...
                            isscalarLookup, idx,...
                            varargin{:});
                    end
                end
            end
        else
            for idx=1:numel(keys)
                if iscell(out)
                    tmp = this.lookupScalarKey(enumSafeFull(keys(idx)),...
                        isscalarLookup, idx,...
                        varargin{:});
                    out{idx} = tmp{1};
                else
                    if canNotBeArray(out)
                        out = this.lookupScalarKey(enumSafeFull(keys(idx)),...
                            isscalarLookup, idx,...
                            varargin{:});
                    else
                        out(idx) = this.lookupScalarKey(enumSafeFull(keys(idx)),...
                            isscalarLookup, idx,...
                            varargin{:});
                    end
                end
            end
        end
    end

    function this = remove(this, keys)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        this = this.parenDelete(keys);
    end

    function this = parenDelete(this, rawKeys)
        %FIXME: bad casts
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        coder.internal.cfunctionname('delete');
        this.assertIsConfigured('MATLAB:dictionary:UnconfiguredRemovalNotSupported');
        coder.internal.errorIf(coder.internal.isInParallelRegion, 'Coder:toolbox:dictionaryParfor');
        coder.assumeDefined(this.kvPairs);
        if ~this.isConfigured
            return;
        end
        coder.assumeDefined(this.kvPairs);


        if ~coder.target('MATLAB') && coder.internal.prop_has_class(this, 'kvPairs')
            egKeyC = coder.internal.homogeneousCellBase(this.kvPairs.keys);
            if ~isOfType(rawKeys, egKeyC)
                keys = castToEg(rawKeys, egKeyC, 'Remove');
            else
                keys = rawKeys;
            end
        else
            keys = rawKeys;
        end


        if iscell(keys)
            for idx = 1:numel(keys)
                this = this.deleteScalarKey({keys{idx}});
            end
        else
            for idx = 1:numel(keys)
                this = this.deleteScalarKey(enumSafeFull(keys(idx)));
            end
        end
    end
    function out = entries(this, format)
        this.assertIsConfigured('Coder:toolbox:dictionaryUnconfiguredEntries');
        coder.assumeDefined(this.kvPairs);
        if nargin == 1
            finalFormat = 'table';
        else
            coder.internal.prefer_const(format);
            coder.internal.assert(coder.internal.isConst(format), 'Coder:toolbox:dictionaryConstFormat');
            f = coder.internal.parseConstantFlags({'table', 'cell', 'struct'}, format);
            if f.table
                finalFormat = 'table';
            elseif f.cell
                finalFormat = 'cell';
            elseif f.struct
                finalFormat = 'struct';
            else
                coder.internal.assert(false, 'Coder:toolbox:dictionaryEntriesFormat');
            end
        end


        switch finalFormat
            case 'table'
                coder.internal.errorIf(...
                    isobject(this.kvPairs.getExampleKey) || isobject(this.kvPairs.getExampleValue), 'Coder:toolbox:dictionaryTableEntries');
                %table not possible for strings (and probably also other objects)
                coder.internal.errorIf(this.kvPairs.getNumel == 0, 'Coder:toolbox:dictionaryTableEmpty')
                k = cell2table(this.keys('cell'), 'VariableNames', {'Key'});
                v = cell2table(this.values('cell'), 'VariableNames', {'Value'});
                out = [k,v];
                
            case 'cell'
                out = coder.internal.infer_or_error(makeCellEntries(this),...
                    'Coder:toolbox:dictionaryCellEntries');
            case 'struct'
                exKey = {this.kvPairs.getExampleKey};
                exVal = {this.kvPairs.getExampleValue};
                eg = struct('Key', exKey, 'Value', exVal);
                out = coder.nullcopy(eml_expand(eg, [this.kvPairs.getNumel,1]));
                k = this.keys('cell');
                v = this.values('cell');
                for i = 1:this.kvPairs.getNumel
                    out(i) = struct('Key', {k{i}}, 'Value', {v{i}});
                end
            otherwise
                coder.internal.assert(false, 'Coder:toolbox:dictionaryEntriesFormat');
        end

    end
    function out = keys(this, giveCell)
        this.assertIsConfigured('Coder:toolbox:dictionaryUnconfiguredKeys');
        coder.assumeDefined(this.kvPairs);
        coder.internal.assert(~canNotBeArray(this.kvPairs.getExampleKey) || (nargin==2 && coder.internal.isConst(giveCell)), 'Coder:toolbox:dictionaryKeysArg', class(this.kvPairs.getExampleValue));
        if nargin == 2
            f = coder.internal.parseConstantFlags({'cell'}, giveCell);
            coder.internal.assert(f.cell, 'Coder:toolbox:dictionaryKeysArgCell');
            out = this.kvPairs.getKeys;
        else
            out = [this.kvPairs.getKeys{:}].';
        end
    end
    function out = values(this, giveCell)
        %FIXME: update errors to note when cell is required
        this.assertIsConfigured('Coder:toolbox:dictionaryUnconfiguredValues');
        coder.assumeDefined(this.kvPairs);
        coder.internal.assert(~canNotBeArray(this.kvPairs.getExampleValue) || (nargin==2 && coder.internal.isConst(giveCell)), 'Coder:toolbox:dictionaryValuesArg', class(this.kvPairs.getExampleValue));
        if nargin == 2
            f = coder.internal.parseConstantFlags({'cell'}, giveCell);
            coder.internal.assert(f.cell, 'Coder:toolbox:dictionaryValuesArg');
            out = this.kvPairs.getValues;
        else
            out = [this.kvPairs.getValues{:}].';
        end
    end
    function [keyType, valueType] = types(this)
        this.assertIsConfigured('Coder:toolbox:dictionaryUnconfiguredTypes');
        coder.assumeDefined(this.kvPairs);
        keyType = string(class(this.kvPairs.getExampleKey));
        valueType = string(class(this.kvPairs.getExampleValue));
    end
    function n = numEntries(this)
        if ~this.isConfigured
            n = 0;
            return;
        end
        coder.assumeDefined(this.kvPairs);
        n = double(this.kvPairs.getNumel);
    end
    function out = isConfigured(this)
        if coder.target("MATLAB")
            out = this.configured;
        else
            out = coder.internal.prop_has_class(this, 'kvPairs') && this.configured;
        end
    end
    function out = isKey(this,rawKeys)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        this.assertIsConfigured('MATLAB:dictionary:UnconfiguredLookupNotSupported');
        coder.internal.errorIf(ischar(rawKeys) && ~isrow(rawKeys), 'Coder:toolbox:dictionaryCharRowIsKey');

        if ~coder.target('MATLAB') && coder.internal.prop_has_class(this, 'kvPairs')
            egKeyC = coder.internal.homogeneousCellBase(this.kvPairs.keys);
            if ~isOfType(rawKeys, egKeyC)
                key = castToEg(rawKeys, egKeyC, 'Lookup');
            else
                key = rawKeys;
            end
        else
            key = rawKeys;
        end



        szOut = size(key);
        % if ~this.isConfigured
        %     out = false(szOut);
        %     return;
        % end
        coder.assumeDefined(this.kvPairs);
        if ischar(key)
            out = this.kvPairs.hasKey(string(key));
        else
            out = coder.nullcopy(false(szOut));
            if iscell(key)
                coder.unroll(~coder.internal.isHomogeneousCell(key))
                for i=1:numel(key)
                    out(i) = this.kvPairs.hasKey({key{i}});
                end
            else
                for i=1:numel(key)
                    out(i) = this.kvPairs.hasKey(enumSafeFull(key(i)));
                end
            end

        end
    end
    function disp(this)
        % coder.internal.assert(this.configured, 'Coder:builtins:Explicit', 'TEMP MESSAGE: can not index into unconfigured dictionary');
        % if ~this.isConfigured
        %     disp('unconfigured dictionary');
        %     return;
        % end
        % disp('this is a coder.internal.dictionary')
        % disp(this.kvPairs);

        if ~this.isConfigured
            feval('coder.internal.dispUnconfigured');
        else
            coder.assumeDefined(this.kvPairs);
            feval('disp', this);
        end
    end
    function varargout = isequal(varargin)
        %in matlab, this does not require that the dictionaries have the
        %same insertion order. I am not sure what else can be different
        coder.internal.assert(false, 'Coder:toolbox:dictionaryEQ');
        [varargout{1:nargout}] = deal([]);
    end
    function varargout = isequaln(varargin)
        coder.internal.assert(false, 'Coder:toolbox:dictionaryEQN');
        [varargout{1:nargout}] = deal([]);
    end
    function n = numel(~)
        n = 1;
    end
    function varargout = size(this, varargin)
        %necessary for d.size
        [varargout{:}] = builtin('size', this, varargin{:});
    end
    function N = ndims(~)
        N = 2;
    end
    function varargout = braceReference(varargin)
            coder.internal.assert(false, 'Coder:toolbox:dictionaryNoCurly');
            [varargout{1:nargout}] = deal([]);
    end
    function varargout = braceAssign(varargin)
        coder.internal.assert(false, 'Coder:toolbox:dictionaryNoCurly');
        [varargout{1:nargout}] = deal([]);
    end
    function varargout = braceListReference(varargin)
        coder.internal.assert(false, 'Coder:toolbox:dictionaryNoCurly');
        [varargout{1:nargout}] = deal([]);
    end
    function varargout = braceListAssign(varargin)
        coder.internal.assert(false, 'Coder:toolbox:dictionaryNoCurly');
        [varargout{1:nargout}] = deal([]);
    end
end

methods (Access = public, Static = true, Hidden = true)
    function t = matlabCodegenTypeof(~)
        t = 'coder.type.Dictionary';
    end
    function this = fromBasicDictionary(bd)
        this = coder.internal.dictionary();
        this.kvPairs = bd;
        this.configured = true;
    end
    function this = matlabCodegenToRedirected(d)
        % Given MATLAB dictionary, d, return coder.internal.dictionary, this.
        coder.internal.assert(isConfigured(d), 'Coder:toolbox:dictionaryUnconfiguredRedirect');
        [keyType, valType] = d.types;
        if d.numEntries > 1 &&...
                strcmp(keyType, 'cell') || strcmp(valType, 'cell') ||...
                strcmp(keyType, 'struct') || strcmp(valType, 'struct')
            %this doesn't work well for empties, but is necessary to avoid
            %passing nonscalar structs and cells
            args = [reshape(d.keys('cell'), 1, []); reshape(d.values('cell'), 1, [])];
            this = coder.internal.dictionary(args{:});
        else
            this = coder.internal.dictionary(d.keys, d.values);
        end
    end
    function d = matlabCodegenFromRedirected(this)
        % Given coder.internal.dictionary, this, return MATLAB dictionary, d.

        if this.configured && ~isempty(this.kvPairs.getExampleKey)
            %if the dictionary is configured, but never saw an actual kv
            %pair, we dont have an example to marshall out, so by the time
            %we get to matlab the type is lost. Return unconfigured (which
            %can still be used as configured), instead of returning the
            %wrong type or giving an unpredictable error message.
            if this.kvPairs.getNumel == 0
                k = repmat(this.kvPairs.getExampleKey, [0,0]);
                v = repmat(this.kvPairs.getExampleValue, [0,0]);
                d = dictionary(k,v);
            else
                %d = dictionary([this.kvPairs.getKeys{:}], [this.kvPairs.getValues{:}]);
                args = [this.kvPairs.getKeys.'; this.kvPairs.getValues.'];
                d = dictionary(args{:});
            end
        else
            d = dictionary();
        end
    end
    function out = matlabCodegenNontunableProperties(~)
        out = {'matlabCodegenUserReadableName'};
    end
end
methods(Static, Access = private, Hidden = true)
        function result = matlabCodegenDispatcherName
            result = 'dictionary';
        end
end
methods(Access = private)
    function out = makeCellEntries(this)
        %this function exists to have something to give to infer or error
        out = [this.keys('cell'), this.values('cell')]; %only works for homogeneous keys/values
    end

    function out = lookupScalarKey(this, key, isscalarLookup, idx, opts)
        arguments
            this
            key
            isscalarLookup
            idx
            opts.FallbackValue
        end
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        coder.internal.prefer_const(isscalarLookup);
        [valueOrExample, hasValue] = this.kvPairs.read(key);

        if isscalarLookup
            coder.internal.assert(hasValue || isfield(opts, 'FallbackValue'),...
                'MATLAB:dictionary:ScalarKeyNotFound');
        else
             coder.internal.assert(hasValue || isfield(opts, 'FallbackValue'),...
                'MATLAB:dictionary:KeyNotFound', idx);
        end
        if ~hasValue && isfield(opts, 'FallbackValue')
            outTmp = castToEg(opts.FallbackValue, this.kvPairs.getExampleValue, 'Lookup');
            if ischar(outTmp) && isstring(this.kvPairs.getExampleValue)
                out = string(outTmp(1:coder.internal.ignoreRange(numel(outTmp)))); %cast to EG doesn't do this to avoid string arrays, but we need it here
            else
                out = outTmp;
            end
        elseif hasValue
            out = valueOrExample;
        else %impossible with asserts on
            out = buildDefaultValue(valueOrExample);
        end
    end

    function this = deleteScalarKey(this, key)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        this.kvPairs = this.kvPairs.delete(key);
    end

    function this = insertScalarKey(this, key, value, overwrite)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        coder.internal.prefer_const(overwrite);
        if overwrite || ~this.isKey(key)
            this.kvPairs = this.kvPairs.write(key, value);
        end
    end

    function assertIsConfigured(this, varargin)
        coder.inline('always');
        coder.internal.prefer_const(varargin)
        coder.internal.assert(this.isConfigured, varargin{:});
        coder.assumeDefined(this.kvPairs);
    end

    function this = insertForceConfigured(this, forceConfigured, rawKeys, rawValues, opts)
        arguments
            this
            forceConfigured
            rawKeys
            rawValues
            opts.Overwrite (1,1) logical = true
        end
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        %possible enhancement:dedupe keys??
        coder.const(forceConfigured);
        if ~coder.target('MATLAB') && coder.internal.prop_has_class(this, 'kvPairs')
            egKeyC = coder.internal.homogeneousCellBase(this.kvPairs.keys);
            if ~isOfType(rawKeys, egKeyC)
                keys = castToEg(rawKeys, egKeyC, 'Insert');
            else
                keys = rawKeys;
            end
        else
            keys = rawKeys;
        end
        if ~coder.target('MATLAB') && coder.internal.prop_has_class(this, 'kvPairs')
            egValC = coder.internal.homogeneousCellBase(this.kvPairs.values);
            if coder.const(~isOfType(rawValues, egValC))
                values = castToEg(rawValues, egValC, 'Insert');
            else
                values = rawValues;
            end
        else
            values = rawValues;
        end


        if ~this.configured && ~forceConfigured
            this.configured = coder.ignoreConst(true);
            this = buildKVPairs(this, keys, values);
            %this.matlabCodegenUserReadableName = buildUserName(class(this.kvPairs.getExampleKey), class(this.kvPairs.getExampleValue));
        end

        coder.assumeDefined(this.kvPairs);


        if isscalar(values) || (ischar(values) && isrow(values)) %require const row??
            scalarValue = idOrToString(values);
            if iscell(scalarValue)
                trueScalar = {scalarValue{1}};
            elseif canNotBeArray(scalarValue)
                trueScalar = scalarValue;
            else
                trueScalar = scalarValue(1);
            end
            k = cellify(keys);
            for idx = 1:numel(k)
                this = this.insertScalarKey(k{idx}, trueScalar, opts.Overwrite);
            end
        else
            [k, keysSz] = cellify(keys);
            [v, valuesSz] = cellify(values);
            if coder.internal.isConst(size(v)) && coder.internal.isConst(size(k))...
                    && coder.internal.isConstTrue(coder.internal.ndims(v)==2)...
                    && coder.internal.isConstTrue(coder.internal.ndims(k)==2)
                coder.internal.assert(isscalar(v) || numel(k)==numel(v),...
                    'Coder:toolbox:KeyValueDimsMustMatch',...
                    size(k,1), size(k,2), size(v,1), size(v,2));
            else
                coder.internal.assert(isscalar(v) || numel(k)==numel(v), 'MATLAB:dictionary:KeyValueDimsMustMatch');
            end
            coder.internal.assert(...
                (ndims(k) == ndims(v) && all(size(k)==size(v))) ||...
                ((isvector(k)||isvector(v)) && numel(k)==numel(v) && numel(k)~=0),...
                'MATLAB:dictionary:KeyValueDimsMustMatch');%this is too permissive?
            if isempty(k) || isempty(v)
                % This is an unrequired NO-OP to avoid coder errors on
                % v{idx} in the following loop.
                return
            end
            if keysSz == valuesSz
                for idx = 1:numel(k)
                    this = this.insertScalarKey(k{idx}, v{idx}, opts.Overwrite);
                end
            else

            end
        end
    end
    function this = buildKVPairs(this, varargin)
        coder.internal.allowEnumInputs;
        coder.internal.allowHalfInputs;
        [this.kvPairs, keys, values, nPairs] = buildEmptyKVPairs(varargin{:});
        coder.unroll()
        for i = 1:nPairs
            this = this.insertForceConfigured(true, keys{i}, values{i}); %this is not great for error messages, but i think matlab has the same problems
        end
    end
end


end

function out = idOrToString(in)
coder.inline('always')
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
if ischar(in) || isstring(in)
    out = string(in);
else
    out = enumSafeFull(in);
end
end

function sz = getTextScalarSize(charSz)
    if numel(charSz) == 2
        sz = coder.internal.indexInt([charSz(1) 1]);
    else
        % Ideally we would write outSz = charSz([1 3:end])
        % however that doesn't preserve constness of the elements,
        % see g2307911.
        sz = coder.internal.indexInt(zeros(1, numel(charSz) - 1));
        sz(1) = charSz(1);
        coder.unroll();
        for idx = 3:numel(charSz)
            sz(idx - 1) = charSz(idx);
        end
    end
end

function [out, outSz] = makeCellOfStrings(charArray)
    outSz = getTextScalarSize(size(charArray));
    ndSz = [outSz(1) prod(outSz(2:end))];
    out = coder.nullcopy(repmat({string(blanks(coder.internal.ignoreRange(1)))}, [1, prod(ndSz)]));
    for idx = 1:numel(out)
        [jdx,kdx] = ind2sub(ndSz,idx);
        out{idx} = string(charArray(jdx, :, kdx));
    end
end

function elem = getFirstElement(item)
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
    if isempty(item)
        elem = item;
        return
    end
    if ischar(item)
        charSz = size(item);
        if numel(charSz) == 2
            elem = item(1,:);
        else
            elem = item(1,:,ones(1,numel(charSz)-2));
        end
    elseif iscell(item)
        elem = {item{1}};
    elseif canNotBeArray(item)
        elem = item;
    else
        elem = item(1);
    end
end

function [out, outSz] = cellify(items)
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
if ischar(items)
    % out is a flattened cell array of strings [1 N]
    % outSz is size(A, [1 3:end])
    [out, outSz] = makeCellOfStrings(items);
elseif ~coder.target('MATLAB') && canNotBeArray(items) && ~isstring(items)
    %there are no arrays of objects (yet), and num2cell does not behave
    %when given scalar objects that support parenReference
    out = {items};
    outSz = [1,1];
else
    out = num2cell(enumSafeFull(items)); %this full might inflate too much if someone passes the wrong input by mistake
    outSz = size(items);
end
end

function in = buildDefaultValue(in)
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
if isenum(in)
    [eg, ~] = enumeration(class(in));
    in = repmat(eg(1), size(in));
elseif isnumeric(in)
    in = zeros(size(in), 'like', in);
elseif isstring(in)
    in  = "";
elseif islogical(in)
    in = false(size(in));
elseif iscell(in)
    for i = 1:numel(in)
        in{i} = buildDefaultValue(in{i});
    end
elseif isstruct(in)
    f = fieldnames(in);
    for j = 1:numel(in)
        for i=1:numel(f)
            in(j).(f{i}) = buildDefaultValue(in(j).(f{i}));
        end
    end
end
%to consider: could add more types? is there a helper elsewhere for this?
end

function out = castToEg(in,eg, funcName)
coder.const(funcName);


fullIn = enumSafeFull(in); %keys and values are always full


egClass = class(eg);
if isstring(eg) && ~isstring(in)
    out = coder.internal.infer_or_error(string(in),...
        ['Coder:toolbox:dictionaryStringArrayCast', funcName], class(in));
    %out = string(in); %this will error on many inputs - should we throw a better error?
    return;
end

if isa(fullIn, egClass)
    outC = fullIn;
else
    %check target
    coder.internal.assert(isCoercibleClass(egClass), ['Coder:toolbox:dictionaryCastFailed', funcName], class(in), egClass);
    %check source
    coder.internal.assert(...
        ~(iscell(in) || isstruct(in)) || (isobject(in) && ~isstring(in)),...
        ['Coder:toolbox:dictionaryCastFailed', funcName], class(in), egClass)
    caster = str2func(egClass);
    outC = caster(fullIn);
end

if ~isnumeric(eg) || isreal(eg) == isreal(outC) %no conversion necessary
    out = outC;
elseif ~isreal(eg) %cast to complex
    out= complex(outC);
else %cast to real
   coder.internal.assert(isstring(in) || ischar(in) || isreal(outC), ['Coder:toolbox:dictionaryComplex', funcName]) ;
   coder.internal.errorIf((isstring(in) || ischar(in))&& imag(outC)~=0, ['Coder:toolbox:dictionaryComplex', funcName]);
   out = real(outC);
end

end

function good = isCoercibleClass(c)
coder.internal.prefer_const(c);
switch c
    case {'string','char', 'double', 'single', 'half', 'logical',...
            'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'}
        good = true;
    otherwise
        good = false;
end
end

function match = isOfType(in, eg)


match = isa(in, class(eg));
if isnumeric(eg)
    match = match && isreal(in)==isreal(eg);
end
if ~isobject(eg)
    match = match && issparse(in)==issparse(eg);
end


end

function out = isHashableType(eg)
out = ~isfi(eg) && isnumeric(eg) || ischar(eg) || ...
    islogical(eg) || isstruct(eg) || ...
    iscell(eg) || isenum(eg) || isstring(eg);
if iscell(eg)
    for i=1:numel(eg)
        out = out && isHashableType(eg{i});
    end
elseif isstruct(eg)
    f = fieldnames(eg);
    for j=1:numel(eg)
        for i=1:numel(f)
            out = out && isHashableType(eg(j).(f{i}));
        end
    end
end
end

function out = isBuiltinNumeric(in)
coder.inline('always')

out = ~issparse(in) && ~isenum(in) && isa(in, 'double') || isa(in, 'single')...
    || isa(in, 'int8') || isa(in, 'uint8') || isa(in, 'int16') || isa(in, 'uint16')...
    || isa(in, 'int32') || isa(in, 'uint32') || isa(in, 'int64') || isa(in, 'uint64');

end

function [kvPairs, keys, values, nPairs] = buildEmptyKVPairs(varargin)
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
coder.internal.assert(nargin>1, 'MATLAB:dictionary:IncorrectNumberOfInputs');
coder.internal.assert(mod(nargin, 2)==0, 'MATLAB:dictionary:IncorrectNumberOfInputs');
nPairs = nargin/2;
hetKeys = coder.nullcopy(cell(1, nPairs));
hetValues = coder.nullcopy(cell(1, nPairs));
keyHasCell = false;
valueHasCell = false;
allKeysComplexable = true;
allValuesComplexable = true;
hasComplexKey = false;
hasComplexValue = false;

coder.unroll()
for i=1:nPairs
    %validate key
    kIdx = i*2 -1;
    coder.internal.assert(isHashableType(varargin{kIdx}), 'Coder:toolbox:dictionaryBadKeytype')
    coder.internal.errorIf(ischar(varargin{kIdx}) && ~isrow(varargin{kIdx}), 'Coder:toolbox:dictionaryCharRow')
    coder.internal.errorIf((iscell(varargin{kIdx}) || isstruct(varargin{kIdx}))...
        && ~coder.internal.isConstTrue(isscalar(varargin{kIdx})),...
        'Coder:toolbox:dictionaryAggregateNonscalar', class(varargin{kIdx}));
    coder.internal.errorIf(...
        iscell(varargin{kIdx}) && coder.internal.isConstTrue(isempty(varargin{kIdx})),...
        'Coder:toolbox:dictionaryEmptyCell');

    hetKeys{i} = idOrToString(varargin{kIdx}); %idOrToString doesn't do the right thing for char arrays?

    %validate value
    vIdx = i*2;
    coder.internal.errorIf(ischar(varargin{vIdx}) && ~isrow(varargin{vIdx}), 'Coder:toolbox:dictionaryCharRow')
    coder.internal.assert(~isa(varargin{vIdx}, 'function_handle'), 'Coder:toolbox:dictionaryFunctionHandle')
    coder.internal.assert(~isa(varargin{vIdx}, 'categorical'), 'Coder:toolbox:dictionaryCategorical')
    coder.internal.errorIf(...
        (iscell(varargin{vIdx}) || isstruct(varargin{vIdx})) && ~coder.internal.isConstTrue(isscalar(varargin{vIdx})),...
        'Coder:toolbox:dictionaryAggregateNonscalar',class(varargin{vIdx}));
    coder.internal.errorIf(...
        iscell(varargin{vIdx}) && coder.internal.isConstTrue(isempty(varargin{vIdx})),...
        'Coder:toolbox:dictionaryEmptyCell');

    hetValues{i} = idOrToString(varargin{vIdx});



    keyHasCell = keyHasCell || iscell(hetKeys{i});
    valueHasCell = valueHasCell || iscell(hetValues{i});
    allKeysComplexable = allKeysComplexable && isBuiltinNumeric(hetKeys{i});
    allValuesComplexable = allValuesComplexable && isBuiltinNumeric(hetValues{i});
    hasComplexKey = hasComplexKey || (allKeysComplexable && ~isreal(hetKeys{i}));
    hasComplexValue = hasComplexValue || (allValuesComplexable && ~isreal(hetValues{i}));
end



if keyHasCell && ~coder.target('MATLAB')
    keys = hetKeys;
    coder.internal.tryMakeHomogeneousCell(keys);
    coder.internal.assert(coder.internal.isHomogeneousCell(keys), 'Coder:toolbox:dictionaryHetKeys');
else
    keys = hetKeys;
end
if valueHasCell && ~coder.target('MATLAB')
    values = hetValues;
    coder.internal.tryMakeHomogeneousCell(values);
    coder.internal.assert(coder.internal.isHomogeneousCell(values), 'Coder:toolbox:dictionaryHetValues');
else
    values = hetValues;
end
%this is not smart about complexity, and gets weird if there are empties followed by nonempties


if isempty(keys{1})
    startEmpty = true;
    if coder.target('MATLAB') && isstring(keys{1})
        keyEG = "a";
    else
        keyEG = coder.internal.scalarEg(keys{1});
    end
else
    startEmpty = false;
    if iscell(keys{1})
        keyEG = keys{1};
    else
        keyEG = keys{1}(1);
    end
end
if isempty(values{1})
    startEmpty = true;
    if coder.target('MATLAB') && isstring(values{1})
        valueEG = "a";
    else
        valueEG = coder.internal.scalarEg(values{1});
    end
else
    startEmpty = startEmpty || false;
    if iscell(values{1})
        valueEG = values{1};
    else
        if  canNotBeArray(values{1})
            valueEG = values{1};%already scalar, might overload indexing
        else
            valueEG = values{1}(1);
        end
    end
end

expectedNumEntries = coder.internal.indexInt(0);
for i=1:nPairs
    expectedNumEntries = expectedNumEntries + coder.internal.indexInt(numel(keys{i}));
end



storeEGInputs = false;
if allKeysComplexable && hasComplexKey
    keyEG_cmplx = complex(keyEG);
else
    keyEG_cmplx = keyEG;
end
if allValuesComplexable && hasComplexValue
    valueEG_cmplx = complex(valueEG);
else
    valueEG_cmplx = valueEG;
end


kvPairs = coder.internal.basicDictionary({keyEG_cmplx}, {valueEG_cmplx}, expectedNumEntries, startEmpty, storeEGInputs);

end

function out = enumSafeFull(in)
coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
if isenum(in)
    out = in;
else
    out = full(in);
end
end

function out = canNotBeArray(in)
out = isobject(in) && ~isenum(in) && ~isa(in, 'half');
end


% LocalWords:  Keytype dont homogonize nonconst dedupe kv unrequired Unconfigured Sz constness
% LocalWords:  builtins unconfigured EQN idk EG
