#!/usr/bin/env python3

import rclpy
import numpy as np
import math

from rclpy.node import Node
from rclpy.qos import QoSProfile, ReliabilityPolicy, HistoryPolicy, DurabilityPolicy
from px4_msgs.msg import OffboardControlMode, TrajectorySetpoint, VehicleCommand, VehicleLocalPosition, VehicleStatus
from std_msgs.msg import String, Float32MultiArray
import time


class OffboardControl(Node):
    """Node for controlling a vehicle in offboard mode."""

    def __init__(self) -> None:
        super().__init__('offboard_control_takeoff_and_land')

        qos_profile_drone = QoSProfile(
            reliability=ReliabilityPolicy.BEST_EFFORT,
            durability=DurabilityPolicy.TRANSIENT_LOCAL,
            history=HistoryPolicy.KEEP_LAST,
            depth=1
        )
        
        qos_profile_attach = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            durability=DurabilityPolicy.VOLATILE,
            history=HistoryPolicy.KEEP_LAST,
            depth=10
        )

        # Create publishers
        self.offboard_control_mode_publisher = self.create_publisher(OffboardControlMode, '/fmu/in/offboard_control_mode', qos_profile_drone)
        self.trajectory_setpoint_publisher = self.create_publisher(TrajectorySetpoint, '/fmu/in/trajectory_setpoint', qos_profile_drone)
        self.vehicle_command_publisher = self.create_publisher(VehicleCommand, '/fmu/in/vehicle_command', qos_profile_drone)
        self.Attach_publisher = self.create_publisher(String, '/Attach', qos_profile_attach)
        self.Matlab_publisher = self.create_publisher(Float32MultiArray, '/Matlab_path_request', 10)


        # Create subscribers
        self.vehicle_local_position_subscriber = self.create_subscription(VehicleLocalPosition, '/fmu/out/vehicle_local_position_v1', self.vehicle_local_position_callback, qos_profile_drone)
        self.vehicle_status_subscriber = self.create_subscription(VehicleStatus, '/fmu/out/vehicle_status_v1', self.vehicle_status_callback, qos_profile_drone)
        self.Matlab_subscriber = self.create_subscription(Float32MultiArray, '/Matlab_path_reply', self.matlab_reply_callback, 10)

        self.vehicle_local_position = VehicleLocalPosition()
        self.vehicle_status = VehicleStatus()

        self.path_phase = 1 # 1: execute path 1, 2: execute path 2, 3: execute path 3 , 4: attach the box, 5: detach the box
        self.path_index = 0 # Counter for path step
        self.armed = False
        self.target1_z = 1.0 # Desired height for attach/detach
        self.path_received=False

        # Creation of the request path message
        msg = Float32MultiArray()

        # Path from start position to box position
        startPose1 = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0]
        goalPose1 = [15.0, -9.0, 2.0, 0.0, 0.0, 0.0, 1.0]
        
        # Path from box position to release position
        startPose2 = [15.0, -9.0, 2.0, 0.0, 0.0, 0.0, 1.0]
        goalPose2 = [21.0, 11.0, 2.0, 1.0, 0.0, 0.0, 0.0]

        # Path from release position to start position
        startPose3 = [21.0, 11.0, 2.0, 1.0, 0.0, 0.0, 0.0]
        goalPose3 = [0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0]

        # Concatenate target poses
        msg.data = startPose1 + goalPose1 + startPose2 + goalPose2 + startPose3 + goalPose3
        self.Matlab_publisher.publish(msg)
        self.get_logger().info("Path request sent")

        self.timer = self.create_timer(0.05, self.timer_callback)


    def vehicle_local_position_callback(self, vehicle_local_position):
        self.vehicle_local_position = vehicle_local_position

    def vehicle_status_callback(self, vehicle_status):
        self.vehicle_status = vehicle_status

    def arm(self):
        self.publish_vehicle_command(VehicleCommand.VEHICLE_CMD_COMPONENT_ARM_DISARM, param1=1.0)
        self.get_logger().info('Arm command sent')

    def engage_offboard_mode(self):
        self.publish_vehicle_command(VehicleCommand.VEHICLE_CMD_DO_SET_MODE, param1=1.0, param2=6.0)
        self.get_logger().info("Switching to offboard mode")

    def publish_offboard_control_heartbeat_signal(self):
        msg = OffboardControlMode()
        msg.position = True
        msg.timestamp = int(self.get_clock().now().nanoseconds / 1000)
        self.offboard_control_mode_publisher.publish(msg)

    def publish_position_setpoint(self, x: float, y: float, z: float, yaw: float):
        msg = TrajectorySetpoint()
        msg.position = [x, y, z]
        msg.yaw = yaw
        msg.timestamp = int(self.get_clock().now().nanoseconds / 1000)
        self.trajectory_setpoint_publisher.publish(msg)

    def publish_vehicle_command(self, command, **params) -> None:
        msg = VehicleCommand()
        msg.command = command
        msg.param1 = params.get("param1", 0.0)
        msg.param2 = params.get("param2", 0.0)
        msg.param3 = params.get("param3", 0.0)
        msg.param4 = params.get("param4", 0.0)
        msg.param5 = params.get("param5", 0.0)
        msg.param6 = params.get("param6", 0.0)
        msg.param7 = params.get("param7", 0.0)
        msg.target_system = 1
        msg.target_component = 1
        msg.source_system = 1
        msg.source_component = 1
        msg.from_external = True
        msg.timestamp = int(self.get_clock().now().nanoseconds / 1000)
        self.vehicle_command_publisher.publish(msg)


    def matlab_reply_callback(self, msg):
        num_paths=int(len(msg.data)/4/1000)
        self.get_logger().info(f"Numero path ricevuti: {[num_paths]}")
        waypoints_reshaped = np.array(msg.data)
        waypoints = waypoints_reshaped.reshape((int(len(msg.data)/4), 4))
        self.paths = np.zeros((num_paths, 1000,4), dtype=float)
        
        # Fill paths data structure
        for i in range(num_paths):
            self.paths[i] = waypoints[1000*i:1000*(i+1), :]
        self.path_received=True



    def timer_callback(self) -> None:
        self.publish_offboard_control_heartbeat_signal()
        self.position = np.array([self.vehicle_local_position.y, self.vehicle_local_position.x, -self.vehicle_local_position.z])
        
        if self.path_received==True:
            
            if self.armed == False:
                self.engage_offboard_mode()
                self.arm()
                self.armed=True

            else:
                if self.path_phase <=3:

                    # Find the next step of the path so that the distance between drone and path step is at least 50 cm
                    while (math.dist(self.position, self.paths[self.path_phase -1] [self.path_index][:3]) < 0.5
                        and self.path_index < len(self.paths[self.path_phase -1])-1):
                        
                        self.path_index += 1

                    # Publish setpoint
                    self.target = self.paths[self.path_phase -1] [self.path_index]
                    self.yaw = self.target[3]

                    # FLU->FDR => zFDR = -zFLU, yawFDR = yawFLU
                    self.publish_position_setpoint(self.target[1], self.target[0], -self.target[2], -self.yaw)

                    if(self.path_index == len(self.paths[self.path_phase -1])-1):
                        # 1 -> 4 (attach the box), 2 -> 5 (detach the box)
                        if (self.path_phase==1):
                            self.path_phase = 4
                        elif (self.path_phase==2):
                            self.path_phase = 5 
                
                else:
                    # Setpoint = last path step pose with z coordinate changed
                    self.target[2] = self.target1_z

                    # FLU->FDR => zFDR = -zFLU, yawFDR = yawFLU
                    self.publish_position_setpoint(self.target[1], self.target[0], -self.target1_z , -self.yaw)
                    
                    # se la distanza è > 50cm continua a pubblicare questo target
                    # If the distance between the drone and the target position is greater than 50 cm
                    # keep publishing the target
                    # Else attach/detach the box and change path_phase
                    if math.dist(self.position, self.target[:3]) < 0.4: 
                        if self.path_phase == 4:
                            msg = String()
                            msg.data = "attach"
                            self.Attach_publisher.publish(msg)
                            self.path_phase = 2
                            self.path_index = 0
                        elif self.path_phase == 5:
                            msg = String()
                            msg.data = "detach"
                            self.Attach_publisher.publish(msg)
                            self.path_phase = 3
                            self.path_index = 0

def main(args=None) -> None:
    print('Starting offboard control node...')
    rclpy.init(args=args)
    offboard_control = OffboardControl()
    rclpy.spin(offboard_control)
    offboard_control.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(e)