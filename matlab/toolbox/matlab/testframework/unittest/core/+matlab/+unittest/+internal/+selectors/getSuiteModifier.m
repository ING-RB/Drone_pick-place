function modifier = getSuiteModifier(criteria, namedargs)
%

% Copyright 2013-2024 The MathWorks, Inc.

arguments
    criteria (1,1) struct = struct;
    namedargs.OnlySelectors (1,1) logical = false;
end

modifier = getLocatedModifiers(criteria, namedargs.OnlySelectors);
modifier = handleModifierInput(modifier, criteria, namedargs.OnlySelectors);
modifier = handleParameterization(modifier, criteria);
modifier = handleName(modifier, criteria);
modifier = handleBaseFolder(modifier, criteria);
modifier = handleTag(modifier, criteria);
modifier = handleProcedureName(modifier, criteria);
modifier = handleSuperclass(modifier, criteria);
end

function modifier = getLocatedModifiers(criteria, onlySelectors)
import matlab.automation.internal.services.ServiceLocator;
import matlab.unittest.internal.services.ServiceFactory;
import matlab.unittest.internal.services.suitemodifier.SuiteModifierLiaison;

liaison = SuiteModifierLiaison(criteria, OnlySelectors=onlySelectors);
namespace = "matlab.unittest.internal.services.suitemodifier";
cls = ?matlab.unittest.internal.services.suitemodifier.SuiteModifierService;
classes = ServiceLocator.forNamespace(meta.package.fromName(namespace)).locate(cls);
services = ServiceFactory.create(classes);
fulfill(services, liaison);
modifier = liaison.Modifier;
end

function modifier = handleModifierInput(modifier, selectionCriteria, onlySelectors)
if isfield(selectionCriteria, "Modifier")
    if onlySelectors
        className = "matlab.unittest.selectors.Selector";
    else
        className = "matlab.unittest.internal.selectors.Modifier";
    end
    validateattributes(selectionCriteria.Modifier, className, "scalar", "", "selector");
    modifier = modifier & selectionCriteria.Modifier;
end
end

function modifier = handleParameterization(modifier, selectionCriteria)
import matlab.unittest.selectors.HasParameter;

% Need to create a HasParameter selector when one or both of
% 'ParameterProperty' and 'ParameterName' was specified.
hasParameterProperty = isfield(selectionCriteria, 'ParameterProperty');
hasParameterName = isfield(selectionCriteria, 'ParameterName');

if hasParameterProperty || hasParameterName
    propertyArgs = {};
    if hasParameterProperty
        propertyArgs = {'Property', convertValueToMatchesConstraint(selectionCriteria.ParameterProperty,'ParameterProperty')};
    end
    
    nameArgs = {};
    if hasParameterName
        nameArgs = {'Name', convertValueToMatchesConstraint(selectionCriteria.ParameterName,'ParameterName')};
    end
    
    modifier = modifier & HasParameter(propertyArgs{:}, nameArgs{:});
end
end

function modifier = handleName(modifier, selectionCriteria)
import matlab.unittest.selectors.HasName;

if isfield(selectionCriteria, 'Name')
    modifier = modifier & HasName(convertValueToMatchesConstraint(selectionCriteria.Name,'Name'));
end
end

function modifier = handleBaseFolder(modifier, selectionCriteria)
import matlab.unittest.selectors.HasBaseFolder;

if isfield(selectionCriteria, 'BaseFolder')
    constraint = convertValueToMatchesConstraint(selectionCriteria.BaseFolder,'BaseFolder');
    if ispc
        constraint = constraint.ignoringCase;
    end
    modifier = modifier & HasBaseFolder(constraint);
end
end

function modifier = handleTag(modifier, selectionCriteria)
import matlab.unittest.selectors.HasTag;

if isfield(selectionCriteria, 'Tag')
    modifier = modifier & HasTag(convertValueToMatchesConstraint(selectionCriteria.Tag,'Tag'));
end
end

function modifier = handleProcedureName(modifier, selectionCriteria)
import matlab.unittest.selectors.HasProcedureName;

if isfield(selectionCriteria, 'ProcedureName')    
    modifier = modifier & HasProcedureName(convertValueToMatchesConstraint(selectionCriteria.ProcedureName,'ProcedureName'));   
end
end

function modifier = handleSuperclass(modifier, selectionCriteria)
import matlab.unittest.selectors.HasSuperclass

if isfield(selectionCriteria, 'Superclass')
    modifier = modifier & covertValueToSuperclassSelector(selectionCriteria.Superclass,'Superclass');
end
end

function checkIfInputParametersAreValid(value,criteria)
import matlab.unittest.internal.mustContainCharacters;
import matlab.unittest.internal.mustBeTextScalarOrTextArray;

mustBeTextScalarOrTextArray(value,criteria);
mustContainCharacters(value,criteria);

validateattributes(value,{'cell','string','char'} ,{'nonempty','row'}, '', criteria);
end

function constraint = convertValueToMatchesConstraint(value,criteria)
import matlab.unittest.constraints.Matches;

checkIfInputParametersAreValid(value,criteria);
value = string(value);
constraint = Matches(['^', regexptranslate('wildcard',char(value(1))), '$']);
for i = 2:numel(value)
    constraint = constraint | Matches(['^', regexptranslate('wildcard',char(value(i))), '$']);
end
end

function constraint = covertValueToSuperclassSelector(value,criteria)
import matlab.unittest.selectors.HasSuperclass;

checkIfInputParametersAreValid(value,criteria);
value = string(value);
constraint = HasSuperclass(char(value(1)));
for i = 2:numel(value)
    constraint = constraint | HasSuperclass(value(i));
end
end

% LocalWords:  namedargs suitemodifier cls
