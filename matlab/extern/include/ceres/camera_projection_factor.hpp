// Copyright 2022-2024 The MathWorks, Inc.

// This file contains implementations for:
// - factor between an SE(3) Camera and an R3 point
//
// All implementations represent the poses as a single variable and the Jacobians
// are computed through ceres auto-diff.

#include <vector>
#include <unordered_map>
#include <Eigen/Core>
#include <Eigen/Geometry>
#include "ceres/ceres.h"
#include "ceres/rotation.h"
#include <unsupported/Eigen/MatrixFunctions>

#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/cerescodegen_spec.hpp"
    #include "cerescodegen/group_utilities.hpp"
    #include "cerescodegen/custom_local_parameterization.hpp"
    #include "cerescodegen/factor.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy */
    #include "cerescodegen_spec.hpp"
    #include "group_utilities.hpp"
    #include "custom_local_parameterization.hpp"
    #include "factor.hpp"
#endif

#ifndef CAMERA_PROJECTION_FACTOR_HPP
#define CAMERA_PROJECTION_FACTOR_HPP
namespace mw_ceres {

     /** Functor to compute the projection cost between SE3 Camera and R(3) point
         The Jacobians are computed through Ceres auto-diff.*/
    class PinholeCameraSE3Point3ReprojectionCost {
     public:
        /** 
          * \brief Re-projection cost function constructor
          * \param observedPosition double vector storing (u,v) image point observation
          * \param information double vector specifying information matrix in the form [Ixx,0,0,Iyy]
          * \param sensorTform double vector specifying sensor transform from base sensor to current camera in the form [x,y,z,qw,qx,qy,qz]
        */
        PinholeCameraSE3Point3ReprojectionCost(const std::vector<double>& observedPosition,
                          const std::vector<double>& information, const std::vector<double>& sensorTform ) {
            // m_Observed is the observed position of the projection point in camera frame
            m_ObservedXY << observedPosition[0], observedPosition[1];
            m_SqrtInformation = Eigen::Matrix<double, 2, 2, Eigen::RowMajor>(information.data()).llt().matrixL();
            Eigen::Map<const Eigen::Matrix<double, 4, 4>> tform(sensorTform.data());
            m_SensorTransform_q =  tform.block<3,3>(0,0).transpose();
            m_SensorTransform_t = m_SensorTransform_q*tform.block<3,1>(0,3);
            focalL[0] = observedPosition[2];
            focalL[1] = observedPosition[3];
        }

        template <typename T>
        bool operator()(const T* const camera, const T* const pos, T* residuals) const {
            // here camera is the vehicle/robot's camera pose in reference frame,
            //      pos is the point position in reference frame

            // world position of camera
            Eigen::Map<const Eigen::Matrix<T, 3, 1>> pi(camera);
            // world orientation of camera
            Eigen::Map<const Eigen::Quaternion<T>> qi(camera + 3);
            // world position of landmark
            Eigen::Map<const Eigen::Matrix<T, 3, 1>> xi(pos);

            // rotate and translate the point to bring it to  
            // camera frame i from world 
            auto qs = m_SensorTransform_q.cast<T>();
            Eigen::Matrix<T, 3, 1> p = qs*qi.conjugate()*(xi  - pi) + m_SensorTransform_t.cast<T>();
        
            // compute projected image point
            T predicted_x = p[0] / p[2] * focalL[0] ;
            T predicted_y = p[1] / p[2] * focalL[1];
        
            // The error is the difference between the predicted and observed position.
            T r_x = predicted_x - T(m_ObservedXY[0]);
            T r_y = predicted_y - T(m_ObservedXY[1]);

            residuals[0] = r_x*m_SqrtInformation(0,0) + r_y*m_SqrtInformation(1,0);
            residuals[1] = r_x*m_SqrtInformation(0,1) + r_y*m_SqrtInformation(1,1);

            return true;   
        }

    protected:
        Eigen::Vector2d m_ObservedXY;
        Eigen::Matrix<double, 2, 2,  Eigen::RowMajor> m_SqrtInformation;
        Eigen::Quaterniond m_SensorTransform_q;
        Eigen::Matrix<double, 3, 1> m_SensorTransform_t;

        double focalL[2];
    };

    /** This class represents a factor that relates between an camera and an R(3) point
        using PinholeCameraSE3Point3ReprojectionCost as residual cost function */
    class CERESCODEGEN_API FactorCameraSE3AndPointXYZ : public FactorGaussianNoiseModel {
        public:
        FactorCameraSE3AndPointXYZ(std::vector<int> ids) : FactorGaussianNoiseModel(ids, {7, 3}, {VariableType::Pose_SE3, VariableType::Point_XYZ}) {
            m_MeasurementLength = 4;
            m_InfoMatLength = 4;
            m_Measurement = {0.0, 0.0, 0.0, 0.0};
            m_InformationMatrix = std::vector<double>(m_InfoMatLength, 0.0);
            Eigen::Map<Eigen::Matrix<double, 2, 2, Eigen::RowMajor>> mat(m_InformationMatrix.data());
            mat = Eigen::Matrix<double, 2, 2>::Identity();
            m_SensorTransform = std::vector<double>(16, 0.0);
            Eigen::Map<Eigen::Matrix<double, 4, 4, Eigen::RowMajor>> matS(m_SensorTransform.data());
            matS = Eigen::Matrix<double, 4, 4>::Identity();
            lossParameter = -1;
        }

        ceres::CostFunction* createFactorCostFcn() const override {
            return new ceres::AutoDiffCostFunction<PinholeCameraSE3Point3ReprojectionCost, 2, 7, 3>(
                new PinholeCameraSE3Point3ReprojectionCost(m_Measurement, m_InformationMatrix, m_SensorTransform));
        }

         ceres::LossFunctionWrapper* createFactorLossFcn() const override {
            if (lossParameter < 0)
                return nullptr;
            else
                return new ceres::LossFunctionWrapper(new ceres::HuberLoss(lossParameter), ceres::TAKE_OWNERSHIP);

        }

        ceres::LocalParameterization* getVariableLocalParameterization(int variableID) override {
            if (m_MapVariableLPTypes.find(variableID)->second == VariableType::Point_XYZ)
                return new ceres::IdentityParameterization(3);
            else
                return new ceres::ProductParameterization( new ceres::IdentityParameterization(3),
                    new ceres::EigenQuaternionParameterization());
        }

        std::vector<double> getDefaultState(int variableID) const override {
            if (m_MapVariableLPTypes.find(variableID)->second == VariableType::Point_XYZ)
                return {0.0, 0.0, 0.0};
            else
                return {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0};
        }

