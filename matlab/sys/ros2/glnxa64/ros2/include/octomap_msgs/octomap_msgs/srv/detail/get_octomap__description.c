// generated from rosidl_generator_c/resource/idl__description.c.em
// with input from octomap_msgs:srv/GetOctomap.idl
// generated code does not contain a copyright notice

#include "octomap_msgs/srv/detail/get_octomap__functions.h"

ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__GetOctomap__get_type_hash(
  const rosidl_service_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_type_hash_t hash = {1, {
      0xc4, 0x3f, 0x2c, 0xeb, 0x83, 0x5f, 0x79, 0x7f,
      0x3d, 0x2a, 0x2c, 0x3d, 0x90, 0x00, 0xe4, 0x69,
      0x12, 0x07, 0xd8, 0xc7, 0xbf, 0xb4, 0x43, 0x11,
      0x9b, 0x4e, 0x90, 0xda, 0xaa, 0xbb, 0x5d, 0x6c,
    }};
  return &hash;
}

ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__GetOctomap_Request__get_type_hash(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_type_hash_t hash = {1, {
      0xcd, 0x35, 0xdf, 0x88, 0xd5, 0xef, 0xc7, 0x17,
      0xa0, 0x1b, 0xcc, 0xa3, 0x52, 0x89, 0xd9, 0xbb,
      0x1e, 0xa7, 0x09, 0x9e, 0xc0, 0x81, 0xcb, 0x9a,
      0xe6, 0xc2, 0x82, 0xc2, 0x69, 0xd7, 0xfa, 0x59,
    }};
  return &hash;
}

ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__GetOctomap_Response__get_type_hash(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_type_hash_t hash = {1, {
      0x87, 0x4a, 0x18, 0xc1, 0x90, 0x9a, 0x06, 0x4d,
      0x2d, 0xbf, 0x20, 0x7a, 0x8e, 0x4d, 0xe6, 0xcc,
      0xc8, 0xd7, 0xd3, 0xd9, 0x3e, 0xdc, 0xe2, 0xac,
      0x4d, 0x42, 0x05, 0xf9, 0xdf, 0x04, 0x95, 0xdb,
    }};
  return &hash;
}

ROSIDL_GENERATOR_C_PUBLIC_octomap_msgs
const rosidl_type_hash_t *
octomap_msgs__srv__GetOctomap_Event__get_type_hash(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_type_hash_t hash = {1, {
      0x93, 0x47, 0x72, 0x0b, 0xa6, 0xab, 0xc6, 0x4c,
      0x1a, 0x3d, 0x6b, 0x36, 0x00, 0x84, 0x81, 0x8c,
      0x9a, 0x10, 0x79, 0x3d, 0x28, 0x87, 0x70, 0xb8,
      0xf3, 0xaa, 0xdf, 0xc0, 0xf7, 0x88, 0xc5, 0xb4,
    }};
  return &hash;
}

#include <assert.h>
#include <string.h>

// Include directives for referenced types
#include "service_msgs/msg/detail/service_event_info__functions.h"
#include "builtin_interfaces/msg/detail/time__functions.h"
#include "octomap_msgs/msg/detail/octomap__functions.h"
#include "std_msgs/msg/detail/header__functions.h"

// Hashes for external referenced types
#ifndef NDEBUG
static const rosidl_type_hash_t builtin_interfaces__msg__Time__EXPECTED_HASH = {1, {
    0xb1, 0x06, 0x23, 0x5e, 0x25, 0xa4, 0xc5, 0xed,
    0x35, 0x09, 0x8a, 0xa0, 0xa6, 0x1a, 0x3e, 0xe9,
    0xc9, 0xb1, 0x8d, 0x19, 0x7f, 0x39, 0x8b, 0x0e,
    0x42, 0x06, 0xce, 0xa9, 0xac, 0xf9, 0xc1, 0x97,
  }};
static const rosidl_type_hash_t octomap_msgs__msg__Octomap__EXPECTED_HASH = {1, {
    0x98, 0x91, 0xa1, 0x9a, 0x05, 0xb7, 0x0e, 0xc2,
    0x0a, 0xa8, 0xf4, 0x5d, 0xb3, 0xf8, 0x30, 0x0b,
    0x9a, 0xb8, 0x0a, 0xff, 0xf3, 0x2c, 0x61, 0xc5,
    0x49, 0xd2, 0x50, 0x87, 0xda, 0x96, 0x25, 0xb0,
  }};
