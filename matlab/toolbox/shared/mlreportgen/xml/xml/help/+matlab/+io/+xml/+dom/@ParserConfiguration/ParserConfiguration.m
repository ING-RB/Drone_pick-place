%matlab.io.xml.dom.ParserConfiguration Defines XML parse options
%
%    ParserConfiguration properties:
%       Namespaces               - Allow elements in undefined namespaces
%       ElementContentWhitespace - Include white space in the output
%       LoadExternalDTD          - Load an external DTD
%       DisableEntityResolution  - Resolve entity references
%       AllowDoctype             - Whether to parse a document containing a DTD
%       StandardURIConformant    - Enforce URI conformity
%       Entities                 - Whether to expand entities
%       Validate                 - Validate input markup
%       SkipDTDValidation        - Do not use DTD to validate input
%       ValidationErrorAsFatal   - Halt parsing on validation error
%       ContinueAfterFatalError  - Continue parsing after validation error
%       Comments                 - Include comments in parsed document
%       DoXInclude               - Include XInclude-specified content
%       ExternalSchemaLocation   - Location of external schema
%       ExternalNoNamespaceSchemaLocation - Location of non-namespace schema
%       LoadSchema                        - Load external schema
%       Schema                            - Enable use of schemas
%       ValidateIfSchema                  - Use schema for validation
%       SchemaFullChecking                - Check schema constraints
%       DatatypeNormalization             - Normalize white space using schema
%       IgnoreAnnotations                 - Ignore schema annotations
%       ValidateAnnotations               - Validate schema annotations
%       GenerateSyntheticAnnotations      - Generate schema annotations
%       CacheGrammarFromParse             - Cache parsed schema
%       UseCachedGrammarInParse           - Use parsed schema
%       HandleMultipleImports             - Import multiple schemas
%       HasPSVI                           - Save post-schema-validation information
%       IdentityConstraintChecking        - Check identity constraints
%       EntityResolver                    - Resolve document entities
%       ErrorHandler                      - Handle parse errors
%
%    See also matlab.io.xml.dom.Parser

%    Copyright 2020-2022 MathWorks, Inc.
%    Built-in class