        std::string getVariableTypeString(int variableID) const override {
            return VariableTypeString.at(static_cast<VariableType>(getVariableType(variableID)));
        }

        bool setSensorTransform(const double* sensorTform) {
            m_SensorTransform = std::vector<double>(sensorTform, sensorTform+16);
            return true;
        }

        bool setLossParameter(const double lp){
            lossParameter = lp;
            return true;
        }

        std::vector<double> m_SensorTransform;

        // Loss function parameter used to define the loss function. Most loss functions supported in
		// Ceres only takes one parameter which defines how large residuals are reduced. To create a
		// valid loss function, lossParameter must be positive. Otherwise, no loss function is created.
        double lossParameter;
    };

    /** 
    * \fn Eigen::Matrix<T, 3, 1> projectPointToCamera(const T* pose, const T* point, const T* sensorTransform)
    * \brief Project 3-D point from world to camera frame
    *
    *  Inputs
    *      pose - pointer to pose (x,y,z,qx,qy,qz,qw) of base in world frame
    *      point - pointer to 3-D point (x,y,z) in world frame
    *      sensorTransform - pointer to sensor transform (x,y,z,qx,qy,qz,qw) from base to current camera
    *  Outputs:
    *      pointInCamera - point in camera frame returned as an eigen matrix of size 3-by-1
    */
    template <typename T>
    inline Eigen::Matrix<T, 3, 1> projectPointToCamera(const T* pose, const T* point, const T* sensorTransform){
        return Eigen::Map<const Eigen::Quaternion<T>>(sensorTransform+3) *
                (Eigen::Map<const Eigen::Quaternion<T>>(pose+3).inverse() *
                (Eigen::Map<const Eigen::Matrix<T, 3, 1>>(point) -
                 Eigen::Map<const Eigen::Matrix<T, 3, 1>>(pose))) +
                Eigen::Map<const Eigen::Matrix<T, 3, 1>>(sensorTransform);
    }

    /** 
    * \fn Eigen::Matrix<T, 3, 1> projectPointToCamera(const T* pose, const T* point, const Eigen::Matrix<T, 4, 4, Eigen::RowMajor>& sensorTransform)
    * \brief Project 3-D point from world to camera frame
    *
    *  Inputs
    *      pose - pointer to pose (x,y,z,qx,qy,qz,qw) of base in world frame
    *      point - pointer to 3-D point (x,y,z) in world frame
    *      sensorTransform - sensor transform (Eigen row major matrix of size 4-by-4) from base to current camera
    *  Outputs:
    *      pointInCamera - point in camera frame returned as an eigen matrix of size 3-by-1
    */
    template <typename T>
    inline Eigen::Matrix<T, 3, 1> projectPointToCamera(const T* pose, const T* point,const Eigen::Matrix<T, 4, 4, Eigen::RowMajor>& sensorTransform){
        return sensorTransform.template block<3,3>(0,0) *
                (Eigen::Map<const Eigen::Quaternion<T>>(pose+3).inverse() *
                (Eigen::Map<const Eigen::Matrix<T, 3, 1>>(point) -
                 Eigen::Map<const Eigen::Matrix<T, 3, 1>>(pose))) +
                sensorTransform.template block<3,1>(0,3);
    }

    
    /**
      * \brief Reproject point to image using pinhole camera model with single focal, aspect ratio, principal point and 8 parameter radial-tangential distortion
      * 
      * The intrinsic parameters used in this model are:
      *    - Focal length along X
      *    - Aspect ratio: ratio of Y-Focal to X-Focal
      *    - Principal point along X
      *    - Principal point along Y
      *    - 6 Radial distortion parameters k1, k2, k3, k4, k5, k6
      *    - 2 tangential distortion parameters p1, p2
      *
      * The key differentiator of this pinhole model from the MATLAB 
      * pinhole is the aspect ratio. Instead of focal length along Y (fy)
      * as an intrinsic parameter this model uses an aspect ratio
      * parameter. This allows us to configure pinhole reprojection 
      * to use single focal length by fixing aspect ratio (r) to 1.
      *
      *  \param x : x-coordinate of the 3-D point in camera frame
      *  \param y : y-coordinate of the 3-D point in camera frame
      *  \param z : z-coordinate of the 3-D point in camera frame
      *  \param fx : pointer to focal length along X-axis of camera
      *  \param r : pointer to ratio of focal length along Y and focal length along X (fy/fx). Set this parameter is 1 if the image pixels are square in shape.
      *  \param cx : pointer to principal point along X-axis
      *  \param cy : pointer to principal point along Y-axis
      *  \param k1 : pointer to radial distortion parameter 1
      *  \param k2 : pointer to radial distortion parameter 2
      *  \param k3 : pointer to radial distortion parameter 3
      *  \param k4 : pointer to radial distortion parameter 4
      *  \param k5 : pointer to radial distortion parameter 5
      *  \param k6 : pointer to radial distortion parameter 6
      *  \param p1 : pointer to tangential distortion parameter 1
      *  \param p2 : pointer to tangential distortion parameter 2
      *  \param u - pointer to projected pixel along X-axis
      *  \param v - pointer to projected pixel along Y-axis
      *
      * To understand camera intrinsic parameters look at:
      * https://mathworks.com/help/vision/ug/camera-calibration.html
      *
      * Radial distortion is known to have 3 major configurations:
      *    - Only k1, k2 are in affect and non zero
      *    - Only k1, k2, k3 are in affect and non zero
      *    - All k1, k2, k3, k4, k5, k6 are in affect and non zero
      * k3, …, k6 are only needed for wide-angle lenses
      * https://mathworks.com/help/vision/ref/cameraintrinsics.html#bvhjcpz-1-RadialDistortion
      */
    template <typename T>
    void reprojectPointToImageUsingPinholeCameraModelWithAspectRatio(const T* x, const T* y, const T* z, 
                               const T* fx, const T* r, const T* cx, const T* cy, 
                               const T* k1, const T* k2, const T* k3, const T* k4, const T* k5,const T* k6, 
                               const T* p1, const T* p2, 
                               T* u, T* v) {
        
        // normalize
        *u = (*x)/(*z);
        *v = (*y)/(*z);

        
        // apply distortion
        const T u2 = (*u) * (*u);
        const T uv = (*u) * (*v);
        const T v2 = (*v) * (*v);
        const T r2 = u2 + v2;
        const T r4 = r2 * r2;
        const T r6 = r4 * r2;
        const T radial = (static_cast<T>(1) + ((*k1) * r2) + ((*k2) * r4) + ((*k3) * r6))/(static_cast<T>(1) + ((*k4) * r2) + ((*k5) * r4) + ((*k6) * r6));
        *u = ((*u) * radial) + (static_cast<T>(2) * (*p1) * uv) + ((*p2) * (r2 + static_cast<T>(2) * u2));
        *v = ((*v) * radial) + (static_cast<T>(2) * (*p2) * uv) + ((*p1) * (r2 + static_cast<T>(2) * v2));

        // apply affect of focal length and camera center
        *u = ((*fx) * (*u)) + (*cx);
        *v = ((*fx) * (*r) * (*v)) + (*cy);
    }

