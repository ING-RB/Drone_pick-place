// generated from rosidl_generator_c/resource/idl__description.c.em
// with input from octomap_msgs:srv/BoundingBoxQuery.idl
// generated code does not contain a copyright notice

#include "octomap_msgs/srv/detail/bounding_box_query__functions.h"

ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__BoundingBoxQuery__get_type_hash(
  const rosidl_service_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_type_hash_t hash = {1, {
      0x51, 0x15, 0xfa, 0x06, 0x0b, 0x6e, 0x9c, 0x8f,
      0x7b, 0x1d, 0xba, 0x63, 0xdc, 0x31, 0x8f, 0x43,
      0x08, 0xe6, 0x0a, 0xb9, 0x36, 0xee, 0xde, 0x09,
      0x86, 0x38, 0x57, 0x68, 0x78, 0x7d, 0xbe, 0x23,
    }};
  return &hash;
}

ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__BoundingBoxQuery_Request__get_type_hash(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_type_hash_t hash = {1, {
      0xbb, 0x7d, 0x0a, 0x53, 0x52, 0xf9, 0x0b, 0x66,
      0x44, 0x33, 0xa1, 0x2e, 0xf5, 0x39, 0xae, 0xcd,
      0x67, 0x6e, 0xb6, 0x1c, 0x5f, 0xa8, 0x4f, 0xe7,
      0xd3, 0x01, 0x97, 0x69, 0x25, 0x2c, 0xd3, 0xb9,
    }};
  return &hash;
}

ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__BoundingBoxQuery_Response__get_type_hash(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_type_hash_t hash = {1, {
      0x30, 0x75, 0xe1, 0xc8, 0x8f, 0xc0, 0xa4, 0x10,
      0xa5, 0xda, 0x5d, 0xfd, 0x31, 0x4d, 0xa8, 0x4f,
      0xbe, 0xbc, 0xf0, 0x11, 0x3e, 0xdf, 0xf2, 0xa7,
      0xb9, 0x37, 0xeb, 0xb8, 0x1e, 0xe8, 0x28, 0x6f,
    }};
  return &hash;
}

ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__BoundingBoxQuery_Event__get_type_hash(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_type_hash_t hash = {1, {
      0x3c, 0xd3, 0xab, 0xb6, 0x55, 0xb3, 0x48, 0xe1,
      0xd5, 0x6e, 0x3a, 0xc1, 0xe9, 0xc9, 0x73, 0x92,
      0xaf, 0x3d, 0x66, 0xcd, 0xbc, 0x93, 0x8c, 0x13,
      0xe9, 0xcb, 0x7a, 0x78, 0xd4, 0x6c, 0x58, 0x71,
    }};
  return &hash;
}

#include <assert.h>
#include <string.h>

// Include directives for referenced types
#include "service_msgs/msg/detail/service_event_info__functions.h"
#include "builtin_interfaces/msg/detail/time__functions.h"
#include "geometry_msgs/msg/detail/point__functions.h"

// Hashes for external referenced types
#ifndef NDEBUG
static const rosidl_type_hash_t builtin_interfaces__msg__Time__EXPECTED_HASH = {1, {
    0xb1, 0x06, 0x23, 0x5e, 0x25, 0xa4, 0xc5, 0xed,
    0x35, 0x09, 0x8a, 0xa0, 0xa6, 0x1a, 0x3e, 0xe9,
    0xc9, 0xb1, 0x8d, 0x19, 0x7f, 0x39, 0x8b, 0x0e,
    0x42, 0x06, 0xce, 0xa9, 0xac, 0xf9, 0xc1, 0x97,
  }};
static const rosidl_type_hash_t geometry_msgs__msg__Point__EXPECTED_HASH = {1, {
    0x69, 0x63, 0x08, 0x48, 0x42, 0xa9, 0xb0, 0x44,
    0x94, 0xd6, 0xb2, 0x94, 0x1d, 0x11, 0x44, 0x47,
    0x08, 0xd8, 0x92, 0xda, 0x2f, 0x4b, 0x09, 0x84,
    0x3b, 0x9c, 0x43, 0xf4, 0x2a, 0x7f, 0x68, 0x81,
  }};
