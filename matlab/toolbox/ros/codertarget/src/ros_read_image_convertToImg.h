/* Copyright 2024 The MathWorks, Inc. */

#ifndef _ROS_IMAGEREADER_CONVERTTOIMG_H_
#define _ROS_IMAGEREADER_CONVERTTOIMG_H_

#include <iostream>
#include <string>
#include <cstdint>
#include <vector>
#include <string>
#include <map>
#include <algorithm>
#include <stdexcept>
#include <future>
#include <cstring>
#include <list>
// Define data types corresponding to MATLAB's mClassId
enum DataType {
    UINT8,
    UINT16,
    INT8,
    INT16,
    INT32,
    FLOAT32,
    FLOAT64
};
class ImageReaderBase {
protected:
    std::map<std::string, uint8_t> mEncodingFormats = {
        {"rgb8", 1},          {"rgba8", 2},        {"rgb16", 3},         {"rgba16", 4},
        {"bgr8", 5},          {"bgra8", 6},        {"bgr16", 7},         {"bgra16", 8},
        {"mono8", 9},         {"mono16", 10},      {"32fc1", 11},        {"32fc2", 12},
        {"32fc3", 13},        {"32fc4", 14},       {"64fc1", 15},        {"64fc2", 16},
        {"64fc3", 17},        {"64fc4", 18},       {"8uc1", 19},         {"8uc2", 20},
        {"8uc3", 21},         {"8uc4", 22},        {"8sc1", 23},         {"8sc2", 24},
        {"8sc3", 25},         {"8sc4", 26},        {"16uc1", 27},        {"16uc2", 28},
        {"16uc3", 29},        {"16uc4", 30},       {"16sc1", 31},        {"16sc2", 32},
        {"16sc3", 33},        {"16sc4", 34},       {"32sc1", 35},        {"32sc2", 36},
        {"32sc3", 37},        {"32sc4", 38}};
public:
    std::string mEncodingFormat;
    uint32_t mHeight;
    uint32_t mWidth;
    uint32_t mNumChannels;
    std::vector<uint32_t> mChannelOrder;
    size_t mDataTypeSize;

};
class RosImageReader : public ImageReaderBase {
    const uint8_t* mImgMsgData;
    uint32_t mDataSize;
public:

    DataType mDataType;
    uint8_t* mImgMatrix;
    std::string mEncoding;
    