    /**
      * \brief Reproject point to image using MATLAB pinhole camera model with radial-tangential distortion
      * 
      * The intrinsic parameters used in this model are:
      *    - Focal length along X
      *    - Focal length along Y
      *    - Principal point along X
      *    - Principal point along Y
      *    - Skew
      *    - 6 Radial distortion parameters k1, k2, k3, k4, k5, k6
      *    - 2 tangential distortion parameters p1, p2
      *
      *  \param x - x-coordinate of the 3-D point in camera frame
      *  \param y - y-coordinate of the 3-D point in camera frame
      *  \param z - z-coordinate of the 3-D point in camera frame
      *  \param fx - pointer to focal length along X-axis of camera
      *  \param fy - pointer to focal length along Y-axis of camera
      *  \param cx - pointer to principal point along X-axis
      *  \param cy - pointer to principal point along Y-axis
      *  \param s - pointer to skew
      *  \param k1 : pointer to radial distortion parameter 1
      *  \param k2 : pointer to radial distortion parameter 2
      *  \param k3 : pointer to radial distortion parameter 3
      *  \param k4 : pointer to radial distortion parameter 4
      *  \param k5 : pointer to radial distortion parameter 5
      *  \param k6 : pointer to radial distortion parameter 6
      *  \param p1 : pointer to tangential distortion parameter 1
      *  \param p2 : pointer to tangential distortion parameter 2
      *  \param u - pointer to projected pixel along X-axis
      *  \param v - pointer to projected pixel along Y-axis
      *
      * To understand camera intrinsic parameters look at:
      * https://mathworks.com/help/vision/ug/camera-calibration.html
      *
      * Radial distortion is known to have 3 major configurations:
      *    - Only k1, k2 are in affect and non zero
      *    - Only k1, k2, k3 are in affect and non zero
      *    - All k1, k2, k3, k4, k5, k6 are in affect and non zero
      * k3, …, k6 are only needed for wide-angle lenses
      * https://mathworks.com/help/vision/ref/cameraintrinsics.html#bvhjcpz-1-RadialDistortion
      *
      */
    template <typename T>
    void reprojectPointToImageUsingPinholeCameraModel(const T* x, const T* y, const T* z, 
                               const T* fx, const T* fy, const T* cx, const T* cy, const T* s,
                               const T* k1, const T* k2, const T* k3, const T* k4, const T* k5,const T* k6, 
                               const T* p1, const T* p2, 
                               T* u, T* v) {
        
        // normalize
        *u = (*x)/(*z);
        *v = (*y)/(*z);

        
        // apply distortion
        const T u2 = (*u) * (*u);
        const T uv = (*u) * (*v);
        const T v2 = (*v) * (*v);
        const T r2 = u2 + v2;
        const T r4 = r2 * r2;
        const T r6 = r4 * r2;
        const T radial = (static_cast<T>(1) + ((*k1) * r2) + ((*k2) * r4) + ((*k3) * r6))/(static_cast<T>(1) + ((*k4) * r2) + ((*k5) * r4) + ((*k6) * r6));
        *u = ((*u) * radial) + (static_cast<T>(2) * (*p1) * uv) + ((*p2) * (r2 + static_cast<T>(2) * u2));
        *v = ((*v) * radial) + (static_cast<T>(2) * (*p2) * uv) + ((*p1) * (r2 + static_cast<T>(2) * v2));

        // apply affect of focal length and camera center
        *u = ((*fx) * (*u)) + (*cx) + ((*s) * (*v));
        *v = ((*fy) * (*v)) + (*cy);
    }

    /** 
      * \brief Functor to compute the projection cost between distorted SE3 camera and R(3) point where the camera intrinsics are tunable. The Jacobians are computed through Ceres auto-diff. 
      */
    class DistortedPinholeCameraReprojectionCost {
     public:
        DistortedPinholeCameraReprojectionCost(const std::vector<double>& imagePoint,
                          const std::vector<double>& information) {
            // m_Observed is the observed position of the projection point in camera frame
            m_ObservedXY << imagePoint[0], imagePoint[1];
            m_SqrtInformation = Eigen::Matrix<double, 2, 2, Eigen::RowMajor>(information.data()).llt().matrixL();
            m_Intrinsics = Eigen::Matrix<double,13,1>::Zero();
            m_SensorTransform = Eigen::Matrix<double, 4, 4, Eigen::RowMajor>::Identity();
        }

        DistortedPinholeCameraReprojectionCost(const std::vector<double>& imagePoint,
                          const std::vector<double>& information, const std::vector<double>& intrinsics) {
            // m_Observed is the observed position of the projection point in camera frame
            m_ObservedXY << imagePoint[0], imagePoint[1];
            m_SqrtInformation = Eigen::Matrix<double, 2, 2, Eigen::RowMajor>(information.data()).llt().matrixL();
            m_Intrinsics = Eigen::Matrix<double, 13, 1>(intrinsics.data());
            m_SensorTransform = Eigen::Matrix<double, 4, 4, Eigen::RowMajor>::Identity();
        }

        DistortedPinholeCameraReprojectionCost(const std::vector<double>& imagePoint,
                          const std::vector<double>& information, const std::vector<double>& intrinsics, const std::vector<double>& sensorTransform) {
            // m_Observed is the observed position of the projection point in camera frame
            m_ObservedXY << imagePoint[0], imagePoint[1];
            m_SqrtInformation = Eigen::Matrix<double, 2, 2, Eigen::RowMajor>(information.data()).llt().matrixL();
            m_SensorTransform = Eigen::Matrix<double, 4, 4, Eigen::RowMajor>(sensorTransform.data());
            m_Intrinsics = Eigen::Matrix<double, 13, 1>(intrinsics.data());
        }