static const rosidl_type_hash_t service_msgs__msg__ServiceEventInfo__EXPECTED_HASH = {1, {
    0x41, 0xbc, 0xbb, 0xe0, 0x7a, 0x75, 0xc9, 0xb5,
    0x2b, 0xc9, 0x6b, 0xfd, 0x5c, 0x24, 0xd7, 0xf0,
    0xfc, 0x0a, 0x08, 0xc0, 0xcb, 0x79, 0x21, 0xb3,
    0x37, 0x3c, 0x57, 0x32, 0x34, 0x5a, 0x6f, 0x45,
  }};
#endif

static char octomap_msgs__srv__BoundingBoxQuery__TYPE_NAME[] = "octomap_msgs/srv/BoundingBoxQuery";
static char builtin_interfaces__msg__Time__TYPE_NAME[] = "builtin_interfaces/msg/Time";
static char geometry_msgs__msg__Point__TYPE_NAME[] = "geometry_msgs/msg/Point";
static char octomap_msgs__srv__BoundingBoxQuery_Event__TYPE_NAME[] = "octomap_msgs/srv/BoundingBoxQuery_Event";
static char octomap_msgs__srv__BoundingBoxQuery_Request__TYPE_NAME[] = "octomap_msgs/srv/BoundingBoxQuery_Request";
static char octomap_msgs__srv__BoundingBoxQuery_Response__TYPE_NAME[] = "octomap_msgs/srv/BoundingBoxQuery_Response";
static char service_msgs__msg__ServiceEventInfo__TYPE_NAME[] = "service_msgs/msg/ServiceEventInfo";

// Define type names, field names, and default values
static char octomap_msgs__srv__BoundingBoxQuery__FIELD_NAME__request_message[] = "request_message";
static char octomap_msgs__srv__BoundingBoxQuery__FIELD_NAME__response_message[] = "response_message";
static char octomap_msgs__srv__BoundingBoxQuery__FIELD_NAME__event_message[] = "event_message";

static rosidl_runtime_c__type_description__Field octomap_msgs__srv__BoundingBoxQuery__FIELDS[] = {
  {
    {octomap_msgs__srv__BoundingBoxQuery__FIELD_NAME__request_message, 15, 15},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {octomap_msgs__srv__BoundingBoxQuery_Request__TYPE_NAME, 41, 41},
    },
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery__FIELD_NAME__response_message, 16, 16},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {octomap_msgs__srv__BoundingBoxQuery_Response__TYPE_NAME, 42, 42},
    },
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery__FIELD_NAME__event_message, 13, 13},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {octomap_msgs__srv__BoundingBoxQuery_Event__TYPE_NAME, 39, 39},
    },
    {NULL, 0, 0},
  },
};

static rosidl_runtime_c__type_description__IndividualTypeDescription octomap_msgs__srv__BoundingBoxQuery__REFERENCED_TYPE_DESCRIPTIONS[] = {
  {
    {builtin_interfaces__msg__Time__TYPE_NAME, 27, 27},
    {NULL, 0, 0},
  },
  {
    {geometry_msgs__msg__Point__TYPE_NAME, 23, 23},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery_Event__TYPE_NAME, 39, 39},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery_Request__TYPE_NAME, 41, 41},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery_Response__TYPE_NAME, 42, 42},
    {NULL, 0, 0},
  },
  {
    {service_msgs__msg__ServiceEventInfo__TYPE_NAME, 33, 33},
    {NULL, 0, 0},
  },
};

