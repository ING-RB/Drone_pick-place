classdef basicDictionary < coder.internal.AbstractDict
    %MATLAB Code Generation Private Class
    %implements the actual k/v store, with linear probing.

    %#codegen

    %   Copyright 2023-2024 The MathWorks, Inc.

    properties(Access = public)
        keys
        values
        written
        allocatedSZ
        usedSZ
        numDead
        first
        last
        next
        prev
    end
    methods
        function this = basicDictionary(keys, values, size, initalizeEmpty, writeTheValues)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;

            if nargin == 0
                return;
            end

            coder.internal.assert(numel(keys) == numel(values),... 
                'MATLAB:dictionary:IncorrectNumberOfInputs');
            coder.internal.assert(numel(keys)~=0 && numel(values) ~=0, 'Coder:builtins:Explicit', 'no empties');
            if nargin <= 3
                initalizeEmpty = false;
            end
            if nargin <= 4
                writeTheValues = true;
            end
            if nargin == 2
                nk = numel(keys);
                roundUpFactor = nextpow2(nk+1);
                roundUp = pow2(roundUpFactor);
                asIndex = cast(roundUp, indexType);
                if asIndex > 8
                    this.allocatedSZ = coder.internal.ignoreRange(asIndex);
                else
                    this.allocatedSZ = coder.internal.ignoreRange(cast(8, indexType));
                end
            elseif initalizeEmpty && ~coder.target('MATLAB') %typed empty cells don't exist in matlab, but neither do uninitalized values, so we can allocate some space in this case
                this.allocatedSZ = coder.internal.ignoreRange(cast(0, indexType));
            else
                roundUpFactor = nextpow2(size);
                roundUp = 2.^roundUpFactor;
                this.allocatedSZ = coder.internal.ignoreRange(cast(roundUp, indexType));
            end



            this.usedSZ = zeros(1, indexType);%grown by write
            szArray = [1, this.allocatedSZ];%consider reversing this? but it prints better this way

            if isstring(keys{1})
                this.keys = repmat({string(blanks(coder.internal.ignoreRange(1)))}, szArray);
            else
                if initalizeEmpty
                    this.keys = coder.nullcopy(repmat({keys{1}}, szArray));
                else
                    this.keys = repmat({keys{1}}, szArray);
                end
            end
            if isstring(values{1})
                %it would be nice to nullcopy this
                this.values = repmat({string(blanks(coder.internal.ignoreRange(1)))}, szArray);
            else
                %we want to nullcopy this, but it causes problems for some
                %types
                if initalizeEmpty
                    this.values = coder.nullcopy(repmat({values{1}}, szArray));
                else
                    this.values = repmat({values{1}}, szArray);
                end
            end


            this.written = repmat(coder.internal.WriteStatus.Unwritten, szArray);
            this.first = cast(-1, indexType);
            this.last = this.first;
            this.next = repmat(cast(-1, indexType), szArray);
            this.prev = this.next;
            this.numDead = zeros(1, indexType);

            if ~initalizeEmpty && writeTheValues
                for i=1:numel(keys)
                    this = this.writeNoResizing(keys{i}, values{i});
                end
            end
        end

        function there = hasKey(this, key)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;
            there = this.findKey(key) > 0;
        end

        function [valueOrExample, hasValue] = read(this, key)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;
            idx = this.findKey(key);
            hasValue = idx ~= -1;

            if hasValue
                valueOrExample = this.values{idx};
            else
                valueOrExample = this.getExampleValue;
            end
        end

        function this = write(this, key, value)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;


            if this.allocatedSZ == 0
                %make sure we keep whatever we homogenized on before
                matchedKey = coder.nullcopy(cell([1, coder.internal.ignoreRange(1)]));
                matchedVal = coder.nullcopy(cell([1, coder.internal.ignoreRange(1)]));
                if isstring(key) %todo: something like this is probably necessary for other objects, but I don't know of a generic way to force a copy
                    matchedKey{1} = string(key);
                else
                    matchedKey{1} = key;
                end
                if isstring(value)
                    matchedVal{1} = string(value);
                else
                    matchedVal{1} = value;
                end
                this = assignByProperties(this, coder.internal.basicDictionary(matchedKey, matchedVal));
                return;
            end

            if this.allocatedSZ*3 <= (this.usedSZ + this.numDead)*4 %consider: sooner? check and assert even if wont resize?
                %NOTE: this is happening before we know if this is just an
                %update to an existing value, and will sometimes cause reallocs
                %a little sooner than normal (but thats ok??)
                this = this.reAlloc(this.allocatedSZ*2);
            end

            this = this.writeNoResizing(key, value);


        end

        function this = delete(this, key)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;
            idx = this.findKey(key);
            if idx == -1
                return;
            end
            this.written(idx) = coder.internal.WriteStatus.Dead;
            this.usedSZ = this.usedSZ - 1;
            this.numDead = this.numDead + 1;
            %fprintf('deleted < %f >, usedSZ now < %d >\n', key, this.usedSZ);
            assert(this.usedSZ >= 0);%<HINT>
        end

        function keys = getKeys(this)
            keys = getInOrder(this, "keys");
        end
        function values = getValues(this)
            values = getInOrder(this, "values");
        end
        function eg = getExampleKey(this)

            if coder.target('MATLAB')
                if isempty(this.keys)
                    eg = [];
                else
                    eg = this.keys{1};
                end
            else
                eg = coder.internal.homogeneousCellBase(this.keys);
            end



            % if isobject(this.keys{1}) || coder.target('MATLAB')
            %     if numel(this.keys) > 0
            %         eg = this.keys{1};
            %     else
            %         eg = [];
            %     end
            % else
            %     eg = coder.nullcopy(coder.internal.homogeneousCellBase(this.keys));
            % end
        end
        function eg = getExampleValue(this)
            if coder.target('MATLAB')
                if isempty(this.values)
                    eg = [];
                else
                    eg = this.values{1};
                end
            else
                eg = coder.internal.homogeneousCellBase(this.values);
            end
        end
        function n = getNumel(this)
            n = this.usedSZ;
        end
    end

    methods(Static)
        function finalHash = getHash(key)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;

            coder.internal.errorIf(isobject(key)&&~isstring(key)&&~isenum(key)&&~isa(key, 'half'),...
                'Coder:toolbox:dictionaryBadKeytype');
            %consider storing this info somewhere after things are
            %hashed so we dont have to rehash all the time

            if isstring(key)
                hash = castToIndextype(char(key));
            elseif iscell(key)
                hash = coder.nullcopy(zeros(1, numel(key), indexType));
                for i=1:numel(key)
                    hash(i) = coder.internal.basicDictionary.getHash(key{i});
                end
            elseif isstruct(key)
                fn = fieldnames(key);
                hash = coder.nullcopy(zeros(1, numel(fn)*numel(key), indexType));
                sz = [numel(fn), numel(key)];
                for i=1:numel(key)
                    coder.unroll();
                    for j=1:numel(fn)
                        hash(sub2ind(sz,j,i)) = coder.internal.basicDictionary.getHash(key(i).(fn{j}));
                    end
                end
            elseif issparse(key)
                [i,j,v] = find(key); %can do better on performance if we focus on coder.internal.sparse - but wont work in matlab
                hash = [castToIndextype(size(key)'); castToIndextype([i(:);j(:)]);castToIndextype(v(:))];
            elseif ~isreal(key)
                hash = [castToIndextype(real(key)),...
                    castToIndextype(imag(key))];
            else
                hash = castToIndextype(key);
            end
            %todo: to avoid this cast, just write a hash that works on int32
            %(shouldn't require many changes)
            uintHash = coder.nullcopy(zeros(size(hash), 'uint32'));
            for i = 1:numel(hash)
                uintHash(i) = typecast(hash(i), 'uint32'); % need to do this with scalars because typecast doesn't support varsize inputs
            end
            finalHash = typecast(coder.internal.hashUInt32(uintHash), indexType); %move this
        end
    end
    methods (Static, Hidden = true)
        function t = matlabCodegenTypeof(~)
            t = 'coder.internal.basicDictionaryType';
        end
        % function p = matlabCodgenIndexIntProperties(~)
        %     If the hash type is not index int, I don't think this makes
        %     sense, we would need to constantly be casting back and forth in
        %     order to do mod on the size of the dictionary (very common) or to
        %     use caclulations from a hash as an index (also common)
        %     p = {'first','last','next','prev','numDead','usedSZ','allocatedSZ'};
        % end
    end

    methods(Access = private)
        function idx = findKey(this,key)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;
            if this.usedSZ == 0
                %this is not just an optimization, we also can't index into
                %anything to look when all of the arrays are empty
                idx = cast(-1, indexType);
                return;
            end
            idx = indexMod(this.getHash(key), this.allocatedSZ);
            startIdx = idx;
            %consider bumping the result into the earliest dead spot we
            %see, since we know thats a good place for it to go (we looked there)
            %on the other hand, side effects from findKey might cause lots
            %of problems
            while this.written(idx) ~= coder.internal.WriteStatus.Unwritten %must always have at least one unused spot or will never stop
                if this.written(idx)==coder.internal.WriteStatus.Alive &&...
                        keyMatch(this.keys{idx}, key)
                    return
                end
                idx = indexMod(idx+1, this.allocatedSZ);
                if idx == startIdx % break after one around. g3157459 goes over reasons to get rid of this branch
                    break
                end
            end
            idx = cast(-1, indexType);

        end
        function out = getInOrder(this, prop)
            coder.internal.prefer_const(prop)
            if strcmpi(prop, "keys")
                gettingKeys = true;
                out = coder.nullcopy(cell(this.usedSZ, 1));
            elseif strcmp(prop, "values")
                gettingKeys = false;
                out = coder.nullcopy(cell(this.usedSZ, 1));
            else
                gettingKeys = false;
                coder.internal.assert(false, 'Coder:builtins:Explicit', 'illegal property') %this should never be user-visible
            end
            if this.usedSZ == 0
                return
            end
            cur = this.first;
            i = coder.internal.indexInt(1);
            while true
                %coder.internal.assert(cur > 0, 'Coder:builtins:Explicit', 'TEMP MESSAGE: messed up next/first')
                if this.written(cur) == coder.internal.WriteStatus.Alive
                    if gettingKeys
                        out{i} = this.keys{cur};
                    else
                        out{i} = this.values{cur};
                    end
                    i = i+1;
                end
                if cur == this.last
                    break
                else
                    cur = this.next(cur);
                end
            end
        end


        function this = reAlloc(this, sz)

            if this.usedSZ == 0
                %consider: move this to function? repeated from constructor
                szArray = [1, this.allocatedSZ];
                this.written = repmat(coder.internal.WriteStatus.Unwritten, szArray);
                this.first = cast(-1, indexType);
                this.last = this.first;
                this.next = repmat(cast(-1, indexType), szArray);
                this.prev = this.next;
                this.numDead = zeros(1, indexType);

            else
                this = assignByProperties(this,...
                    coder.internal.basicDictionary(...
                    this.getKeys,...%would be nice not to have to iterate twice
                    this.getValues, sz));
            end
        end

        function this = writeNoResizing(this, key, value)
            coder.internal.allowEnumInputs;
            coder.internal.allowHalfInputs;
            hash = this.getHash(key);
            

            start = indexMod(hash, this.allocatedSZ);
            idx = start;
            firstDead = int32(-1);
            %these conditions are scalar, but simulink can't figure that
            %out so we need to reduce them with all or any
            while (this.written(idx)==coder.internal.WriteStatus.Alive || this.written(idx) == coder.internal.WriteStatus.Dead) &&...
                    ~keyMatch(this.keys{idx}, key) %LIFE: merge with findkey (keep track of dead spots)
                %dead does not mean we should stop looking, since we didn't
                %shift down
                if idx == start && firstDead~=-1
                    idx = firstDead;
                    break; %the entire dictionary is filled with dead TODO: clear them
                end
                if firstDead == -1 && this.written(idx) == coder.internal.WriteStatus.Dead
                    firstDead = idx;
                end

                idx = indexMod(idx+1, this.allocatedSZ);
            end
            if idx~=-1 && this.written(idx) ~= coder.internal.WriteStatus.Alive && firstDead ~= -1
                idx = firstDead;
            end

            if this.first == -1 %first element in the map
                this.first = idx;
                this.last = idx;
                this.usedSZ = this.usedSZ+1;
            elseif this.written(idx)~=coder.internal.WriteStatus.Alive %don't need to do anything if just updating
                if this.written(idx)==coder.internal.WriteStatus.Dead
                    if idx == this.first && idx == this.last
                        %noop, this is an empty dictionary but it already has
                        %the correct first/last
                        %this.usedSZ = this.usedSZ+1;
                    else
                        if idx == this.first
                            this.first = this.next(idx);
                            this.prev(this.next(idx)) = -1; %unnecessary, but helps with debugging
                        elseif idx == this.last
                            this.last = this.prev(idx);
                            this.next(this.prev(idx)) = -1;%unnecesaary, but helps with debugging
                        else
                            this.next(this.prev(idx)) = this.next(idx);
                            this.prev(this.next(idx)) = this.prev(idx);
                        end
                    end
                    this.numDead = this.numDead - 1;
                end
                this.usedSZ = this.usedSZ+1;
                this.prev(idx) = this.last;
                this.next(this.last) = idx;
                this.last = idx;
            end

            this.written(idx) = coder.internal.WriteStatus.Alive;
            if isstring(key)
                c = char(key);
                coder.varsize('c', [1,Inf]); %this stucks, cell is already varsize why does it die
                this.keys{idx} = string(c);
            else
                this.keys{idx} = key;
            end
            if isstring(value)
                c = char(value);
                coder.varsize('c', [1,Inf]);
                this.values{idx} = string(c);
            else
                this.values{idx} = value;
            end
            %fprintf('wrote < %.0f > used sz now < %d >\n', key, this.usedSZ);





        end
        function this = assignByProperties(this, new)
            this.keys = new.keys;
            this.values = new.values;
            this.written = new.written;
            this.allocatedSZ = new.allocatedSZ;
            this.usedSZ = new.usedSZ;
            this.numDead = new.numDead;
            this.first = new.first;
            this.last = new.last;
            this.next = new.next;
            this.prev = new.prev;
        end
    end


end

function out = indexMod(val, base)
coder.inline('always');
%todo: don't use mod - should be possible to map to range with bit operations
outTmp = mod(val-1,base)+1;
out = outTmp(1);%helps ambiguous types for some reason
end

function eq = keyMatch(a,b)
eq = isequaln(a,b);
end

function out = castToIndextype(in)
if isfloat(in)
    in = canonizeFloat(in);
end
if isa(in, 'half')
    out = typecast(single(in(:)), indexType); %half doesn't support typecast, not sure how else to make it fit - we are going to pad to this length anyway
elseif isenum(in)
    %this is kind of sketchy - not sure that I trust that the same class
    %would be found extrinsically, but maybe redirected enums dont really
    %exist?
    baseType = coder.const(feval('coder.internal.getEnumBaseType', class(in)));
    coder.internal.assert(~isempty(baseType), 'Coder:toolbox:dictionaryEnum');
    caster = str2func(baseType);
    out = castToIndextype(caster(in));
elseif ~isnumeric(in) ||...
        (~isa(in, 'double') &&...
        ~isa(in, 'single') &&...
        coder.internal.int_nbits(class(in)) < coder.internal.int_nbits(indexType))
    out = cast(in, indexType);
else
    out = typecast(in(:), indexType);
end
end
function out = indexType
out = 'int32';
end
function x = canonizeFloat(x)
%todo: does this all get optimized away?
%this is a lot of loops for a rare edge case - how important is it? we
%could combine the loops but might lose some other optimizations (something to try)
x(x==0) = zeros(1, 'like', x);
if isa(x, 'double')
    cannonNaN = typecast(int32([0, -524288]), 'double');
elseif isa(x, 'half')
    %typecast doesn't work on half
    tmp = typecast(int32(-4194304), 'single');
    cannonNaN = half(tmp);
else %single
    cannonNaN = typecast(int32(-4194304), 'single');
end
x(isnan(x)) = cannonNaN;
end

% LocalWords:  SZ Indextype nextpow uninitalized nullcopy reallocs eg Keytype dont varsize Codgen
% LocalWords:  caclulations prev builtins findkey noop unnecesaary stucks sz doesnt