        /**
          * \brief Residual function for pinhole camera model with 8 parameter radial-tangential distortion.
          * \param pose : pointer to pose (x,y,z,qx,qy,qz,qw) of base in world frame
          * \param fx : pointer to focal length along X
          * \param fy : pointer to focal length along Y
          * \param cx : pointer to principal point along X
          * \param cy : pointer to principal point along Y
          * \param s  : pointer to skew parameter
          * \param k1 : pointer to radial distortion parameter 1
          * \param k2 : pointer to radial distortion parameter 2
          * \param k3 : pointer to radial distortion parameter 3
          * \param k4 : pointer to radial distortion parameter 4
          * \param k5 : pointer to radial distortion parameter 5
          * \param k6 : pointer to radial distortion parameter 6
          * \param p1 : pointer to tangential distortion parameter 1
          * \param p2 : pointer to tangential distortion parameter 2
          * \param point : pointer to 3-D point (x,y,z) in world frame
          * \param tform : sensor transform (x,y,z,qx,qy,qz,qw) from base sensor to current camera
          * \param residuals : pointer to residual vector
          *
          * To understand camera intrinsic parameters look at:
          * https://mathworks.com/help/vision/ug/camera-calibration.html
          *
          * Radial distortion is known to have 3 major configurations:
          *    - Only k1, k2 are in affect and non zero
          *    - Only k1, k2, k3 are in affect and non zero
          *    - All k1, k2, k3, k4, k5, k6 are in affect and non zero
          * k3, …, k6 are only needed for wide-angle lenses
          * https://mathworks.com/help/vision/ref/cameraintrinsics.html#bvhjcpz-1-RadialDistortion
          *
          */
        template <typename T>
        bool operator()(const T* const pose, const T* const fx, const T* const fy, const T* const cx, const T* const cy, const T* const s, const T* const k1, const T* const k2, const T* const k3, const T* const k4, const T* const k5, const T* const k6, const T* const p1, const T* const p2, const T* const point, const T* const tform, T* residuals) const {
            // project point in world frame to camera frame
            Eigen::Matrix<T, 3, 1> point3D_in_cam = projectPointToCamera<T>(pose, point, tform);
            // re-project point to image plane
            reprojectPointToImageUsingPinholeCameraModel<T>(&point3D_in_cam[0],
                       &point3D_in_cam[1],
                       &point3D_in_cam[2],
                       fx, fy, cx, cy, s, k1, k2, k3, k4, k5, k6, p1, p2,
                       &residuals[0],
                       &residuals[1]);
            // re-projection residual
            residuals[0] -= static_cast<T>(m_ObservedXY[0]);
            residuals[1] -= static_cast<T>(m_ObservedXY[1]);
            Eigen::Map<Eigen::Matrix<T, 2, 1>> res(residuals);
            res.applyOnTheLeft(m_SqrtInformation.template cast<T>());

            return true;   
        }

        /**
          * \brief Residual function for pinhole camera model with 8 parameter radial-tangential distortion and fixed known sensor transform.
          * \param pose : pointer to pose (x,y,z,qx,qy,qz,qw) of base in world frame
          * \param fx : pointer to focal length along X
          * \param fy : pointer to focal length along Y
          * \param cx : pointer to principal point along X
          * \param cy : pointer to principal point along Y
          * \param s  : pointer to skew parameter
          * \param k1 : pointer to radial distortion parameter 1
          * \param k2 : pointer to radial distortion parameter 2
          * \param k3 : pointer to radial distortion parameter 3
          * \param k4 : pointer to radial distortion parameter 4
          * \param k5 : pointer to radial distortion parameter 5
          * \param k6 : pointer to radial distortion parameter 6
          * \param p1 : pointer to tangential distortion parameter 1
          * \param p2 : pointer to tangential distortion parameter 2
          * \param    point : pointer to 3-D point (x,y,z) in world frame
          * \param residuals : pointer to residual vector
          *
          * To understand camera intrinsic parameters look at:
          * https://mathworks.com/help/vision/ug/camera-calibration.html
          *
          * Radial distortion is known to have 3 major configurations:
          *    - Only k1, k2 are in affect and non zero
          *    - Only k1, k2, k3 are in affect and non zero
          *    - All k1, k2, k3, k4, k5, k6 are in affect and non zero
          * k3, …, k6 are only needed for wide-angle lenses
          * https://mathworks.com/help/vision/ref/cameraintrinsics.html#bvhjcpz-1-RadialDistortion
          *
          */
        template <typename T>
        bool operator()(const T* const pose, const T* const fx, const T* const fy, const T* const cx, const T* const cy, const T* const s, const T* const k1, const T* const k2, const T* const k3, const T* const k4, const T* const k5, const T* const k6, const T* const p1, const T* const p2, const T* const point, T* residuals) const {
            // project point in world frame to camera frame
            Eigen::Matrix<T, 3, 1> point3D_in_cam = projectPointToCamera<T>(pose, point, m_SensorTransform.template cast<T>());
            // re-project point to image plane
            reprojectPointToImageUsingPinholeCameraModel<T>(&point3D_in_cam[0],
                       &point3D_in_cam[1],
                       &point3D_in_cam[2],
                       fx, fy, cx, cy, s, k1, k2, k3, k4, k5, k6, p1, p2,
                       &residuals[0],
                       &residuals[1]);
            // re-projection residual
            residuals[0] -= static_cast<T>(m_ObservedXY[0]);
            residuals[1] -= static_cast<T>(m_ObservedXY[1]);
            Eigen::Map<Eigen::Matrix<T, 2, 1>> res(residuals);
            res.applyOnTheLeft(m_SqrtInformation.template cast<T>());

            return true;   
        }

        /**
          * \brief Residual function for pinhole camera model with 8 parameter radial-tangential distortion, variable sensor transform and fixed known intrinsics.
          * \param      pose : pointer to pose (x,y,z,qx,qy,qz,qw) of base in world frame
          * \param     point : pointer to 3-D point (x,y,z) in world frame
          * \param     tform : sensor transform (x,y,z,qx,qy,qz,qw) from base sensor to current camera
          * \param residuals : pointer to residual vector
          */
        template <typename T>
        bool operator()(const T* const pose, const T* const point, const T* const tform, T* residuals) const {
            // project point in world frame to camera frame
            Eigen::Matrix<T, 3, 1> point3D_in_cam = projectPointToCamera<T>(pose, point, tform);
            Eigen::Matrix<T, 13, 1> ii = m_Intrinsics.template cast<T>();
            // re-project point to image plane
            reprojectPointToImageUsingPinholeCameraModel<T>(&point3D_in_cam[0],
                       &point3D_in_cam[1],
                       &point3D_in_cam[2],
                       &ii[0], &ii[1], &ii[2], &ii[3], &ii[4], &ii[5], &ii[6], &ii[7], &ii[8], &ii[9], &ii[10], &ii[11], &ii[12],
                       &residuals[0],
                       &residuals[1]);
            // re-projection residual
            residuals[0] -= static_cast<T>(m_ObservedXY[0]);
            residuals[1] -= static_cast<T>(m_ObservedXY[1]);
            Eigen::Map<Eigen::Matrix<T, 2, 1>> res(residuals);
            res.applyOnTheLeft(m_SqrtInformation.template cast<T>());

            return true;   
        }