static const rosidl_type_hash_t service_msgs__msg__ServiceEventInfo__EXPECTED_HASH = {1, {
    0x41, 0xbc, 0xbb, 0xe0, 0x7a, 0x75, 0xc9, 0xb5,
    0x2b, 0xc9, 0x6b, 0xfd, 0x5c, 0x24, 0xd7, 0xf0,
    0xfc, 0x0a, 0x08, 0xc0, 0xcb, 0x79, 0x21, 0xb3,
    0x37, 0x3c, 0x57, 0x32, 0x34, 0x5a, 0x6f, 0x45,
  }};
static const rosidl_type_hash_t std_msgs__msg__Header__EXPECTED_HASH = {1, {
    0xf4, 0x9f, 0xb3, 0xae, 0x2c, 0xf0, 0x70, 0xf7,
    0x93, 0x64, 0x5f, 0xf7, 0x49, 0x68, 0x3a, 0xc6,
    0xb0, 0x62, 0x03, 0xe4, 0x1c, 0x89, 0x1e, 0x17,
    0x70, 0x1b, 0x1c, 0xb5, 0x97, 0xce, 0x6a, 0x01,
  }};
#endif

static char octomap_msgs__srv__GetOctomap__TYPE_NAME[] = "octomap_msgs/srv/GetOctomap";
static char builtin_interfaces__msg__Time__TYPE_NAME[] = "builtin_interfaces/msg/Time";
static char octomap_msgs__msg__Octomap__TYPE_NAME[] = "octomap_msgs/msg/Octomap";
static char octomap_msgs__srv__GetOctomap_Event__TYPE_NAME[] = "octomap_msgs/srv/GetOctomap_Event";
static char octomap_msgs__srv__GetOctomap_Request__TYPE_NAME[] = "octomap_msgs/srv/GetOctomap_Request";
static char octomap_msgs__srv__GetOctomap_Response__TYPE_NAME[] = "octomap_msgs/srv/GetOctomap_Response";
static char service_msgs__msg__ServiceEventInfo__TYPE_NAME[] = "service_msgs/msg/ServiceEventInfo";
static char std_msgs__msg__Header__TYPE_NAME[] = "std_msgs/msg/Header";

// Define type names, field names, and default values
static char octomap_msgs__srv__GetOctomap__FIELD_NAME__request_message[] = "request_message";
static char octomap_msgs__srv__GetOctomap__FIELD_NAME__response_message[] = "response_message";
static char octomap_msgs__srv__GetOctomap__FIELD_NAME__event_message[] = "event_message";

static rosidl_runtime_c__type_description__Field octomap_msgs__srv__GetOctomap__FIELDS[] = {
  {
    {octomap_msgs__srv__GetOctomap__FIELD_NAME__request_message, 15, 15},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {octomap_msgs__srv__GetOctomap_Request__TYPE_NAME, 35, 35},
    },
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__GetOctomap__FIELD_NAME__response_message, 16, 16},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {octomap_msgs__srv__GetOctomap_Response__TYPE_NAME, 36, 36},
    },
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__GetOctomap__FIELD_NAME__event_message, 13, 13},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {octomap_msgs__srv__GetOctomap_Event__TYPE_NAME, 33, 33},
    },
    {NULL, 0, 0},
  },
};

static rosidl_runtime_c__type_description__IndividualTypeDescription octomap_msgs__srv__GetOctomap__REFERENCED_TYPE_DESCRIPTIONS[] = {
  {
    {builtin_interfaces__msg__Time__TYPE_NAME, 27, 27},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__msg__Octomap__TYPE_NAME, 24, 24},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__GetOctomap_Event__TYPE_NAME, 33, 33},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__GetOctomap_Request__TYPE_NAME, 35, 35},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__GetOctomap_Response__TYPE_NAME, 36, 36},
    {NULL, 0, 0},
  },
  {
    {service_msgs__msg__ServiceEventInfo__TYPE_NAME, 33, 33},
    {NULL, 0, 0},
  },
  {
    {std_msgs__msg__Header__TYPE_NAME, 19, 19},
    {NULL, 0, 0},
  },
};