const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__BoundingBoxQuery__get_type_description(
  const rosidl_service_type_support_t * type_support)
{
  (void)type_support;
  static bool constructed = false;
  static const rosidl_runtime_c__type_description__TypeDescription description = {
    {
      {octomap_msgs__srv__BoundingBoxQuery__TYPE_NAME, 33, 33},
      {octomap_msgs__srv__BoundingBoxQuery__FIELDS, 3, 3},
    },
    {octomap_msgs__srv__BoundingBoxQuery__REFERENCED_TYPE_DESCRIPTIONS, 6, 6},
  };
  if (!constructed) {
    assert(0 == memcmp(&builtin_interfaces__msg__Time__EXPECTED_HASH, builtin_interfaces__msg__Time__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[0].fields = builtin_interfaces__msg__Time__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&geometry_msgs__msg__Point__EXPECTED_HASH, geometry_msgs__msg__Point__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[1].fields = geometry_msgs__msg__Point__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[2].fields = octomap_msgs__srv__BoundingBoxQuery_Event__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[3].fields = octomap_msgs__srv__BoundingBoxQuery_Request__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[4].fields = octomap_msgs__srv__BoundingBoxQuery_Response__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&service_msgs__msg__ServiceEventInfo__EXPECTED_HASH, service_msgs__msg__ServiceEventInfo__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[5].fields = service_msgs__msg__ServiceEventInfo__get_type_description(NULL)->type_description.fields;
    constructed = true;
  }
  return &description;
}
// Define type names, field names, and default values
static char octomap_msgs__srv__BoundingBoxQuery_Request__FIELD_NAME__min[] = "min";
static char octomap_msgs__srv__BoundingBoxQuery_Request__FIELD_NAME__max[] = "max";

static rosidl_runtime_c__type_description__Field octomap_msgs__srv__BoundingBoxQuery_Request__FIELDS[] = {
  {
    {octomap_msgs__srv__BoundingBoxQuery_Request__FIELD_NAME__min, 3, 3},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {geometry_msgs__msg__Point__TYPE_NAME, 23, 23},
    },
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery_Request__FIELD_NAME__max, 3, 3},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {geometry_msgs__msg__Point__TYPE_NAME, 23, 23},
    },
    {NULL, 0, 0},
  },
};

static rosidl_runtime_c__type_description__IndividualTypeDescription octomap_msgs__srv__BoundingBoxQuery_Request__REFERENCED_TYPE_DESCRIPTIONS[] = {
  {
    {geometry_msgs__msg__Point__TYPE_NAME, 23, 23},
    {NULL, 0, 0},
  },
};

const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__BoundingBoxQuery_Request__get_type_description(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static bool constructed = false;
  static const rosidl_runtime_c__type_description__TypeDescription description = {
    {
      {octomap_msgs__srv__BoundingBoxQuery_Request__TYPE_NAME, 41, 41},
      {octomap_msgs__srv__BoundingBoxQuery_Request__FIELDS, 2, 2},
    },
    {octomap_msgs__srv__BoundingBoxQuery_Request__REFERENCED_TYPE_DESCRIPTIONS, 1, 1},
  };
  if (!constructed) {
    assert(0 == memcmp(&geometry_msgs__msg__Point__EXPECTED_HASH, geometry_msgs__msg__Point__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[0].fields = geometry_msgs__msg__Point__get_type_description(NULL)->type_description.fields;
    constructed = true;
  }
  return &description;
}
// Define type names, field names, and default values
static char octomap_msgs__srv__BoundingBoxQuery_Response__FIELD_NAME__structure_needs_at_least_one_member[] = "structure_needs_at_least_one_member";

static rosidl_runtime_c__type_description__Field octomap_msgs__srv__BoundingBoxQuery_Response__FIELDS[] = {
  {
    {octomap_msgs__srv__BoundingBoxQuery_Response__FIELD_NAME__structure_needs_at_least_one_member, 35, 35},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_UINT8,
      0,
      0,
      {NULL, 0, 0},
    },
    {NULL, 0, 0},
  },
};

const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__BoundingBoxQuery_Response__get_type_description(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static bool constructed = false;
  static const rosidl_runtime_c__type_description__TypeDescription description = {
    {
      {octomap_msgs__srv__BoundingBoxQuery_Response__TYPE_NAME, 42, 42},
      {octomap_msgs__srv__BoundingBoxQuery_Response__FIELDS, 1, 1},
    },
    {NULL, 0, 0},
  };
  if (!constructed) {
    constructed = true;
  }
  return &description;
}
// Define type names, field names, and default values
static char octomap_msgs__srv__BoundingBoxQuery_Event__FIELD_NAME__info[] = "info";
static char octomap_msgs__srv__BoundingBoxQuery_Event__FIELD_NAME__request[] = "request";
static char octomap_msgs__srv__BoundingBoxQuery_Event__FIELD_NAME__response[] = "response";

static rosidl_runtime_c__type_description__Field octomap_msgs__srv__BoundingBoxQuery_Event__FIELDS[] = {
  {
    {octomap_msgs__srv__BoundingBoxQuery_Event__FIELD_NAME__info, 4, 4},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {service_msgs__msg__ServiceEventInfo__TYPE_NAME, 33, 33},
    },
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery_Event__FIELD_NAME__request, 7, 7},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE_BOUNDED_SEQUENCE,
      1,
      0,
      {octomap_msgs__srv__BoundingBoxQuery_Request__TYPE_NAME, 41, 41},
    },
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery_Event__FIELD_NAME__response, 8, 8},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE_BOUNDED_SEQUENCE,
      1,
      0,
      {octomap_msgs__srv__BoundingBoxQuery_Response__TYPE_NAME, 42, 42},
    },
    {NULL, 0, 0},
  },
};

