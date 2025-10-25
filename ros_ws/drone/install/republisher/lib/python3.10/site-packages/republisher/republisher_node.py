import rclpy
from rclpy.node import Node

from std_msgs.msg import String
from geometry_msgs.msg import PoseStamped
from px4_msgs.msg import VehicleOdometry
import time
import numpy as np

class republisher(Node):

    def __init__(self):
        super().__init__('republisher_node')
        self.subscription = self.create_subscription(
            PoseStamped,
            '/current_pose',
            self.listener_callback,
            10)

        self.publisher = self.create_publisher(
            VehicleOdometry,
            '/fmu/in/vehicle_visual_odometry',
            10
        )
        
        self.get_logger().info('node initialization complete')


    def listener_callback(self, msg):

        odom = VehicleOdometry()
        odom.timestamp = int(msg.header.stamp.sec *1e6 + msg.header.stamp.nanosec*1e-3) # timestamp in ms
        odom.timestamp_sample = odom.timestamp
        odom.pose_frame = 2 #sdr FRD
        odom.velocity_frame = 2
        odom.position_variance = [0.01, 0.01, 0.01]
        odom.orientation_variance = [0.01, 0.01, 0.01]
        odom.velocity_variance= [0.01, 0.01, 0.01]

        odom.quality = 1 # needed to make PX4 trust the SLAM estimation

        # FLU->FDR position conversion
        odom.position = [
            msg.pose.position.x,     # FRD x = FLU x
            -msg.pose.position.y,     # FRD y = FLU y
            -msg.pose.position.z     # FRD z = - FLU z
        ]

        # FLU->FDR quaternion conversion
        q_FLU = [
            msg.pose.orientation.w,
            msg.pose.orientation.x,
            msg.pose.orientation.y,
            msg.pose.orientation.z
        ]
        
        odom.q = [q_FLU[0], q_FLU[1], -q_FLU[2], -q_FLU[3]]  # FRD (w,x,y,z) = FLU (w,x,-y,-z)
        
        # If velocity and angular velocity is not estimated by the SLAM this fields must be zero
        odom.velocity = [0.0, 0.0, 0.0]
        odom.angular_velocity = [0.0, 0.0, 0.0]

        self.publisher.publish(odom)


def main(args=None):
    rclpy.init(args=args)

    republisher_node = republisher()

    rclpy.spin(republisher_node)

    republisher_node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()