%{
properties
    %Namespaces Whether to output elements with undeclared namespaces
    %    If this option is true (default), include an element having a
    %    qualified name in the output document only if the qualified name 
    %    resides in a declared namespace.
    Namespaces;

    %ElementContentWhitespace Whether to include white space in the output
    %    If this option is true (default), include ignorable white space
    %    in the output document. If this option is false, do not include 
    %    ignorable white space in the output.
    ElementContentWhitespace;

    %LoadExternalDTD Whether to load an external DTD
    %    If this feature is true (default), load the external DTD
    %    specified by the input markup. If this option is false, ignore the
    %    external DTD.
    %
    %    Note: This option is ignored and the DTD is loaded if the 
    %    Validate option is set to true.
    %
    %    See also matlab.io.xml.dom.ParserConfiguration.Validate
    LoadExternalDTD;

    %DisableEntityResolution Whether to resolve entity references
    %    If this option is true, do not attempt to resolve entity 
    %    references. If this option is false (default), attempt to 
    %    resolve entity references.
    DisableEntityResolution;

    %AllowDoctype Whether to parse a document containing a DTD
    %    If false (the default), this option causes the parser to throw an 
    %    error if the XML markup to be parsed includes a document type 
    %    definition (DTD). A DTD can be used to attack a system. Enable 
    %    this option only for XML files from trusted sources.
    %    only for trusted sources. 
    %
    % See also https://owasp.org/www-community/vulnerabilities/XML_External_Entity_(XXE)_Processing
    AllowDoctype;

    %StandardURIConformant Whether to enforce URI conformity
    %    If this option is true, force standard URI conformance. If
    %    false (default), do not force standard URI conformance.
    %
    %    Note: If this option is true, the parser rejects a malformed URI 
    %    and throws a fatal error.
    StandardURIConformant;

    %Entities Whether to retain Entity and EntityReference nodes
    %    If this option is true (default), the parsed document represents
    %    parsed entities and entity references as Entity and 
    %    EntityReference nodes, respectively. If this option is false, the
    %    parser replaces an entity reference node with the children of that
    %    node. For example, suppose the DTD of the document to be parsed 
    %    defines an external entity as
    %  
    %    <!ENTITY sect  SYSTEM "./sect.xml">
    %
    %    where sect.xml contains XML content to be included in the 
    %    document. Then, if this option is false, the parser parses
    %    sect.xml and replaces occurrence of &sect; in the parsed document
    %    with the parsed content of sect.xml. If this option is true, the
    %    parser replaces occurrences of &sect; with EntityReference nodes
    %    containing the parsed content of sect.xml. In this case, if the
    %    parsed document is serialized, the EntityReference nodes are 
    %    replaces with &sect; in the resulting XML markup.
    Entities;

    %Validate Whether to validate input markup
    %    If this option is false (default), do not report markup errors in
    %    the parser input; if true, report markup errors.
    %
    %    Note: If this option is true, the document must specify a grammar 
    %    (DTD or schema). If this option is false and the document 
    %    specifies a grammar, the parser may parse the grammar but will not
    %    validate the input.
    Validate;

    %SkipDTDValidation Whether to use DTD to validate input
    %    If this option is true, use the DTD specified by the input only to 
    %    resolve entity references. If this option is false (default) and 
    %    validation is enabled, use the DTD to validate input.
    %
    %    See also  matlab.io.xml.dom.ParserConfiguration.Validate
    SkipDTDValidation;

    %ValidationErrorAsFatal Whether validation errors are fatal
    %    If this option is true (default) and the ContinueAfterFatalError
    %    option is false, treat a validation error as fatal and exit. If 
    %    this option is false, report the error and continue processing.
    %
    %    See also 
    %    matlab.io.xml.dom.ParserConfiguration.ContinueAfterFatalError
    ValidationErrorAsFatal;

    %ContinueAfterFatalError Whether to continue parsing after fatal error
    %    If this option is true, attempt to continue parsing after a fatal 
    %    error. If this option is false (default), stop parse on first 
    %    fatal error.
    %
    %    Note: The behavior of the parser when this option is true is 
    %    undetermined. Therefore use this feature with extreme caution 
    %    because the parser may get stuck in an infinite loop or worse.
    ContinueAfterFatalError;

    %Comments Whether to include input comments in the parser output
    %    If this option is true (default), include input comments in 
    %    the output document; otherwise, ignore comments.
    Comments;

    %DoXInclude Whether to process XInclude declarations
    %    If this option is true, include nodes specified by XInclude
    %    declarations in the output document tree. If this option is false 
    %   (default), ignore XInclude declarations.
    DoXInclude;

    %ExternalSchemaLocation Specify list of schema locations
    %    The value of this property is a character vector or string
    %    that specifies a list of namespace-location pairs. If one or more
    %    namespaces in the instance document match namespaces in the list, 
    %    the parser uses the corresponding schemas to validate the
    %    document. Use spaces to separate namespace-location pairs in the
    %    list.
    %
    %    Example
    %
    %    parser.Configuration.ExternalSchemaLocation = ...
    %           "http://www.w3.org/XML/1998/namespace xml.xsd" + ...
    %           " http://autosar.org/schema/r4.0 AUTOSAR_4-0-2.xsd";
    ExternalSchemaLocation

    %ExternalNoNamespaceSchemaLocation Specify no-namespace schema location
    %    The value of this property is a character vector or string that 
    %    specifies the location, e.g., mydoc.xsd, of a document schema that 
    %    does not use namespaces. The specified schema overrides the schema
    %    specified by the instance document.
    ExternalNoNamespaceSchemaLocation;

    %LoadSchema Whether to load a schema
    %    If this option is true (default) and the schema support option 
    %    (Schema) is true, load the schema specified by the input markup.
    %    If this option is  false, don't load the schema.
    %
    %    See also  matlab.io.xml.dom.ParserConfiguration.Schema
    LoadSchema;

    %Schema Whether to support schema-based markup validation
    %    If this option and the Namespace option are true, enable the
    %    parser's schema support. If this option is false (default),
    %    disable the parser's schema support.
    %
    %    See also  matlab.io.xml.dom.ParserConfiguration.Namespace,
    %    matlab.io.xml.dom.ParserConfiguration.LoadSchema,
    %    matlab.io.xml.dom.ParserConfiguration.Validate,
    %    matlab.io.xml.dom.ParserConfiguration.ValidateIfSchema
    Schema;

    %ValidateIfSchema Validate input only if input specifies a schema
    %    This option determines whether the input document may specify
    %    either a DTD or schema or must specify a schema to enable 
    %    validation if the Validation option is true. If the Validation 
    %    option and this option are both true, the input must specify a 
    %    schema to enable validation. If the Validate option is true
    %    and this option is false (default), the input may specify either
    %    a DTD or a schema to enable validation.
    %
    %    See also matlab.io.xml.dom.ParserConfiguration.Validate,
    %    matlab.io.xml.dom.ParserConfiguration.Schema
    ValidateIfSchema;

    %SchemaFullChecking Whether to enable full schema constraint checking
    %    If this option is true, enable checking a schema for particle 
    %    unique attribution constraint and particle derivation restriction 
    %    constraint errors. Checking for such errors is time-consuming and
    %    memory intensive. If this option is false (default), disable full 
    %    schema constraint checking.
    SchemaFullChecking;

    %DatatypeNormalization Whether to normalize white space in input
    %    If this option is true, validation is enabled, and the input 
    %    specifies a schema, use the white space normalization options
    %    defined in the schema for each attribute and element data type to
    %    normalize white space in element and attribute values during 
    %    validation of the input. If this option is false (default), 
    %    normalize only attribute values as defined in the XML 1.0
    %    standard. 
    DatatypeNormalization;

    %IgnoreAnnotations Whether to ignore annotations in schema markup
    %    If this option is true, ignore annotations when parsing a schema.
    %    If this option is false (default), convert annotation declarations
    %    to annotation nodes in the schema output.
    IgnoreAnnotations;

    %ValidateAnnotations Whether to validate annotations
    %    If this feature is true, enable validation of annotations.
    %    If this feature is false (default), disable validation of 
    %    annotations.
    %
    %    Note: Each annotation is validated independently.
    ValidateAnnotations;

    %GenerateSyntheticAnnotations Whether to generate synthetic annotations
    %    If this option is true, enable generation of synthetic 
    %    annotations. A synthetic annotation is generated when a schema
    %    component has non-schema attributes but no child annotation.  
    %    If this feature is false (default), disable generation of 
    %    synthetic annotations.
    GenerateSyntheticAnnotations;

    %CacheGrammarFromParse Whether to cache parsed schema
    %   If this feature is true, cache the schema grammar for re-use 
    %   in subsequent parses.  If this feature is false (default), 
    %   do not cache the grammar.
    %
    %   Note: If this option is true, the parser uses the cached grammar
    %   regardless of the setting of the UseCachedGrammarInParse option.
    %
    %    See also 
    %    matlab.io.xml.dom.ParserConfiguration.UseCachedGrammarInParse
    CacheGrammarFromParse;

    %UseCachedGrammarInParse Whether to use a cached grammar
    %    If this option is true (default), use cached schema grammar if it
    %    exists. If this option is false, parse the schema.
    %
    %    Note: If the CacheGrammarFromParse option is true, the parser uses
    %    the cached grammar regardless of the setting of this option.
    %
    %    See also 
    %    matlab.io.xml.dom.ParserConfiguration.CacheGrammatFromParse
    UseCachedGrammarInParse;

    %HandleMultipleImports Whether to allow multipe schemas
    %    If this option is true, allow multiple schemas with the 
    %    same namespace to be imported during schema validation. If this 
    %    feature is false (default), do not import multiple schemas
    %    with the same namespace.
    HandleMultipleImports;

    %HasPSVIInfo Whether to store post-schema validation information
    %    If this option is true, enable storing of post-schema 
    %    validation information (PSVI) in element and attribute nodes. 
    %    If this option isfalse (default), disable storing of PSVI
    %    in element and attribute nodes.
    HasPSVIInfo;

    %IdentityConstraintChecking Whether to check identity constraints
    %    If this feature option is true (default), enable checking identity
    %    constraints specified by the schema associated with a document. If 
    %    this feature is false, disable identity constraint checking.
    IdentityConstraintChecking;

    %EntityResolver Object that resolves entity references
    %    The value of this property is empty by default. To enable a
    %    parser to resolve entities referenced by a document, 
    %    subclass matlab.io.xml.dom.EntityResolver and set this
    %    property to an instance of the subclass.
    EntityResolver;

    %ErrorHandler Object that handles parse errors
    %    If this value is empty (the default), the parser uses a default
    %    error handler to handle errors that the parser encounters while
    %    parsing XML markup in a file or string. The default handler
    %    terminates parsing at the first parse error and throws a MATLAB
    %    error. You can use this property to specify a custom error 
    %    handler that can enable the parser to continue parsing if feasible
    %    after encountering a markup error. To specify a custom parser,
    %    set this property to an instance of a handler derived from
    %    matlab.io.xml.dom.ErrorHandler.
    %
    %    See also matlab.io.xml.dom.ParseErrorHandler
    ErrorHandler;
   
end
%}