        /**
          * \brief Residual function for pinhole camera model with 8 parameter radial-tangential distortion, fixed known sensor transform and fixed known intrinsics.
          * \param    pose : pointer to pose (x,y,z,qx,qy,qz,qw) of base in world frame
          * \param    point : pointer to 3-D point (x,y,z) in world frame
          * \param residuals : pointer to residual vector
          */
        template <typename T>
        bool operator()(const T* const pose, const T* const point, T* residuals) const {
            // project point in world frame to camera frame
            Eigen::Matrix<T, 3, 1> point3D_in_cam = projectPointToCamera<T>(pose, point, m_SensorTransform.template cast<T>());
            Eigen::Matrix<T, 13, 1> ii = m_Intrinsics.template cast<T>();
            // re-project point to image plane
            reprojectPointToImageUsingPinholeCameraModel<T>(&point3D_in_cam[0],
                       &point3D_in_cam[1],
                       &point3D_in_cam[2],
                       &ii[0], &ii[1], &ii[2], &ii[3], &ii[4], &ii[5], &ii[6], &ii[7], &ii[8], &ii[9], &ii[10], &ii[11], &ii[12],
                       &residuals[0],
                       &residuals[1]);
            // re-projection residual
            residuals[0] -= static_cast<T>(m_ObservedXY[0]);
            residuals[1] -= static_cast<T>(m_ObservedXY[1]);
            Eigen::Map<Eigen::Matrix<T, 2, 1>> res(residuals);
            res.applyOnTheLeft(m_SqrtInformation.template cast<T>());

            return true;   
        }


    protected:
        Eigen::Vector2d m_ObservedXY;
        Eigen::Matrix<double, 2, 2, Eigen::RowMajor> m_SqrtInformation;
        Eigen::Matrix<double, 4, 4, Eigen::RowMajor> m_SensorTransform;
        Eigen::Matrix<double, 13, 1> m_Intrinsics; // [fx,fy,cx,cy,s,k1,k2,k3,k4,k5,k6,p1,p2]
    };

    /** Functor to compute the projection cost between SE3 camera and R(3) point using pinhole camera model with single focal, aspect ratio, principal point and 8 parameter radial-tangential distortion (k1,k2,k3,k4,k5,k6,p1,p2) is used. The Jacobians are computed through Ceres auto-diff.
      *
      * The key differentiator of this pinhole model from the MATLAB 
      * pinhole is the aspect ratio. Instead of focal length along Y (fy)
      * as an intrinsic parameter this model uses an aspect ratio
      * parameter. This allows us to configure pinhole reprojection 
      * to use single focal length by fixeing aspect ratio (r) to 1.
      */
    class DistortedPinholeCameraWithAspectRatioReprojectionCost {
     public:
        DistortedPinholeCameraWithAspectRatioReprojectionCost(const std::vector<double>& imagePoint,
                          const std::vector<double>& information)  {
            // m_Observed is the observed position of the projection point in camera frame
            m_ObservedXY << imagePoint[0], imagePoint[1];
            m_SqrtInformation = Eigen::Matrix<double, 2, 2, Eigen::RowMajor>(information.data()).llt().matrixL();
        }

        /**
          * \brief Residual function for pinhole camera model with single focal, aspect ratio, principal point and 8 parameter radial-tangential distortion.
          * \param   pose : pointer to pose (x,y,z,qx,qy,qz,qw) of base in world frame
          * \param fx : pointer to focal length along X
          * \param r  : pointer to aspect ratio (fy/fx)
          * \param cx : pointer to principal point along X
          * \param cy : pointer to principal point along Y
          * \param k1 : pointer to radial distortion parameter 1
          * \param k2 : pointer to radial distortion parameter 2
          * \param k3 : pointer to radial distortion parameter 3
          * \param k4 : pointer to radial distortion parameter 4
          * \param k5 : pointer to radial distortion parameter 5
          * \param k6 : pointer to radial distortion parameter 6
          * \param p1 : pointer to tangential distortion parameter 1
          * \param p2 : pointer to tangential distortion parameter 2
          * \param point : pointer to 3-D point (x,y,z) in world frame
          * \param tform : sensor transform (x,y,z,qx,qy,qz,qw) from base sensor to current camera
          * \param residuals : pointer to residual vector
          *
          * To understand camera intrinsic parameters look at:
          * https://mathworks.com/help/vision/ug/camera-calibration.html
          *
          * Radial distortion is known to have 3 major configurations:
          *    - Only k1, k2 are in affect and non zero
          *    - Only k1, k2, k3 are in affect and non zero
          *    - All k1, k2, k3, k4, k5, k6 are in affect and non zero
          * k3, …, k6 are only needed for wide-angle lenses
          * https://mathworks.com/help/vision/ref/cameraintrinsics.html#bvhjcpz-1-RadialDistortion
          *
          * The key differentiator of this pinhole model from the above MATLAB 
          * pinhole is the aspect ratio. Instead of focal length along Y (fy)
          * as an intrinsic parameter this model uses an aspect ratio
          * parameter. This allows us to configure pinhole reprojection 
          * to use single focal length by fixing aspect ratio (r) to 1.
          *
          */
        template <typename T>
        bool operator()(const T* const pose, const T* const fx, const T* const r, const T* const cx, const T* const cy, const T* const k1, const T* const k2, const T* const k3, const T* const k4, const T* const k5, const T* const k6, const T* const p1, const T* const p2, const T* const point, const T* const tform, T* residuals) const {
            // project point in world frame to camera frame
            Eigen::Matrix<T, 3, 1> point3D_in_cam = projectPointToCamera<T>(pose, point, tform);
            // re-project point to image plane
            reprojectPointToImageUsingPinholeCameraModelWithAspectRatio<T>(&point3D_in_cam[0],
                       &point3D_in_cam[1],
                       &point3D_in_cam[2],
                       fx, r, cx, cy, k1, k2, k3, k4, k5, k6, p1, p2,
                       &residuals[0],
                       &residuals[1]);
            // re-projection residual
            residuals[0] -= static_cast<T>(m_ObservedXY[0]);
            residuals[1] -= static_cast<T>(m_ObservedXY[1]);
            Eigen::Map<Eigen::Matrix<T, 2, 1>> res(residuals);
            res.applyOnTheLeft(m_SqrtInformation.template cast<T>());

            return true;   
        }

