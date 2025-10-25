cmake_minimum_required(VERSION 3.10)
project(Attach_plugin)

find_package(gz-cmake3 REQUIRED)
gz_find_package(gz-sim8 REQUIRED)
gz_find_package(gz-plugin2 REQUIRED COMPONENTS register)
gz_find_package(gz-msgs10 REQUIRED)

add_library(Attach_plugin SHARED src/Attach_plugin.cc)

set_property(TARGET Attach_plugin PROPERTY CXX_STANDARD 17)
target_compile_definitions(Attach_plugin PRIVATE GZ_PLUGIN_ENABLE_REGISTER)

target_link_libraries(Attach_plugin
  gz-sim8::gz-sim8
  gz-plugin2::gz-plugin2
)