static rosidl_runtime_c__type_description__IndividualTypeDescription octomap_msgs__srv__BoundingBoxQuery_Event__REFERENCED_TYPE_DESCRIPTIONS[] = {
  {
    {builtin_interfaces__msg__Time__TYPE_NAME, 27, 27},
    {NULL, 0, 0},
  },
  {
    {geometry_msgs__msg__Point__TYPE_NAME, 23, 23},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery_Request__TYPE_NAME, 41, 41},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__BoundingBoxQuery_Response__TYPE_NAME, 42, 42},
    {NULL, 0, 0},
  },
  {
    {service_msgs__msg__ServiceEventInfo__TYPE_NAME, 33, 33},
    {NULL, 0, 0},
  },
};

const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__BoundingBoxQuery_Event__get_type_description(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static bool constructed = false;
  static const rosidl_runtime_c__type_description__TypeDescription description = {
    {
      {octomap_msgs__srv__BoundingBoxQuery_Event__TYPE_NAME, 39, 39},
      {octomap_msgs__srv__BoundingBoxQuery_Event__FIELDS, 3, 3},
    },
    {octomap_msgs__srv__BoundingBoxQuery_Event__REFERENCED_TYPE_DESCRIPTIONS, 5, 5},
  };
  if (!constructed) {
    assert(0 == memcmp(&builtin_interfaces__msg__Time__EXPECTED_HASH, builtin_interfaces__msg__Time__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[0].fields = builtin_interfaces__msg__Time__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&geometry_msgs__msg__Point__EXPECTED_HASH, geometry_msgs__msg__Point__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[1].fields = geometry_msgs__msg__Point__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[2].fields = octomap_msgs__srv__BoundingBoxQuery_Request__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[3].fields = octomap_msgs__srv__BoundingBoxQuery_Response__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&service_msgs__msg__ServiceEventInfo__EXPECTED_HASH, service_msgs__msg__ServiceEventInfo__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[4].fields = service_msgs__msg__ServiceEventInfo__get_type_description(NULL)->type_description.fields;
    constructed = true;
  }
  return &description;
}

static char toplevel_type_raw_source[] =
  "# Clear a region specified by a global axis-aligned bounding box in stored OctoMap\n"
  "\n"
  "# minimum corner point of axis-aligned bounding box in global frame\n"
  "geometry_msgs/Point min\n"
  "# maximum corner point of axis-aligned bounding box in global frame\n"
  "geometry_msgs/Point max\n"
  "---\n"
  "";

static char srv_encoding[] = "srv";
static char implicit_encoding[] = "implicit";

// Define all individual source functions

const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__BoundingBoxQuery__get_individual_type_description_source(
  const rosidl_service_type_support_t * type_support)
{
  (void)type_support;
  static const rosidl_runtime_c__type_description__TypeSource source = {
    {octomap_msgs__srv__BoundingBoxQuery__TYPE_NAME, 33, 33},
    {srv_encoding, 3, 3},
    {toplevel_type_raw_source, 273, 273},
  };
  return &source;
}

const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__BoundingBoxQuery_Request__get_individual_type_description_source(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static const rosidl_runtime_c__type_description__TypeSource source = {
    {octomap_msgs__srv__BoundingBoxQuery_Request__TYPE_NAME, 41, 41},
    {implicit_encoding, 8, 8},
    {NULL, 0, 0},
  };
  return &source;
}

const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__BoundingBoxQuery_Response__get_individual_type_description_source(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static const rosidl_runtime_c__type_description__TypeSource source = {
    {octomap_msgs__srv__BoundingBoxQuery_Response__TYPE_NAME, 42, 42},
    {implicit_encoding, 8, 8},
    {NULL, 0, 0},
  };
  return &source;
}

const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__BoundingBoxQuery_Event__get_individual_type_description_source(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static const rosidl_runtime_c__type_description__TypeSource source = {
    {octomap_msgs__srv__BoundingBoxQuery_Event__TYPE_NAME, 39, 39},
    {implicit_encoding, 8, 8},
    {NULL, 0, 0},
  };
  return &source;
}

const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__BoundingBoxQuery__get_type_description_sources(
  const rosidl_service_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_runtime_c__type_description__TypeSource sources[7];
  static const rosidl_runtime_c__type_description__TypeSource__Sequence source_sequence = {sources, 7, 7};
  static bool constructed = false;
  if (!constructed) {
    sources[0] = *octomap_msgs__srv__BoundingBoxQuery__get_individual_type_description_source(NULL),
    sources[1] = *builtin_interfaces__msg__Time__get_individual_type_description_source(NULL);
    sources[2] = *geometry_msgs__msg__Point__get_individual_type_description_source(NULL);
    sources[3] = *octomap_msgs__srv__BoundingBoxQuery_Event__get_individual_type_description_source(NULL);
    sources[4] = *octomap_msgs__srv__BoundingBoxQuery_Request__get_individual_type_description_source(NULL);
    sources[5] = *octomap_msgs__srv__BoundingBoxQuery_Response__get_individual_type_description_source(NULL);
    sources[6] = *service_msgs__msg__ServiceEventInfo__get_individual_type_description_source(NULL);
    constructed = true;
  }
  return &source_sequence;
}

const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__BoundingBoxQuery_Request__get_type_description_sources(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_runtime_c__type_description__TypeSource sources[2];
  static const rosidl_runtime_c__type_description__TypeSource__Sequence source_sequence = {sources, 2, 2};
  static bool constructed = false;
  if (!constructed) {
    sources[0] = *octomap_msgs__srv__BoundingBoxQuery_Request__get_individual_type_description_source(NULL),
    sources[1] = *geometry_msgs__msg__Point__get_individual_type_description_source(NULL);
    constructed = true;
  }
  return &source_sequence;
}

const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__BoundingBoxQuery_Response__get_type_description_sources(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_runtime_c__type_description__TypeSource sources[1];
  static const rosidl_runtime_c__type_description__TypeSource__Sequence source_sequence = {sources, 1, 1};
  static bool constructed = false;
  if (!constructed) {
    sources[0] = *octomap_msgs__srv__BoundingBoxQuery_Response__get_individual_type_description_source(NULL),
    constructed = true;
  }
  return &source_sequence;
}

const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__BoundingBoxQuery_Event__get_type_description_sources(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_runtime_c__type_description__TypeSource sources[6];
  static const rosidl_runtime_c__type_description__TypeSource__Sequence source_sequence = {sources, 6, 6};
  static bool constructed = false;
  if (!constructed) {
    sources[0] = *octomap_msgs__srv__BoundingBoxQuery_Event__get_individual_type_description_source(NULL),
    sources[1] = *builtin_interfaces__msg__Time__get_individual_type_description_source(NULL);
    sources[2] = *geometry_msgs__msg__Point__get_individual_type_description_source(NULL);
    sources[3] = *octomap_msgs__srv__BoundingBoxQuery_Request__get_individual_type_description_source(NULL);
    sources[4] = *octomap_msgs__srv__BoundingBoxQuery_Response__get_individual_type_description_source(NULL);
    sources[5] = *service_msgs__msg__ServiceEventInfo__get_individual_type_description_source(NULL);
    constructed = true;
  }
  return &source_sequence;
}