    protected:
        Eigen::Vector2d m_ObservedXY;
        Eigen::Matrix<double, 2, 2, Eigen::RowMajor> m_SqrtInformation;
    };

    
    /**
    * \class FactorDistortedCameraProjection
    * \brief This class represents a factor between a pinhole camera with single focal, aspect ratio, principal point and 8 parameter radial-tangential distortion model and an R(3) point.
    *
    *    This factor connects to 15 nodes represented with the following unique identification numbers in factor graph:
    *       - poseId, fxId, rId, cxId, cyId, k1Id, k2Id, k3Id, k4Id, k5Id, k6Id, p1Id, p2Id, pointId, tformId
    *
    * \details This factor is the most advanced variant of the projection factor that
    * connects to one pose node, 12 intrinsic parameter nodes (fx, r, cx, cy, k1, k2, k3, k4, k5, k6, p1, p2),
    * one 3-D point node and one sensor transform node. In total
    * this factor connects to 15 nodes. Choose this factor for intrinsic +
    * extrinsic estimation workflows where the intrinsics are expected to
    * completely unknown.
    *
    * The key differentiator of this pinhole model from the above MATLAB 
    * pinhole is the aspect ratio. Instead of focal length along Y (fy)
    * as an intrinsic parameter this model uses an aspect ratio
    * parameter. This allows us to configure pinhole reprojection 
    * to use single focal length by fixing aspect ratio (r) to 1.
    *
    * This factor can help formulate many projection error minimization problems 
    * useful for various intrinsic and extrinsic calibration problems. Find
    * a few important configurations below:
    *
    *    - Fix every other intrinsic node except fx, set r to 1 and set 
    *      cx, cy to half of image size. This reduces the number of intrinsic 
    *      parameters greatly and is an essential setup to compute initial
    *      focal during intrinsic calibration. No other additional intrinsic
    *      initialization step (homography, essential matrix decomposition
    *      etc.) are unnecessary this way. This also helps in considering
    *      single focal camera model (square type pixels).
    *
    *    - Fix any of the radial distortion parameters from k1 till k6 to
    *      to mimic any required rad-tan model.
    *
    *    - Fix/unfix 3-D points during estimation based on the confidence
    *      their initial guess. For example the calibration surface may 
    *      not be perfectly planar. Having them unfixed will help 
    *      calibration a lot.
    *
    *    - The poses may be available from other sensors like a LIDAR in 
    *      combined calibration scenarios. Fix them during calibration 
    *      optimization to initialize the camera intrinsic parameters like
    *      focal and principal point. One this initialization is done
    *      execute a larger optimization with poses and other intrinsics
    *      unfixed to get the best results.
    *
    *    Member variables of interest:
    *       - m_Measurement : Image point measurement (x,y)
    *       - m_Information : Information matrix specified as a vector of the form [Ixx,0,0,Iyy]
    *
    *    Member functions of interest:
    *        - setMeasurement : Set the image point measurement
    *        - setInformation : Set the information
    *
    * This factor uses DistortedPinholeCameraReprojectionCost as residual cost function.
    */
    class CERESCODEGEN_API FactorDistortedCameraProjection : public FactorGaussianNoiseModel {
        public:
        /** 
          * Constructor of 12 param rad-tan camera projection factor
          *   \param ids : 15 length vector of connecting node unique identification numbers of the following form
          *                [poseId, fxId, rId, cxId, cyId, k1Id, k2Id, k3Id, k4Id, k5Id, k6Id, p1Id, p2Id, pointId, tformId]
          */
        FactorDistortedCameraProjection(std::vector<int> ids) : FactorGaussianNoiseModel(ids, {7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 7}, {VariableType::Pose_SE3, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Point_XYZ, VariableType::Transform_SE3}) {
            m_MeasurementLength = 2;
            m_InfoMatLength = 4;
            m_Measurement = {0.0, 0.0};
            m_InformationMatrix = std::vector<double>(m_InfoMatLength, 0.0);
            Eigen::Map<Eigen::Matrix<double, 2, 2, Eigen::RowMajor>> mat(m_InformationMatrix.data());
            mat = Eigen::Matrix<double, 2, 2, Eigen::RowMajor>::Identity();
            lossParameter = -1;
        }
        
        /** 
          * Constructor of 12 param rad-tan camera projection factor useful for derived projection factors.
          *   \param ids : vector of connecting node unique identification numbers
          *   \param dims : vector of state lengths of connecting nodes
          *   \param types : vector of state type of connecting nodes
          */
        FactorDistortedCameraProjection(std::vector<int> ids, std::vector<int> dims, std::vector<int> types) : FactorGaussianNoiseModel(ids, dims, types) {
            m_MeasurementLength = 2;
            m_InfoMatLength = 4;
            m_Measurement = {0.0, 0.0};
            m_InformationMatrix = std::vector<double>(m_InfoMatLength, 0.0);
            Eigen::Map<Eigen::Matrix<double, 2, 2, Eigen::RowMajor>> mat(m_InformationMatrix.data());
            mat = Eigen::Matrix<double, 2, 2, Eigen::RowMajor>::Identity();
            lossParameter = -1;
        }

        /**
          * \brief Create autodiff function using DistortedPinholeCameraWithAspectRatioReprojectionCost.
          *
          * \return ceres::CostFunction* : custom DistortedPinholeCameraWithAspectRatioReprojectionCost function
          */
        ceres::CostFunction* createFactorCostFcn() const override {
            return new ceres::AutoDiffCostFunction<DistortedPinholeCameraWithAspectRatioReprojectionCost, 2, 7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 7>(
                new DistortedPinholeCameraWithAspectRatioReprojectionCost(m_Measurement, m_InformationMatrix));
        }

        /**
          * \brief Create huber loss function to handle outliers whenever positive lossParameter is specified.
          *
          * \return ceres::LossFunctionWrapper* : Huber loss function with specified lossParameter.
          */
        ceres::LossFunctionWrapper* createFactorLossFcn() const override {
            if (lossParameter < 0)
                return nullptr;
            else
                return new ceres::LossFunctionWrapper(new ceres::HuberLoss(lossParameter), ceres::TAKE_OWNERSHIP);

        }

