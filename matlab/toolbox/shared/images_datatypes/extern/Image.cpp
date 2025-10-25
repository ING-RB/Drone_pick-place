/**
* @file         Image.cpp
*
* Purpose       Class definition of Image class
*
* Authors       Dinesh Iyer
*
* Copyright     2019-2021 MathWorks, Inc.
*
*/

#include "Image.hpp"

#include <cassert>
#include <algorithm>

// ------------------------------------------------
// Local Helper
// ------------------------------------------------

namespace
{
    uint32_t computeNumBytesPerSample(images::datatypes::UnderlyingType type);
}

using namespace images::datatypes;

// ------------------------------------------------
// Lifetime
// ------------------------------------------------
Image::Image()
        : fMetadata(),
          fRelinquish(RelinquishDataUnderlying::NO)
{
    fDataUnderlyingMgr.reset( Image::createDataUnderlyingMgr(nullptr) );
}


// ------------------------------------------------
Image::Image( DimType height,
              DimType width,
              DimType numChannels,
              UnderlyingType dtype,
              ColorFormat format,
              Layout layout,
              RelinquishDataUnderlying relinquish )
                : Image( nullptr, 
                         ImageMetadata( height, width, numChannels, dtype,
                                        format, layout ), 
                         SourceMgmt::OWN_SRC, 
                         relinquish )
{
}


// ------------------------------------------------
Image::Image( const ImageMetadata& metadata,
              RelinquishDataUnderlying relinquish )
                : Image(nullptr, metadata, SourceMgmt::OWN_SRC, relinquish)
{
}

// ------------------------------------------------
Image::Image( void* src, 
              DimType height,
              DimType width,
              DimType numChannels,
              UnderlyingType dtype,
              ColorFormat format,
              Layout layout,
              SourceMgmt mgmt,
              RelinquishDataUnderlying relinquish )
                : Image( src, 
                         ImageMetadata( height, width, numChannels, dtype, 
                                        format, layout ),
                         mgmt, 
                         relinquish )
{
}

// ------------------------------------------------
Image::Image(void const* dataUnderlying,
             DimType height,
             DimType width,
             DimType numChannels,
             UnderlyingType dtype,
             ColorFormat format,
             Layout layout)
    : fMetadata(ImageMetadata(height, width, numChannels, dtype, format, layout))
    , fDataUnderlyingMgr( Image::createDataUnderlyingMgr(
        copyRawData(static_cast<BufferType const*>(dataUnderlying)).release(),
        SourceMgmt::COPY_SRC,
        RelinquishDataUnderlying::NO) ) {
}

// ------------------------------------------------
Image::Image( void* src, 
              const ImageMetadata& metadata,
              SourceMgmt mgmt,
              RelinquishDataUnderlying relinquish )
                : fMetadata(metadata),
                  fRelinquish(relinquish)
{
    // Need to perform property validation

    // Allocate memory in the constructor.
    // This ensures that getRawBuffer() does not break command/query separation
    if( src == nullptr ) 
    {
        std::unique_ptr<BufferType, RawDataDeleter> dataUnderlying( allocateBufferForDataUnderlying(), 
            RawDataDeleter() );

        fDataUnderlyingMgr.reset( Image::createDataUnderlyingMgr( dataUnderlying.release(), 
            mgmt, relinquish ) );
    }
    else
    {
        BufferType* srcLocal = reinterpret_cast<BufferType*>( src );

        if( mgmt == SourceMgmt::COPY_SRC )
        {
            auto newData = copyRawData( srcLocal );

            fDataUnderlyingMgr.reset( Image::createDataUnderlyingMgr( newData.release(), mgmt, relinquish ) );
        }
        else
        {
            fDataUnderlyingMgr.reset( Image::createDataUnderlyingMgr( srcLocal, mgmt, relinquish ) );
        }
    }
}

// ------------------------------------------------
Image::~Image() noexcept
{}


// ------------------------------------------------
// Copy and assignment operations
// ------------------------------------------------
Image::Image(const Image& otherImage)
{
    if( this == &otherImage ) 
    {
        return;
    }

    copyProps(otherImage);

}

Image& Image::operator=(const Image& otherImage)
{
    if( this == &otherImage ) 
    {
        return *this;
    }

    copyProps(otherImage);
    return *this;
}

// Move operations
Image::Image(Image&& otherImage) noexcept
{
    if( this == &otherImage ) 
    {
        return;
    }

    copyProps(otherImage);
}

Image& Image::operator=(Image&& otherImage) noexcept
{
    if( this == &otherImage )
    {
        return *this;
    }

    copyProps(otherImage);
    return *this;
}

// ------------------------------------------------
// Public methods
// ------------------------------------------------
Image Image::deepCopy(RelinquishDataUnderlying relinquish) const
{
    auto newData = copyRawData( fDataUnderlyingMgr->getUnderlyingData() );

    return Image( newData.release(),
                  fMetadata,
                  SourceMgmt::OWN_SRC,
                  relinquish );
}


// ------------------------------------------------
BufferType* Image::getUnderlyingData() const 
{ 
    return fDataUnderlyingMgr->getUnderlyingData(); 
}