    // Constructor
    RosImageReader(const uint8_t* imgMsgData, uint32_t dataSize,
                   uint32_t width, uint32_t height,
                   const char* encoding,uint8_t* imgData)
        : mImgMsgData(imgMsgData)
        , mDataSize(dataSize){
        mHeight = height;
        mWidth = width;
        mEncodingFormat = encoding;
        std::transform(mEncodingFormat.begin(), mEncodingFormat.end(), mEncodingFormat.begin(), ::tolower);
        // Get the encoding parameters based on the format.
        switch (mEncodingFormats[mEncodingFormat]) {
        case 1:
            mNumChannels = 3;
            mChannelOrder = {1, 2, 3};
            mDataType = UINT8;
            mDataTypeSize = sizeof(uint8_t);
            break;
        case 2:
            mNumChannels = 4;
            mChannelOrder = {1, 2, 3, 4};
            mDataType = UINT8;
            mDataTypeSize = sizeof(uint8_t);
            break;
        case 3:
            mNumChannels = 3;
            mChannelOrder = {1, 2, 3};
            mDataType = UINT16;
            mDataTypeSize = sizeof(uint16_t);
            break;
        case 4:
            mNumChannels = 4;
            mChannelOrder = {1, 2, 3, 4};
            mDataType = UINT16;
            mDataTypeSize = sizeof(uint16_t);
            break;
        case 5:
            mNumChannels = 3;
            mChannelOrder = {3, 2, 1};
            mDataType = UINT8;
            mDataTypeSize = sizeof(uint8_t);
            break;
        case 6:
            mNumChannels = 4;
            mChannelOrder = {3, 2, 1, 4};
            mDataType = UINT8;
            mDataTypeSize = sizeof(uint8_t);
            break;
        case 7:
            mNumChannels = 3;
            mChannelOrder = {3, 2, 1};
            mDataType = UINT16;
            mDataTypeSize = sizeof(uint16_t);
            break;
        case 8:
            mNumChannels = 4;
            mChannelOrder = {3, 2, 1, 4};
            mDataType = UINT16;
            mDataTypeSize = sizeof(uint16_t);
            break;
        case 9:
            mNumChannels = 1;
            mChannelOrder = {1};
            mDataType = UINT8;
            mDataTypeSize = sizeof(uint8_t);
            break;
        case 10:
            mNumChannels = 1;
            mChannelOrder = {1};
            mDataType = UINT16;
            mDataTypeSize = sizeof(uint16_t);
            break;
        case 11:
            mNumChannels = 1;
            mChannelOrder = {1};
            mDataType = FLOAT32;
            mDataTypeSize = sizeof(float);
            break;
        case 12:
            mNumChannels = 2;
            mChannelOrder = {1, 2};
            mDataType = FLOAT32;
            mDataTypeSize = sizeof(float);
            break;
        case 13:
            mNumChannels = 3;
            mChannelOrder = {1, 2, 3};
            mDataType = FLOAT32;
            mDataTypeSize = sizeof(float);
            break;
        case 14:
            mNumChannels = 4;
            mChannelOrder = {1, 2, 3, 4};
            mDataType = FLOAT32;
            mDataTypeSize = sizeof(float);
            break;
        case 15:
            mNumChannels = 1;
            mChannelOrder = {1};
            mDataType = FLOAT64;
            mDataTypeSize = sizeof(double);
            break;
        case 16:
            mNumChannels = 2;
            mChannelOrder = {1, 2};
            mDataType = FLOAT64;
            mDataTypeSize = sizeof(double);
            break;
        case 17:
            mNumChannels = 3;
            mChannelOrder = {1, 2, 3};
            mDataType = FLOAT64;
            mDataTypeSize = sizeof(double);
            break;
        case 18:
            mNumChannels = 4;
            mChannelOrder = {1, 2, 3, 4};
            mDataType = FLOAT64;
            mDataTypeSize = sizeof(double);
            break;
        case 19:
            mNumChannels = 1;
            mChannelOrder = {1};
            mDataType = UINT8;
            mDataTypeSize = sizeof(uint8_t);
            break;
        case 20:
            mNumChannels = 2;
            mChannelOrder = {1, 2};
            mDataType = UINT8;
            mDataTypeSize = sizeof(uint8_t);
            break;
        case 21:
            mNumChannels = 3;
            mChannelOrder = {1, 2, 3};
            mDataType = UINT8;
            mDataTypeSize = sizeof(uint8_t);
            break;
        case 22:
            mNumChannels = 4;
            mChannelOrder = {1, 2, 3, 4};
            mDataType = UINT8;
            mDataTypeSize = sizeof(uint8_t);
            break;
        case 23:
            mNumChannels = 1;
            mChannelOrder = {1};
            mDataType = INT8;
            mDataTypeSize = sizeof(int8_t);
            break;
        case 24:
            mNumChannels = 2;
            mChannelOrder = {1, 2};
            mDataType = INT8;
            mDataTypeSize = sizeof(int8_t);
            break;
        case 25:
            mNumChannels = 3;
            mChannelOrder = {1, 2, 3};
            mDataType = INT8;
            mDataTypeSize = sizeof(int8_t);
            break;
        case 26:
            mNumChannels = 4;
            mChannelOrder = {1, 2, 3, 4};
            mDataType = INT8;
            mDataTypeSize = sizeof(int8_t);
            break;
        case 27:
            mNumChannels = 1;
            mChannelOrder = {1};
            mDataType = UINT16;
            mDataTypeSize = sizeof(uint16_t);
            break;
        case 28:
            mNumChannels = 2;
            mChannelOrder = {1, 2};
            mDataType = UINT16;
            mDataTypeSize = sizeof(uint16_t);
            break;
        case 29:
            mNumChannels = 3;
            mChannelOrder = {1, 2, 3};
            mDataType = UINT16;
            mDataTypeSize = sizeof(uint16_t);
            break;
        case 30:
            mNumChannels = 4;
            mChannelOrder = {1, 2, 3, 4};
            mDataType = UINT16;
            mDataTypeSize = sizeof(uint16_t);
            break;
        case 31:
            mNumChannels = 1;
            mChannelOrder = {1};
            mDataType = INT16;
            mDataTypeSize = sizeof(int16_t);
            break;
        case 32:
            mNumChannels = 2;
            mChannelOrder = {1, 2};
            mDataType = INT16;
            mDataTypeSize = sizeof(int16_t);
            break;
        case 33:
            mNumChannels = 3;
            mChannelOrder = {1, 2, 3};
            mDataType = INT16;
            mDataTypeSize = sizeof(int16_t);
            break;
        case 34:
            mNumChannels = 4;
            mChannelOrder = {1, 2, 3, 4};
            mDataType = INT16;
            mDataTypeSize = sizeof(int16_t);
            break;
        case 35:
            mNumChannels = 1;
            mChannelOrder = {1};
            mDataType = INT32;
            mDataTypeSize = sizeof(int32_t);
            break;
        case 36:
            mNumChannels = 2;
            mChannelOrder = {1, 2};
            mDataType = INT32;
            mDataTypeSize = sizeof(int32_t);
            break;
        case 37:
            mNumChannels = 3;
            mChannelOrder = {1, 2, 3};
            mDataType = INT32;
            mDataTypeSize = sizeof(int32_t);
            break;
        case 38:
            mNumChannels = 4;
            mChannelOrder = {1, 2, 3, 4};
            mDataType = INT32;
            mDataTypeSize = sizeof(int32_t);
            break;

        // Add other cases as needed
        default:
            throw std::logic_error("Invalid Encoding");
        }
        
        mImgMatrix = imgData;
    }
    void createImageMatrix() {

      // Create matrix based on required data-type and create an image matrix.
        switch (mDataType) {
        case UINT8:
            convertToImgTemplate<uint8_t>();
            break;
        case UINT16:
            convertToImgTemplate<uint16_t>();
            break;
        case INT8:
            convertToImgTemplate<int8_t>();
            break;
        case INT16:
            convertToImgTemplate<int16_t>();
            break;
        case INT32:
            convertToImgTemplate<int32_t>();
            break;
        case FLOAT32:
            convertToImgTemplate<float>();
            break;
        case FLOAT64:
            convertToImgTemplate<double>();
            break;
        
        default:
            throw std::logic_error("Invalid data type");
        }
    }
    template <typename T>
    void convertToImgTemplate() {
        // Get the actual pointer of the image message data field.
        const T* pConvertedDataPtr = reinterpret_cast<const T*>(mImgMsgData);

        // Prepare the image matrix
        T* pImageMat = reinterpret_cast<T*>(mImgMatrix);
        
        // Read data field and write into image matrix using multithreading
        const size_t channelStep = mWidth * mHeight;
        const size_t heightStep = mWidth * mNumChannels;
        std::list<std::future<void>> futures;
        for (size_t channelIndex = 0; channelIndex < mNumChannels; ++channelIndex) {
            futures.emplace_back(std::async(
                std::launch::async, &RosImageReader::ReadImageData<T>, this, std::ref(pImageMat),
                std::ref(pConvertedDataPtr), channelIndex, channelStep, heightStep));
        }
        // Wait for all futures to complete
        std::for_each(futures.begin(), futures.end(), [](std::future<void>& f) { f.wait(); });
        futures.clear();
    }
    template <typename T>
    void ReadImageData(T*& imageMat,
                       const T*& convertedDataPtr,
                       size_t channelIndex,
                       const size_t& channelStep,
                       const size_t& heightStep) {
        // Read image data into image matrix in worker threads that are launched based on the
        // individual channels
        size_t channelMatrix = channelStep * channelIndex;
        size_t indexedHeightData = 0;
        size_t indexedChannelData = 0;
        for (size_t heightIndex = 0; heightIndex < mHeight; ++heightIndex) {
            size_t heightMatrix = heightStep * heightIndex;
            indexedHeightData = heightMatrix + mChannelOrder[channelIndex] - 1;
            indexedChannelData = channelMatrix + heightIndex;
            for (size_t widthIndex = 0; widthIndex < mWidth; ++widthIndex) {
                *(imageMat + indexedChannelData + (widthIndex * mHeight)) =
                    *(convertedDataPtr + indexedHeightData + (widthIndex * mNumChannels));
            }
        }
    }
};
inline void readImage(const uint8_t* rosImgData, uint32_t dataSize,
               uint32_t width, uint32_t height,
               const char* encodingStr,
               uint8_t* imgData) {
    
    RosImageReader gir(rosImgData, dataSize, width, height, encodingStr,imgData);
    gir.createImageMatrix();
}
#endif