        /**
          * \brief Create custom ceres local parameterization for each connecting node type.
          *
          * The custom parameterizations are:
          *     - SE(3) pose parametrization of global size 7 and local size 6 for connecting pose and transform nodes
          *     - R(3) euclidian parametrization of global and local size 3 for connecting point node
          *     - R(1) euclidian parametrization of global and local size 1 for connecting intrinsic parameter nodes
          */
        ceres::LocalParameterization* getVariableLocalParameterization(int variableID) override {
            if (m_MapVariableLPTypes.find(variableID)->second == VariableType::Point_XYZ)
                return new ceres::IdentityParameterization(3);
            else if ((m_MapVariableLPTypes.find(variableID)->second == VariableType::Pose_SE3) || (m_MapVariableLPTypes.find(variableID)->second == VariableType::Transform_SE3))
                return new ceres::ProductParameterization( new ceres::IdentityParameterization(3),
                    new ceres::EigenQuaternionParameterization());
            else
                return new ceres::IdentityParameterization(1);
        }

        /**
          * \brief Get default state of each connecting node. This is necessary for initializing the state of the new node by factor graph.
          *
          * The default values for different node types are as following:
          *     - SE(3) pose : [0,0,0,1,0,0,0]
          *     - R(3) point : [0,0,0]
          *     - R(1) scalar camera intrinsic : [0]
          *
          *  \param variableID : Identification number of variable. This can help identify the type of node in the factor graph.
          *  \return std::vector<double> : storing the default state based on the type of node.
          */
        std::vector<double> getDefaultState(int variableID) const override {
            if (m_MapVariableLPTypes.find(variableID)->second == VariableType::Point_XYZ)
                return {0.0, 0.0, 0.0};
            else if ((m_MapVariableLPTypes.find(variableID)->second == VariableType::Pose_SE3) || (m_MapVariableLPTypes.find(variableID)->second == VariableType::Transform_SE3))
                return {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0};
            else
                return {0.0};
        }

        /** Get variable/node type of the variable/node represented by variableID as a string
          * \param variableID : Connecting node/variable identification number
          * \return string : variable type string 
          */
        std::string getVariableTypeString(int variableID) const override {
            return VariableTypeString.at(static_cast<VariableType>(getVariableType(variableID)));
        }

        
        /** Set value of loss parameter
          * \param lp : Scalar double loss parameter value
          * \return bool : Status of set operation. When true represents successful set.
          */
        bool setLossParameter(const double lp){
            lossParameter = lp;
            return true;
        }

        /** Set value of camera intrinsics.
          * \param intrinsics : double vector (std::vector<double>) of length 13 ([fx,fy,cx,cy,s,k1,k2,k3,k4,k5,k6,p1,p2]).
          * \return bool : Status of set operation. When true represents successful set.
          */
        bool setIntrinsic(std::vector<double>& intrinsics) {
            m_Intrinsics = intrinsics;
            return true;
        }

        /** Set value of sensor transform.
          * \param tform : double vector (std::vector<double>) of length 16 ([R11,R12,R13,tx,R21,R22,R23,ty,R31,R32,R33,tx,0,0,0,1])
          * \return bool : Status of set operation. When true represents successful set.
          */
        bool setSensorTransform(std::vector<double>& tform) {
            m_SensorTransform = tform;
            return true;
        }

        /** 
          * \brief Loss function parameter used to define the loss function. 
          *
          * Most loss functions supported in Ceres only takes one parameter which
		  * defines how large residuals are reduced. To create a valid loss
		  * function, lossParameter must be positive. Otherwise, no loss 
          * function is created.
          */
        double lossParameter;

        /** Ge the number of nodes connected by the projection factor.
          * \return size_t : Number of nodes connected by the projection factor.
          */
        virtual size_t getNumNodesToConnect() const { return 15;}

        /** Ge the length of camera intrinsic vector that is considered to be fixed during the optimization.
          * \return size_t : Number of fixed intrinsic parameters.
          */
        virtual size_t getFixedIntrinsicLength() const {return 0;}

        protected:
        /// camera intrinsic parameter vector [fx,fy,cx,cy,s,k1,k2,k3,k4,k5,k6,p1,p2]
        std::vector<double> m_Intrinsics;
        /// sensor transform vector
        std::vector<double> m_SensorTransform;
    };

    /**
      * \brief This class represents a factor between a pinhole camera with variable 8 parameter radial-tangential distortion model (k1,k2,k3,k4,k5,k6,p1,p2) and an R(3) point.
      *
      *    This factor connects to 16 nodes represented with the following unique identification numbers in factor graph:
      *       - poseId, fxId, fyId, cxId, cyId, sId, k1Id, k2Id, k3Id, k4Id, k5Id, k6Id, p1Id, p2Id, pointId, tformId
      *
      * This variant of the projection factor connects to one pose node, 
      * 13 intrinsic parameter nodes (fx, fy, cx, cy, s, k1, k2, k3, k4, k5, k6, p1, p2),
      * one 3-D point node and one sensor transform node. In total this 
      * factor connects to 16 nodes.
      *
      * Use this factor when intrinsics are known to some extent, MATLAB pinhole   
      * camera model is preferred and control over individual parameters
      * (fix/unfix etc.) is important. If no intrinsic refinement is needed
      * prefer camera factor variants that don't connect to intrinsic nodes.
      *
      * Member variables of interest:
      *     - m_Measurement : Image point measurement (x,y)
      *     - m_Information : Information matrix specified as a vector of the form [Ixx,0,0,Iyy]
      *
      * Member functions of interest:
      *     -  setMeasurement : Set the image point measurement
      *     -  setInformation : Set the information
      *
      * This factor uses DistortedPinholeCameraReprojectionCost as residual cost function
      */
    class CERESCODEGEN_API FactorDistortedPinholeCameraProjectionVariableIntrinsics : public FactorDistortedCameraProjection {
        public:
        /** 
          * Constructor of pinhole camera projection factor with variable 13 intrinsic param MATLAB radial-tangential model
          *   \param ids : 16 length vector of connecting node unique identification numbers of the following form
          *                [poseId, fxId, fyId, cxId, cyId, sId, k1Id, k2Id, k3Id, k4Id, k5Id, k6Id, p1Id, p2Id, pointId, tformId]
          */
        FactorDistortedPinholeCameraProjectionVariableIntrinsics(std::vector<int> ids) : FactorDistortedCameraProjection(ids, {7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 7}, {VariableType::Pose_SE3, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Camera_Intrinsics, VariableType::Point_XYZ, VariableType::Transform_SE3}) {
            m_Intrinsics = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}; // [fx,fy,cx,cy,s,k1,k2,k3,k4,k5,k6,p1,p2]
        }

        ceres::CostFunction* createFactorCostFcn() const override {
            return new ceres::AutoDiffCostFunction<DistortedPinholeCameraReprojectionCost, 2, 7, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 7>(
                new DistortedPinholeCameraReprojectionCost(m_Measurement, m_InformationMatrix));
        }

