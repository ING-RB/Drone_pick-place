#include <iostream>

#include <gz/sim/Model.hh>
#include <gz/sim/EntityComponentManager.hh>
#include <gz/sim/System.hh>
#include <gz/plugin/Register.hh>

namespace example
{
  class HelloModelPlugin:
    public gz::sim::System,
    public gz::sim::ISystemUpdate
  {
    public: HelloModelPlugin() = default;

    public: void Update(const gz::sim::UpdateInfo &_info,
                        gz::sim::EntityComponentManager &_ecm) override
    {
      std::cout << "[HelloModelPlugin] Sim time: "
                << _info.simTime.count() << " ns" << std::endl;
    }
  };
}

// Plugin registration macro
GZ_ADD_PLUGIN(
  example::HelloModelPlugin,
  gz::sim::System,
  gz::sim::ISystemUpdate
)