// ------------------------------------------------
BufferType* Image::getUniqueDataUnderlying()
{
    auto data = getUnderlyingData();
    if (fDataUnderlyingMgr.use_count() == 1) {
        return data;
    }
    auto newData = copyRawData(data);
    fDataUnderlyingMgr.reset(
            Image::createDataUnderlyingMgr(
                    newData.get(),
                    SourceMgmt::COPY_SRC,
                    fRelinquish) );
    return newData.release();
}

// ------------------------------------------------
bool Image::isDeepCopyOfDataOnRelease() const 
{ 
    return fRelinquish == RelinquishDataUnderlying::NO; 
}


// ------------------------------------------------
BufferType* Image::releaseUnderlyingData() 
{ 
    return fDataUnderlyingMgr->releaseUnderlyingData(); 
}

// ------------------------------------------------
void Image::resize(DimType newHeight, DimType newWidth)
{
    if( newHeight == fMetadata.getHeight() &&
        newWidth == fMetadata.getWidth() )
    {
        // Do nothing if the target dimensions match the current one
        return;
    }

    fMetadata.setHeight(newHeight);
    fMetadata.setWidth(newWidth);
    std::unique_ptr<BufferType, RawDataDeleter> dataUnderlying( allocateBufferForDataUnderlying(), 
                                                                RawDataDeleter() );

    fDataUnderlyingMgr.reset( Image::createDataUnderlyingMgr( dataUnderlying.release(), 
                              SourceMgmt::OWN_SRC, fRelinquish ) );
}

// ------------------------------------------------
size_t Image::computeNumBytesInImage() const
{
    return static_cast<size_t>( getWidth() *
                                getHeight() *
                                getNumChannels() *
                                computeNumBytesPerSample(getUnderlyingType()) );
}

// ------------------------------------------------
// Private Helper functions
// ------------------------------------------------
void Image::copyProps(const Image& otherImage)
{
    fMetadata = otherImage.fMetadata;
    fRelinquish = otherImage.fRelinquish;

    // If the source object can relinquish the underlying data without a data
    // copy, then a copy of the underlying data has to be made
    // Reason is that unique_ptr instances that is used to manage the raw data
    // cannot be copy-assigned
    if( isDeepCopyOfDataOnRelease() ) 
    {
        fDataUnderlyingMgr = otherImage.fDataUnderlyingMgr;
    }
    else 
    {
        auto newDataUnderlying = copyRawData( otherImage.getUnderlyingData() );

        // Create a new source management scheme to manage this newly allocated memory buffer
        // storing the data underlying
        // Apply relinquish semantics to the target image.
        fDataUnderlyingMgr.reset( Image::createDataUnderlyingMgr( newDataUnderlying.release(), 
                                                           SourceMgmt::OWN_SRC, 
                                                           fRelinquish ) );
    }
}


// ------------------------------------------------
BufferType* Image::allocateBufferForDataUnderlying() const 
{
    return new BufferType[computeNumBytesInImage()]();
}


// ------------------------------------------------
Image::IUnderlyingDataMgr* Image::createDataUnderlyingMgr( BufferType* src, 
                                    SourceMgmt mgmt,
                                    RelinquishDataUnderlying relinquish )
{
    IUnderlyingDataMgr* mgr = nullptr;
    switch(mgmt) 
    {
        case SourceMgmt::COPY_SRC:
        case SourceMgmt::OWN_SRC:
            if( relinquish == RelinquishDataUnderlying::YES ) 
            {
                mgr = new Image::UnderlyingDataMgrSingleUse(src);
            }
            else 
            {
                mgr = new Image::UnderlyingDataMgrOwn(src);
            }
            break;

        case SourceMgmt::USE_SRC:
            // The relinquish flag is not applicable here
            mgr = new Image::UnderlyingDataMgrUseOnly(src); break;

        default:
            assert( false && "Should not reach this" );
    }

    return mgr;
}


// ------------------------------------------------
std::unique_ptr<BufferType, Image::RawDataDeleter> Image::copyRawData(const BufferType* src) const
{
    // Allocate a new-buffer to store the data
    std::unique_ptr<BufferType, Image::RawDataDeleter> newRawData( allocateBufferForDataUnderlying(), 
                                                            RawDataDeleter() );

    // Copy the data from the source object's underlying data into the target
    std::copy( src, 
               src + computeNumBytesInImage(), 
               newRawData.get() );

    return newRawData;
}


// ------------------------------------------------
// Private Helper functions
// ------------------------------------------------
namespace
{
    uint32_t computeNumBytesPerSample(images::datatypes::UnderlyingType type)
    {
        using namespace images::datatypes;

        uint32_t numBytes = 0;
        switch(type) 
        {
            case UnderlyingType::Uint8:
            case UnderlyingType::Int8:
                numBytes = 1; break;

            case UnderlyingType::Uint16:
            case UnderlyingType::Int16:
                numBytes = 2; break;

            case UnderlyingType::Uint32:
            case UnderlyingType::Int32:
            case UnderlyingType::Single:
                numBytes = 4; break;

            case UnderlyingType::Double:
                numBytes = 8; break;

            case UnderlyingType::Logical: // Need to confirm this
                numBytes = 1; break;

            default:
                assert( false && "Invalid pixel type" );
        }

        return numBytes;
    }
}
