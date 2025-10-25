// Copyright 2021-2022 The MathWorks, Inc.

#ifdef BUILDING_LIBMWCERESCODEGEN
    #include "cerescodegen/utilities.hpp"
#else
    /* To deal with the fact that PackNGo has no include file hierarchy */
    #include "utilities.hpp"
#endif

std::istream& mw_ceres::g2o::operator>>(std::istream& input, mw_ceres::g2o::VertexSE3& v) {
    input >> v.m_ID;                                    // node IDs
    input >> v.m_Data[0] >> v.m_Data[1] >> v.m_Data[2]; // pos
    input >> v.m_Data[3] >> v.m_Data[4] >> v.m_Data[5] >>
        v.m_Data[6]; // quaternion sequence is qx, qy, qz, qw in g2o, and we read in as is
    return input;
}

std::istream& mw_ceres::g2o::operator>>(std::istream& input, mw_ceres::g2o::VertexPointXYZ& v) {
    input >> v.m_ID;                                    // node IDs
    input >> v.m_Data[0] >> v.m_Data[1] >> v.m_Data[2]; // pos
    return input;
}

std::istream& mw_ceres::g2o::operator>>(std::istream& input, mw_ceres::g2o::EdgeSE3& e) {
    input >> e.m_IDs[0] >> e.m_IDs[1];                  // node IDs
    input >> e.m_Data[0] >> e.m_Data[1] >> e.m_Data[2]; // position vector
    input >> e.m_Data[3] >> e.m_Data[4] >> e.m_Data[5] >>
        e.m_Data[6];                 // quaternion sequence is qx, qy, qz, qw in g2o
    for (size_t i = 0; i < 6; i++) { // covariance 6x6 flattened row-major
        for (size_t j = i; j < 6; j++) {
            input >> e.m_Info[i * 6 + j];
            if (i != j) {
                e.m_Info[i + 6 * j] = e.m_Info[i * 6 + j];
            }
        }
    }
    return input;
}

std::istream& mw_ceres::g2o::operator>>(std::istream& input, mw_ceres::g2o::EdgeSE3PointXYZ& e) {
    input >> e.m_IDs[0] >> e.m_IDs[1];                  // node IDs
    input >> e.m_Data[0] >> e.m_Data[1] >> e.m_Data[2]; // position measurement
    for (size_t i = 0; i < 3; i++) {                    // covariance 3x3 flattened row-major
        for (size_t j = i; j < 3; j++) {
            input >> e.m_Info[i * 3 + j];
            if (i != j) {
                e.m_Info[i + 3 * j] = e.m_Info[i * 3 + j];
            }
        }
    }
    return input;
}

std::istream& mw_ceres::g2o::operator>>(std::istream& input, mw_ceres::g2o::VertexSE2& v) {
    input >> v.m_ID;                     // node IDs
    input >> v.m_Data[0] >> v.m_Data[1]; // position x, y
    input >> v.m_Data[2];                // theta
    return input;
}

std::istream& mw_ceres::g2o::operator>>(std::istream& input, mw_ceres::g2o::VertexPointXY& v) {
    input >> v.m_ID;                     // node IDs
    input >> v.m_Data[0] >> v.m_Data[1]; // position x, y
    return input;
}

std::istream& mw_ceres::g2o::operator>>(std::istream& input, mw_ceres::g2o::EdgeSE2& e) {
    input >> e.m_IDs[0] >> e.m_IDs[1];   // node IDs
    input >> e.m_Data[0] >> e.m_Data[1]; // position x, y
    input >> e.m_Data[2];                // theta
    for (size_t i = 0; i < 3; i++) {     // covariance 3x3 flattened row-major
        for (size_t j = i; j < 3; j++) {
            input >> e.m_Info[i * 3 + j];
            if (i != j) {
                e.m_Info[i + 3 * j] = e.m_Info[i * 3 + j];
            }
        }
    }
    return input;
}

std::istream& mw_ceres::g2o::operator>>(std::istream& input, mw_ceres::g2o::EdgeSE2PointXY& e) {
    input >> e.m_IDs[0] >> e.m_IDs[1];   // node IDs
    input >> e.m_Data[0] >> e.m_Data[1]; // position x, y
    for (size_t i = 0; i < 2; i++) {     // covariance 2x2 flattened row-major
        for (size_t j = i; j < 2; j++) {
            input >> e.m_Info[i * 2 + j];
            if (i != j) {
                e.m_Info[i + 2 * j] = e.m_Info[i * 2 + j];
            }
        }
    }
    return input;
}