        size_t getNumNodesToConnect() const override { return 16;}
    };

    /**
      * \brief This class represents a factor between a pinhole camera with fixed 8 parameter radial-tangential distortion model (k1,k2,k3,k4,k5,k6,p1,p2) and an R(3) point.
      *
      *    This factor connects to 3 nodes represented with the following unique identification numbers in factor graph:
      *       - poseId, pointId, tformId
      *
      * This variant of the projection factor connects to one pose node,
      * one 3-D point node and one sensor transform node. In total this 
      * factor connects to 3 nodes.
      *
      * Use this factor when intrinsics are known to accurately, MATLAB   
      * pinhole camera model is preferred. If no intrinsic refinement is
      * needed and only extrinsic refinement is needed prefer this camera factor.
      *
      * Member variables of interest:
      *     - m_Measurement : Image point measurement (x,y)
      *     - m_Information : Information matrix specified as a vector of the form [Ixx,0,0,Iyy]
      *
      * Member functions of interest:
      *     -  setMeasurement : Set the image point measurement
      *     -  setInformation : Set the information
      *
      * This factor uses DistortedPinholeCameraReprojectionCost as residual cost function
      */
    class CERESCODEGEN_API FactorDistortedPinholeCameraProjectionFixedIntrinsics : public FactorDistortedCameraProjection {
        public:
        /** 
          * Constructor of MATLAB pinhole camera projection factor with fixed radial-tangential distortion parameters and variable sensor transform
          *   \param ids : 3 length vector of connecting node unique identification numbers of the following form
          *                [poseId, pointId, tformId]
          */
        FactorDistortedPinholeCameraProjectionFixedIntrinsics(std::vector<int> ids) : FactorDistortedCameraProjection(ids, {7, 3, 7}, {VariableType::Pose_SE3, VariableType::Point_XYZ, VariableType::Transform_SE3}) {
            m_Intrinsics = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}; // [fx,fy,cx,cy,s,k1,k2,k3,k4,k5,k6,p1,p2]
        }

        ceres::CostFunction* createFactorCostFcn() const override {
            return new ceres::AutoDiffCostFunction<DistortedPinholeCameraReprojectionCost, 2, 7, 3, 7>(
                new DistortedPinholeCameraReprojectionCost(m_Measurement, m_InformationMatrix, m_Intrinsics));
        }

        size_t getNumNodesToConnect() const override { return 3;}

        size_t getFixedIntrinsicLength() const override {return 13;}
    };

    /**
      * \brief This class represents a factor between a pinhole camera with fixed 8 parameter radial-tangential distortion model (k1,k2,k3,k4,k5,k6,p1,p2) and an R(3) point.
      *
      *    This factor connects to 2 nodes represented with the following unique identification numbers in factor graph:
      *       - poseId, pointId
      *
      * This variant of the projection factor connects to one pose node,
      * one 3-D point node. In total this factor connects to 2 nodes.
      *
      * Use this factor when intrinsics ansd sensor transform are known 
      * accurately, and MATLAB pinhole camera model is preferred. If no 
      * intrinsic and sensor transform (extrinsic) refinement is
      * needed prefer this camera factor.
      *
      * Member variables of interest:
      *     - m_Measurement : Image point measurement (x,y)
      *     - m_Information : Information matrix specified as a vector of the form [Ixx,0,0,Iyy]
      *
      * Member functions of interest:
      *     -  setMeasurement : Set the image point measurement
      *     -  setInformation : Set the information
      *
      * This factor uses DistortedPinholeCameraReprojectionCost as residual cost function
      */
    class CERESCODEGEN_API FactorDistortedPinholeCameraProjectionFixedIntrinsicsAndSensorTransform : public FactorDistortedCameraProjection {
        public:
        /** 
          * Constructor of MATLAB pinhole camera projection factor with fixed radial-tangential distortion parameters and sensor transform
          *   \param ids : 2 length vector of connecting node unique identification numbers of the following form
          *                [poseId, pointId]
          */
        FactorDistortedPinholeCameraProjectionFixedIntrinsicsAndSensorTransform(std::vector<int> ids) : FactorDistortedCameraProjection(ids, {7, 3}, {VariableType::Pose_SE3, VariableType::Point_XYZ}) {
            m_Intrinsics = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}; // [fx,fy,cx,cy,s,k1,k2,k3,k4,k5,k6,p1,p2]
        }

        ceres::CostFunction* createFactorCostFcn() const override {
            return new ceres::AutoDiffCostFunction<DistortedPinholeCameraReprojectionCost, 2, 7, 3>(
                new DistortedPinholeCameraReprojectionCost(m_Measurement, m_InformationMatrix, m_Intrinsics, m_SensorTransform));
        }

        size_t getNumNodesToConnect() const override { return 2;}

        size_t getFixedIntrinsicLength() const override {return 13;}
    };

    static const std::map<std::string, std::function<std::unique_ptr<FactorDistortedCameraProjection>(std::vector<int>)>> ProjectionFactorRegistry{
                      {"Distorted_Pinhole_Camera_Projection_With_Variable_Intrinsics_F", [](std::vector<int> ids) -> std::unique_ptr<FactorDistortedCameraProjection> {
                                 return std::make_unique<FactorDistortedPinholeCameraProjectionVariableIntrinsics>(ids);}},
                      {"Distorted_Pinhole_Camera_Projection_With_Aspect_Ratio_And_Variable_Intrinsics_F", [](std::vector<int> ids) -> std::unique_ptr<FactorDistortedCameraProjection> {
                         return std::make_unique<FactorDistortedCameraProjection>(ids);}},
                      {"Distorted_Pinhole_Camera_Projection_With_Fixed_Intrinsics_F", [](std::vector<int> ids) -> std::unique_ptr<FactorDistortedCameraProjection> {
                         return std::make_unique<FactorDistortedPinholeCameraProjectionFixedIntrinsics>(ids);}},
                      {"Distorted_Pinhole_Camera_Projection_With_Fixed_Intrinsics_And_Sensor_Transform_F", [](std::vector<int> ids) -> std::unique_ptr<FactorDistortedCameraProjection> {
                         return std::make_unique<FactorDistortedPinholeCameraProjectionFixedIntrinsicsAndSensorTransform>(ids);}}
                      };

    inline std::function<std::unique_ptr<FactorDistortedCameraProjection>(std::vector<int>)> createUnifiedProjectionFactorContructor(const std::string& factorType) {
        auto projectionFactorLookup = ProjectionFactorRegistry.find(factorType);
        return projectionFactorLookup->second;
    };

}

#endif // CAMERA_PROJECTION_FACTOR_HPP
