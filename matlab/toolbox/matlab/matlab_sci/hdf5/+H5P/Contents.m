% Contents for H5P:  Property interface
%
%  To use these functions, you must be familiar with the information about 
%  the Property List Interface contained in the HDF5 User's Guide and
%  Reference Manual. This documentation may be obtained from The HDF
%  Group at <http://www.hdfgroup.org>.
%
%  General Property List Operations
%    close            - Closes a property list.
%    copy             - Copies an existing property list.
%    create           - Creates a property list.
%    get_class        - Gets the property list class for a property list.
%
%  Generic Property List Operations
%    close_class      - Closes a property list class.
%    equal            - Checks if property lists are equal.
%    exist            - Checks if a named property exists.
%    get              - Gets the value of a property.
%    get_class_name   - Gets the name of a class.
%    get_class_parent - Gets the parent class.
%    get_nprops       - Gets the number of properties.
%    get_size         - Gets the size of a property value.
%    isa_class        - Checks if property list is a class member.
%    iterate          - Iterates over properties in a property class.
%    set              - Sets a property list value.
%
%  Dataset Access, Memory, and Transfer Properties
%    get_btree_ratios      - Gets B-tree split ratios.
%    get_chunk_cache       - Gets chunk cache parameters.
%    get_edc_check         - Gets error-detection mode.
%    get_hyper_vector_size - Gets number of hyperslab I/O vectors.
%    get_virtual_print_gap - Returns max number of missing source files and/or datasets. 
%    get_virtual_view      - Gets view of virtual dataset.
%    set_btree_ratios      - Sets B-tree split ratios.
%    set_chunk_cache       - Sets chunk cache parameters.
%    set_edc_check         - Sets error-detection mode.
%    set_hyper_vector_size - Sets number of hyperslab I/O vectors.
%    set_virtual_print_gap - Sets max number of missing source files and/or datasets. 
%    set_virtual_view      - Sets view of virtual dataset.
%
%  Dataset Creation Properties
%    all_filters_avail     - Checks if filters are available.
%    fill_value_defined    - Checks if a fill value is defined.
%    get_alloc_time        - Gets the timing for allocation.
%    get_chunk             - Gets the chunk size.
%    get_chunk_opts        - Gets the edge chunk option.
%    get_external          - Gets external file from the list.
%    get_external_count    - Gets the count of external files.
%    get_fill_time         - Gets the fill values write time.
%    get_fill_value        - Gets the dataset fill value.
%    get_filter            - Gets the filter in a pipeline.
%    get_filter_by_id      - Gets the filter information by index.
%    get_layout            - Gets the raw data layout.
%    get_nfilters          - Gets the number of pipeline filters.
%    get_virtual_count     - Gets number of mappings for virtual dataset.
%    get_virtual_dsetname  - Gets the name of the source dataset .
%    get_virtual_srcspace  - Gets the id of the source data selection.
%    get_virtual_vspace    - Gets the id of the virtual dataset selection.
%    modify_filter         - Modifies a filter in a pipeline.
%    remove_filter         - Delete filters in the filter pipeline.
%    set_alloc_time        - Sets the timing for allocation.
%    set_chunk             - Sets the chunk size.
%    set_chunk_opts        - Sets the edge chunk option.
%    set_deflate           - Sets compression method and level.
%    set_external          - Adds external file to the list.
%    set_fill_time         - Sets the fill value write time.
%    set_fill_value        - Sets the fill value for a dataset.
%    set_filter            - Adds the filter to the pipeline.
%    set_fletcher32        - Sets up use of the Fletcher32 filter.
%    set_layout            - Sets the raw data layout.
%    set_nbit              - Sets up the use of the N-Bit filter.
%    set_scaleoffset       - Sets up the Scale-Offset filter.
%    set_shuffle           - Sets up use of the shuffle filter.
%    set_szip              - Sets up use of the SZIP compression filter.
%    set_virtual           - Sets mapping for virtual datasets.
%
%  File Access Properties
%    get_alignment             - Gets alignment properties.
%    get_driver                - Gets low-lever driver identifier.
%    get_family_offset         - Gets low-level file offset.
%    get_fapl_core             - Gets the H5FD_CORE driver properties.
%    get_fapl_family           - Gets file access for the family driver.
%    get_fapl_multi            - Gets multi-file driver properties.
%    get_fclose_degree         - Gets the file close degree.
%    get_file_space_page_size  - Gets the file space page size.
%    get_file_space_strategy   - Gets the file space handling information.
%    get_libver_bounds         - Gets library version bounds settings.
%    get_gc_references         - Gets the garbage collecting settings.
%    get_metadata_read_attempts- Gets the number of read attempts.
%    get_mdc_config            - Gets the metadata cache configuration.
%    get_meta_block_size       - Gets the metadata block size setting.
%    get_multi_type            - Gets MULTI driver type of data.
%    get_page_buffer_size      - Gets information about the page buffer size.
%    get_sieve_buf_size        - Gets maximum data sieve buffer size.
%    get_small_data_block_size - Gets the small data block size setting.
%    set_alignment             - Sets alignment properties.
%    set_family_offset         - Sets low-level file offset .
%    set_fapl_core             - Sets the H5FD_CORE driver properties.
%    set_fapl_family           - Sets file access for the family driver.
%    set_fapl_log              - Sets up the use of the logging driver.
%    set_fapl_multi            - Sets multi-file driver properties.
%    set_fapl_sec2             - Sets up the use of the sec2 driver.
%    set_fapl_split            - Emulates the old split file driver.
%    set_fapl_stdio            - Sets the standard I/O driver.
%    set_fclose_degree         - Sets the file close degree.
%    set_file_space_page_size  - Sets the file space page size for a file.
%    set_file_space_strategy   - Sets the file space handling strategy.
%    set_gc_references         - Sets the garbage collecting flag.
%    set_libver_bounds         - Sets library version bounds settings.
%    set_mdc_config            - Sets the metadata cache configuration.
%    set_meta_block_size       - Sets the minimum metadata block size.
%    set_metadata_read_attempts- Sets the number of read attempts in a faplID.
%    set_multi_type            - Sets the type of data property.
%    set_page_buffer_size      - Sets the information about the page buffer size.
%    set_sieve_buf_size        - Sets the data sieve buffer max size.
%    set_small_data_block_size - Sets small data contiguous block sizes.
%
%  File Creation Properties
%    get_istore_k             - Gets the 1/2 rank of a B-tree.
%    get_sizes                - Gets size of the object offsets and lengths.
%    get_sym_k                - Gets symbol table node parameter sizes.
%    get_userblock            - Gets the size of a user block.
%    get_version              - Gets the version information.
%    set_istore_k             - Sets the 1/2 rank of a B-tree.
%    set_sizes                - Sets size of the object offsets and lengths
%    set_sym_k                - Sets symbol table node parameter sizes.
%    set_userblock            - Sets the size of a user block.
%
%  Object Copy and Object Creation Properties
%    get_attr_creation_order - Gets attribute creation order.
%    get_attr_phase_change   - Gets attribute storage phase change thresholds.
%    get_copy_object         - Gets object copy property options.
%    set_attr_creation_order - Sets attribute creation order.
%    set_attr_phase_change   - Sets attribute storage phase change thresholds.
%    set_copy_object         - Sets object copy property options.
%
%  Group Creation Properties
%    get_create_intermediate_group - Gets intermediate group creation setting.
%    get_link_creation_order       - Gets link creation order .
%    get_link_phase_change         - Gets compact, dense group thresholds.
%    set_create_intermediate_group - Sets intermediate group creation setting
%    set_link_creation_order       - Sets link creation order.
%    set_link_phase_change         - Sets compact, dense group thresholds.
%
%  String Properties
%    get_char_encoding             - Gets the character encoding.
%    set_char_encoding             - Sets the character encoding.
%
%  File Integrity Checks
%    set_relax_file_integrity_checks - Sets relaxed file integrity check flag.
%    get_relax_file_integrity_checks - Gets relaxed file integrity check flag.

%   Copyright 2006-2024 The MathWorks, Inc.