const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__GetOctomap__get_type_description(
  const rosidl_service_type_support_t * type_support)
{
  (void)type_support;
  static bool constructed = false;
  static const rosidl_runtime_c__type_description__TypeDescription description = {
    {
      {octomap_msgs__srv__GetOctomap__TYPE_NAME, 27, 27},
      {octomap_msgs__srv__GetOctomap__FIELDS, 3, 3},
    },
    {octomap_msgs__srv__GetOctomap__REFERENCED_TYPE_DESCRIPTIONS, 7, 7},
  };
  if (!constructed) {
    assert(0 == memcmp(&builtin_interfaces__msg__Time__EXPECTED_HASH, builtin_interfaces__msg__Time__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[0].fields = builtin_interfaces__msg__Time__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&octomap_msgs__msg__Octomap__EXPECTED_HASH, octomap_msgs__msg__Octomap__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[1].fields = octomap_msgs__msg__Octomap__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[2].fields = octomap_msgs__srv__GetOctomap_Event__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[3].fields = octomap_msgs__srv__GetOctomap_Request__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[4].fields = octomap_msgs__srv__GetOctomap_Response__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&service_msgs__msg__ServiceEventInfo__EXPECTED_HASH, service_msgs__msg__ServiceEventInfo__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[5].fields = service_msgs__msg__ServiceEventInfo__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&std_msgs__msg__Header__EXPECTED_HASH, std_msgs__msg__Header__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[6].fields = std_msgs__msg__Header__get_type_description(NULL)->type_description.fields;
    constructed = true;
  }
  return &description;
}
// Define type names, field names, and default values
static char octomap_msgs__srv__GetOctomap_Request__FIELD_NAME__structure_needs_at_least_one_member[] = "structure_needs_at_least_one_member";

static rosidl_runtime_c__type_description__Field octomap_msgs__srv__GetOctomap_Request__FIELDS[] = {
  {
    {octomap_msgs__srv__GetOctomap_Request__FIELD_NAME__structure_needs_at_least_one_member, 35, 35},
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
octomap_msgs__srv__GetOctomap_Request__get_type_description(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static bool constructed = false;
  static const rosidl_runtime_c__type_description__TypeDescription description = {
    {
      {octomap_msgs__srv__GetOctomap_Request__TYPE_NAME, 35, 35},
      {octomap_msgs__srv__GetOctomap_Request__FIELDS, 1, 1},
    },
    {NULL, 0, 0},
  };
  if (!constructed) {
    constructed = true;
  }
  return &description;
}
// Define type names, field names, and default values
static char octomap_msgs__srv__GetOctomap_Response__FIELD_NAME__map[] = "map";

static rosidl_runtime_c__type_description__Field octomap_msgs__srv__GetOctomap_Response__FIELDS[] = {
  {
    {octomap_msgs__srv__GetOctomap_Response__FIELD_NAME__map, 3, 3},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {octomap_msgs__msg__Octomap__TYPE_NAME, 24, 24},
    },
    {NULL, 0, 0},
  },
};

static rosidl_runtime_c__type_description__IndividualTypeDescription octomap_msgs__srv__GetOctomap_Response__REFERENCED_TYPE_DESCRIPTIONS[] = {
  {
    {builtin_interfaces__msg__Time__TYPE_NAME, 27, 27},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__msg__Octomap__TYPE_NAME, 24, 24},
    {NULL, 0, 0},
  },
  {
    {std_msgs__msg__Header__TYPE_NAME, 19, 19},
    {NULL, 0, 0},
  },
};

const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__GetOctomap_Response__get_type_description(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static bool constructed = false;
  static const rosidl_runtime_c__type_description__TypeDescription description = {
    {
      {octomap_msgs__srv__GetOctomap_Response__TYPE_NAME, 36, 36},
      {octomap_msgs__srv__GetOctomap_Response__FIELDS, 1, 1},
    },
    {octomap_msgs__srv__GetOctomap_Response__REFERENCED_TYPE_DESCRIPTIONS, 3, 3},
  };
  if (!constructed) {
    assert(0 == memcmp(&builtin_interfaces__msg__Time__EXPECTED_HASH, builtin_interfaces__msg__Time__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[0].fields = builtin_interfaces__msg__Time__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&octomap_msgs__msg__Octomap__EXPECTED_HASH, octomap_msgs__msg__Octomap__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[1].fields = octomap_msgs__msg__Octomap__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&std_msgs__msg__Header__EXPECTED_HASH, std_msgs__msg__Header__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[2].fields = std_msgs__msg__Header__get_type_description(NULL)->type_description.fields;
    constructed = true;
  }
  return &description;
}
// Define type names, field names, and default values
static char octomap_msgs__srv__GetOctomap_Event__FIELD_NAME__info[] = "info";
static char octomap_msgs__srv__GetOctomap_Event__FIELD_NAME__request[] = "request";
static char octomap_msgs__srv__GetOctomap_Event__FIELD_NAME__response[] = "response";

static rosidl_runtime_c__type_description__Field octomap_msgs__srv__GetOctomap_Event__FIELDS[] = {
  {
    {octomap_msgs__srv__GetOctomap_Event__FIELD_NAME__info, 4, 4},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE,
      0,
      0,
      {service_msgs__msg__ServiceEventInfo__TYPE_NAME, 33, 33},
    },
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__GetOctomap_Event__FIELD_NAME__request, 7, 7},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE_BOUNDED_SEQUENCE,
      1,
      0,
      {octomap_msgs__srv__GetOctomap_Request__TYPE_NAME, 35, 35},
    },
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__GetOctomap_Event__FIELD_NAME__response, 8, 8},
    {
      rosidl_runtime_c__type_description__FieldType__FIELD_TYPE_NESTED_TYPE_BOUNDED_SEQUENCE,
      1,
      0,
      {octomap_msgs__srv__GetOctomap_Response__TYPE_NAME, 36, 36},
    },
    {NULL, 0, 0},
  },
};

