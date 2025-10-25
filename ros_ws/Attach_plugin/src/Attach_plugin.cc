#include <iostream>

#include <gz/sim/Model.hh>
#include <gz/sim/EntityComponentManager.hh>
#include <gz/sim/System.hh>
#include <gz/plugin/Register.hh>
#include <gz/transport/Node.hh>
#include <gz/msgs/stringmsg.pb.h>

#include <gz/sim/components/Pose.hh>
#include <gz/math/Pose3.hh>
#include <gz/sim/components/Model.hh>
#include <gz/sim/components/Name.hh>
#include <gz/sim/components/Link.hh>


using namespace gz;
using namespace gz::sim;
using namespace gz::sim::components;

namespace Attach_plugin_namespace
{
  class Attach_plugin:
    public gz::sim::System,
    public gz::sim::ISystemUpdate,
    public gz::sim::ISystemConfigure
  {
    public: Attach_plugin() = default;

    private: gz::transport::Node node;
    private: gz::sim::Model model;
    private: gz::sim::Entity entity;
    private: gz::math::Pose3d targetPose;
    private: std::string modelName;
    private: gz::sim::Entity droneEntity{gz::sim::kNullEntity};
    private: gz::sim::Entity baseLinkEntity{gz::sim::kNullEntity};
    private: int attach;



    
    public: void Configure(const gz::sim::Entity &_entity,
                           const std::shared_ptr<const sdf::Element> &,
                           gz::sim::EntityComponentManager &_ecm,
                           gz::sim::EventManager &) override
    {
      std::cout << "[Attach_plugin] Subscribing to /Attach" << std::endl;

      // Subscribe to a topic
      this->node.Subscribe("/Attach", &Attach_plugin::OnMsg, this);

      // Saves the pointer to the model and his entity
      this->model = gz::sim::Model(_entity);
      this->entity = _entity;
      attach=-1; // -1: do nothing, 1: attach the box to the drone, 0: detach the box (make it fall) 
    }


    private: void OnMsg(const gz::msgs::StringMsg &msg)
    {
      std::cout << "[Attach_plugin] Received message: " << msg.data() << std::endl;
      if(msg.data() == "attach")
        attach=1;
      else if (msg.data() == "detach")
        attach=0;
    }



    public: void Update(const gz::sim::UpdateInfo &_info, gz::sim::EntityComponentManager &_ecm) override
    {
      
      if (droneEntity == kNullEntity)
      {
        // Gets the pointer to the model of the drone
        _ecm.Each<components::Model, components::Name>(
          [&](const Entity &entityIter,
              const components::Model *,
              const components::Name *name) -> bool
          {
            if (name->Data() == "x500_lidar_2d_0")
            {
              droneEntity = entityIter;
              return false;
            }
            return true;
          });
      }
      else if(attach==1) // Places frame by frame the box under the drone
      {
        auto *pose_drone = _ecm.Component<components::Pose>(droneEntity);
        auto poseToSet = pose_drone->Data(); 
        gz::math::Pose3d offset(0.0, 0.0, -0.3, 0.0, 0.0, 0.0);  // x, y, z, roll, pitch, yaw
        this->targetPose = poseToSet + offset;

        // Checks if the Pose component exists
        auto poseComp = _ecm.Component<gz::sim::components::Pose>(this->entity);

        if (poseComp)
        {
          // If Pose component exists, edits it
          _ecm.SetComponentData<gz::sim::components::Pose>(this->entity, this->targetPose);
        }
        else
        {
          // If Pose component doesn't exist, creates it
          _ecm.CreateComponent(this->entity, gz::sim::components::Pose(this->targetPose));
        }
        
        // Notifies the ecm that the Pose component has changed
        _ecm.SetChanged(this->entity, components::Pose::typeId, ComponentState::OneTimeChange);
      }
      else if (attach == 0) // Moves the box on the ground right under the drone
      {
        auto *pose_drone = _ecm.Component<components::Pose>(droneEntity);
        auto poseToSet = pose_drone->Data();
        gz::math::Pose3d targetPose(poseToSet.Pos().X(), poseToSet.Pos().Y(), 0.25, poseToSet.Rot().Roll(), poseToSet.Rot().Pitch(), poseToSet.Rot().Yaw());

        auto poseComp = _ecm.Component<gz::sim::components::Pose>(this->entity);

        if (poseComp)
        {
          // If Pose component exists, edits it
          _ecm.SetComponentData<gz::sim::components::Pose>(this->entity, targetPose);
        }
        else
        {
          // If Pose component doesn't exist, creates it
          _ecm.CreateComponent(this->entity, gz::sim::components::Pose(targetPose));
        }
        
        // Notifies the ecm that the Pose component has changed
        _ecm.SetChanged(this->entity, components::Pose::typeId, ComponentState::OneTimeChange);

        attach=-1; // Leave the box where it is
      }
    }
  };
}

// Plugin registration macro
GZ_ADD_PLUGIN(
  Attach_plugin_namespace::Attach_plugin,
  gz::sim::System,
  gz::sim::ISystemUpdate,
  gz::sim::ISystemConfigure
)