static rosidl_runtime_c__type_description__IndividualTypeDescription octomap_msgs__srv__GetOctomap_Event__REFERENCED_TYPE_DESCRIPTIONS[] = {
  {
    {builtin_interfaces__msg__Time__TYPE_NAME, 27, 27},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__msg__Octomap__TYPE_NAME, 24, 24},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__GetOctomap_Request__TYPE_NAME, 35, 35},
    {NULL, 0, 0},
  },
  {
    {octomap_msgs__srv__GetOctomap_Response__TYPE_NAME, 36, 36},
    {NULL, 0, 0},
  },
  {
    {service_msgs__msg__ServiceEventInfo__TYPE_NAME, 33, 33},
    {NULL, 0, 0},
  },
  {
    {std_msgs__msg__Header__TYPE_NAME, 19, 19},
    {NULL, 0, 0},
  },
};

const rosidl_runtime_c__type_description__TypeDescription *
octomap_msgs__srv__GetOctomap_Event__get_type_description(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static bool constructed = false;
  static const rosidl_runtime_c__type_description__TypeDescription description = {
    {
      {octomap_msgs__srv__GetOctomap_Event__TYPE_NAME, 33, 33},
      {octomap_msgs__srv__GetOctomap_Event__FIELDS, 3, 3},
    },
    {octomap_msgs__srv__GetOctomap_Event__REFERENCED_TYPE_DESCRIPTIONS, 6, 6},
  };
  if (!constructed) {
    assert(0 == memcmp(&builtin_interfaces__msg__Time__EXPECTED_HASH, builtin_interfaces__msg__Time__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[0].fields = builtin_interfaces__msg__Time__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&octomap_msgs__msg__Octomap__EXPECTED_HASH, octomap_msgs__msg__Octomap__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[1].fields = octomap_msgs__msg__Octomap__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[2].fields = octomap_msgs__srv__GetOctomap_Request__get_type_description(NULL)->type_description.fields;
    description.referenced_type_descriptions.data[3].fields = octomap_msgs__srv__GetOctomap_Response__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&service_msgs__msg__ServiceEventInfo__EXPECTED_HASH, service_msgs__msg__ServiceEventInfo__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[4].fields = service_msgs__msg__ServiceEventInfo__get_type_description(NULL)->type_description.fields;
    assert(0 == memcmp(&std_msgs__msg__Header__EXPECTED_HASH, std_msgs__msg__Header__get_type_hash(NULL), sizeof(rosidl_type_hash_t)));
    description.referenced_type_descriptions.data[5].fields = std_msgs__msg__Header__get_type_description(NULL)->type_description.fields;
    constructed = true;
  }
  return &description;
}

static char toplevel_type_raw_source[] =
  "# Get the map as a octomap\n"
  "---\n"
  "octomap_msgs/Octomap map";

static char srv_encoding[] = "srv";
static char implicit_encoding[] = "implicit";

// Define all individual source functions

const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__GetOctomap__get_individual_type_description_source(
  const rosidl_service_type_support_t * type_support)
{
  (void)type_support;
  static const rosidl_runtime_c__type_description__TypeSource source = {
    {octomap_msgs__srv__GetOctomap__TYPE_NAME, 27, 27},
    {srv_encoding, 3, 3},
    {toplevel_type_raw_source, 56, 56},
  };
  return &source;
}

const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__GetOctomap_Request__get_individual_type_description_source(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static const rosidl_runtime_c__type_description__TypeSource source = {
    {octomap_msgs__srv__GetOctomap_Request__TYPE_NAME, 35, 35},
    {implicit_encoding, 8, 8},
    {NULL, 0, 0},
  };
  return &source;
}

const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__GetOctomap_Response__get_individual_type_description_source(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static const rosidl_runtime_c__type_description__TypeSource source = {
    {octomap_msgs__srv__GetOctomap_Response__TYPE_NAME, 36, 36},
    {implicit_encoding, 8, 8},
    {NULL, 0, 0},
  };
  return &source;
}

const rosidl_runtime_c__type_description__TypeSource *
octomap_msgs__srv__GetOctomap_Event__get_individual_type_description_source(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static const rosidl_runtime_c__type_description__TypeSource source = {
    {octomap_msgs__srv__GetOctomap_Event__TYPE_NAME, 33, 33},
    {implicit_encoding, 8, 8},
    {NULL, 0, 0},
  };
  return &source;
}

const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__GetOctomap__get_type_description_sources(
  const rosidl_service_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_runtime_c__type_description__TypeSource sources[8];
  static const rosidl_runtime_c__type_description__TypeSource__Sequence source_sequence = {sources, 8, 8};
  static bool constructed = false;
  if (!constructed) {
    sources[0] = *octomap_msgs__srv__GetOctomap__get_individual_type_description_source(NULL),
    sources[1] = *builtin_interfaces__msg__Time__get_individual_type_description_source(NULL);
    sources[2] = *octomap_msgs__msg__Octomap__get_individual_type_description_source(NULL);
    sources[3] = *octomap_msgs__srv__GetOctomap_Event__get_individual_type_description_source(NULL);
    sources[4] = *octomap_msgs__srv__GetOctomap_Request__get_individual_type_description_source(NULL);
    sources[5] = *octomap_msgs__srv__GetOctomap_Response__get_individual_type_description_source(NULL);
    sources[6] = *service_msgs__msg__ServiceEventInfo__get_individual_type_description_source(NULL);
    sources[7] = *std_msgs__msg__Header__get_individual_type_description_source(NULL);
    constructed = true;
  }
  return &source_sequence;
}

const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__GetOctomap_Request__get_type_description_sources(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_runtime_c__type_description__TypeSource sources[1];
  static const rosidl_runtime_c__type_description__TypeSource__Sequence source_sequence = {sources, 1, 1};
  static bool constructed = false;
  if (!constructed) {
    sources[0] = *octomap_msgs__srv__GetOctomap_Request__get_individual_type_description_source(NULL),
    constructed = true;
  }
  return &source_sequence;
}

const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__GetOctomap_Response__get_type_description_sources(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_runtime_c__type_description__TypeSource sources[4];
  static const rosidl_runtime_c__type_description__TypeSource__Sequence source_sequence = {sources, 4, 4};
  static bool constructed = false;
  if (!constructed) {
    sources[0] = *octomap_msgs__srv__GetOctomap_Response__get_individual_type_description_source(NULL),
    sources[1] = *builtin_interfaces__msg__Time__get_individual_type_description_source(NULL);
    sources[2] = *octomap_msgs__msg__Octomap__get_individual_type_description_source(NULL);
    sources[3] = *std_msgs__msg__Header__get_individual_type_description_source(NULL);
    constructed = true;
  }
  return &source_sequence;
}

const rosidl_runtime_c__type_description__TypeSource__Sequence *
octomap_msgs__srv__GetOctomap_Event__get_type_description_sources(
  const rosidl_message_type_support_t * type_support)
{
  (void)type_support;
  static rosidl_runtime_c__type_description__TypeSource sources[7];
  static const rosidl_runtime_c__type_description__TypeSource__Sequence source_sequence = {sources, 7, 7};
  static bool constructed = false;
  if (!constructed) {
    sources[0] = *octomap_msgs__srv__GetOctomap_Event__get_individual_type_description_source(NULL),
    sources[1] = *builtin_interfaces__msg__Time__get_individual_type_description_source(NULL);
    sources[2] = *octomap_msgs__msg__Octomap__get_individual_type_description_source(NULL);
    sources[3] = *octomap_msgs__srv__GetOctomap_Request__get_individual_type_description_source(NULL);
    sources[4] = *octomap_msgs__srv__GetOctomap_Response__get_individual_type_description_source(NULL);
    sources[5] = *service_msgs__msg__ServiceEventInfo__get_individual_type_description_source(NULL);
    sources[6] = *std_msgs__msg__Header__get_individual_type_description_source(NULL);
    constructed = true;
  }
  return &source_sequence;
}
