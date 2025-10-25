// Copyright 2024 The MathWorks, Inc.
#ifdef BUILDING_LIBMWCOLLISIONFCNCODEGEN
#include "collisionfcncodegen/collisioncodegen_functional_api.hpp"
#include "collisioncodegen/collisioncodegen_ccdExtensions.hpp"
#include <ccd/ccd_vec3.h>
#include <ccd/ccd_quat.h>
#else
#include "collisioncodegen_functional_api.hpp"
#include "collisioncodegen_ccdExtensions.hpp"
#include <ccd_vec3.h>
#include <ccd_quat.h>
#endif
#include <stdio.h>

static void tformvert(ccd_vec3_t* vert,
                      ccd_vec3_t* supportPoint,
                      const ccd_quat_t* quat,
                      const ccd_vec3_t* pos) {
    ccdQuatRotVec(vert, quat);
    ccdVec3Add(vert, pos);
    ccdVec3Copy(supportPoint, vert);
}

static real64_T collisioncodegen_dotprod(const real64_T* vx,
                                         const real64_T* vy,
                                         const real64_T* vz,
                                         const ccd_vec3_t* dir) {
    return *vx * dir->v[0] + *vy * dir->v[1] + *vz * dir->v[2];
}

EXTERN_C COLLISIONCODEGEN_API int8_T collisioncodegen_intersect2(CollisionGeometryStruct* obj1,
                                                                 const real64_T* vert1,
                                                                 CollisionGeometryStruct* obj2,
                                                                 const real64_T* vert2,
                                                                 real64_T computeDistance,
                                                                 real64_T* p1Vec,
                                                                 real64_T* p2Vec,
                                                                 real64_T* distance) {
    obj1->m_Vertices = vert1;
    obj2->m_Vertices = vert2;
    int8_T result;
    ccd_t ccd;
    CCD_INIT(&ccd);
    ccd.support1 = collisionGeometryStructSupport(obj1);
    ccd.support2 = collisionGeometryStructSupport(obj2);
    ccd.max_iterations = 100;
    ccd_vec3_t p1 = {{0, 0, 0}};
    ccd_vec3_t p2 = {{0, 0, 0}};
    *distance = -CCD_ONE;
    p1Vec[0] = 0;
    p1Vec[1] = 0;
    p1Vec[2] = 0;

    p2Vec[0] = 0;
    p2Vec[1] = 0;
    p2Vec[2] = 0;
    if (static_cast<int8_T>(computeDistance)) {
        *distance = shared_robotics::ccdDistance(static_cast<const void*>(obj1),
                                                 static_cast<const void*>(obj2), &ccd, &p1, &p2);
        p1Vec[0] = p1.v[0];
        p1Vec[1] = p1.v[1];
        p1Vec[2] = p1.v[2];
        p2Vec[0] = p2.v[0];
        p2Vec[1] = p2.v[1];
        p2Vec[2] = p2.v[2];
        if (*distance < 0) {
            result = 1;
        } else {
            result = 0;
        }
    } else {
        result = static_cast<int8_T>(
            ccdGJKIntersect(static_cast<void*>(obj1), static_cast<void*>(obj2), &ccd));
    }
    return result;
}

static ccd_quat_t ccdquatfromgeom(const CollisionGeometryStruct* geom) {
    ccd_quat_t geomquat;
    ccdQuatSet(&geomquat, geom->m_Quaternion[1], geom->m_Quaternion[2], geom->m_Quaternion[3],
               geom->m_Quaternion[0]);
    return geomquat;
}

static ccd_vec3_t ccdposfromgeom(const CollisionGeometryStruct* geom) {
    ccd_vec3_t geompos;
    ccdVec3Set(&geompos, geom->m_Position[0], geom->m_Position[1], geom->m_Position[2]);
    return geompos;
}

static ccd_vec3_t tformdirtolocalframe(const CollisionGeometryStruct* geom,
                                       const ccd_vec3_t* ccdDirection) {
    ccd_quat_t quatInv = {{0, 0, 0, 1}};
    ccd_quat_t geomquat = ccdquatfromgeom(geom);
    ccdQuatInvert2(&quatInv, &geomquat);
    ccd_vec3_t dirRot;
    ccdVec3Copy(&dirRot, ccdDirection);
    ccdQuatRotVec(&dirRot, &quatInv);
    return dirRot;
}

static void boxsupport(const void* obj, const ccd_vec3_t* ccdDirection, ccd_vec3_t* supportPoint) {
    const CollisionGeometryStruct* geom = static_cast<const CollisionGeometryStruct*>(obj);
    ccd_vec3_t dirRot = tformdirtolocalframe(geom, ccdDirection);
    ccd_vec3_t vert;
    ccd_quat_t geomquat = ccdquatfromgeom(geom);
    ccd_vec3_t geompos = ccdposfromgeom(geom);
    ccdVec3Set(&vert, ccdSign(ccdVec3X(&dirRot)) * geom->m_X * CCD_REAL(0.5),
               ccdSign(ccdVec3Y(&dirRot)) * geom->m_Y * CCD_REAL(0.5),
               ccdSign(ccdVec3Z(&dirRot)) * geom->m_Z * CCD_REAL(0.5));
    tformvert(&vert, supportPoint, &geomquat, &geompos);
}

static void sphsupport(const void* obj, const ccd_vec3_t* ccdDirection, ccd_vec3_t* supportPoint) {
    const CollisionGeometryStruct* geom = static_cast<const CollisionGeometryStruct*>(obj);
    ccd_vec3_t dirRot = tformdirtolocalframe(geom, ccdDirection);
    ccd_vec3_t vert;
    ccd_quat_t geomquat = ccdquatfromgeom(geom);
    ccd_vec3_t geompos = ccdposfromgeom(geom);
    ccd_real_t len = CCD_SQRT(ccdVec3Len2(&dirRot));
    ccd_real_t scale = geom->m_Radius / len;
    ccdVec3Copy(&vert, &dirRot);
    ccdVec3Scale(&vert, scale);
    tformvert(&vert, supportPoint, &geomquat, &geompos);
}

static void cylsupport(const void* obj, const ccd_vec3_t* ccdDirection, ccd_vec3_t* supportPoint) {
    const CollisionGeometryStruct* geom = static_cast<const CollisionGeometryStruct*>(obj);
    ccd_vec3_t dirRot = tformdirtolocalframe(geom, ccdDirection);
    ccd_vec3_t vert;
    ccd_quat_t geomquat = ccdquatfromgeom(geom);
    ccd_vec3_t geompos = ccdposfromgeom(geom);
    ccd_real_t xyShadow = CCD_SQRT(dirRot.v[0] * dirRot.v[0] + dirRot.v[1] * dirRot.v[1]);
    if (CCD_FABS(xyShadow) < 5 * CCD_EPS) /* with double-precision built ccd, CCD_EPS is
                                           DBL_EPSILON in float.h, around 2.22045e-16*/
    {
        ccdVec3Set(&vert, CCD_ZERO, CCD_ZERO,
                   ccdSign(ccdVec3Z(&dirRot)) * geom->m_Height * CCD_REAL(0.5));
    } else {
        ccd_real_t scale = geom->m_Radius / xyShadow;
        ccdVec3Set(&vert, scale * dirRot.v[0], scale * dirRot.v[1],
                   ccdSign(ccdVec3Z(&dirRot)) * geom->m_Height * CCD_REAL(0.5));
    }
    tformvert(&vert, supportPoint, &geomquat, &geompos);
}

static void capssupport(const void* obj, const ccd_vec3_t* ccdDirection, ccd_vec3_t* supportPoint) {
    const CollisionGeometryStruct* geom = static_cast<const CollisionGeometryStruct*>(obj);
    ccd_vec3_t dirRot = tformdirtolocalframe(geom, ccdDirection);
    ccd_vec3_t vert;
    ccd_quat_t geomquat = ccdquatfromgeom(geom);
    ccd_vec3_t geompos = ccdposfromgeom(geom);
    /*
        Consider the support vector "s", then the farthest point "p" along
        the capsule in direction of "s" is given as,

        p = [0, 0, sign(dot(s,[0,0,1]))] * L/2 + R * s

        Where L and R are the length/height and radius of the capsule,
        respectively.
    */
    ccd_real_t len = CCD_SQRT(ccdVec3Len2(&dirRot));
    ccd_real_t scale = geom->m_Radius / len;
    ccdVec3Set(&vert, scale * dirRot.v[0], scale * dirRot.v[1],
               ccdSign(ccdVec3Z(&dirRot)) * geom->m_Height * CCD_REAL(0.5) + scale * dirRot.v[2]);
    tformvert(&vert, supportPoint, &geomquat, &geompos);
}

static void convmeshsupport(const void* obj,
                            const ccd_vec3_t* ccdDirection,
                            ccd_vec3_t* supportPoint) {
    const CollisionGeometryStruct* geom = static_cast<const CollisionGeometryStruct*>(obj);
    ccd_vec3_t dirRot = tformdirtolocalframe(geom, ccdDirection);
    ccd_vec3_t vert;
    ccd_quat_t geomquat = ccdquatfromgeom(geom);
    ccd_vec3_t geompos = ccdposfromgeom(geom);
    uint32_T argmax = 0;
    real64_T maxdotprod = collisioncodegen_dotprod(
        geom->m_Vertices + argmax, geom->m_Vertices + argmax + geom->m_NumVertices,
        geom->m_Vertices + argmax + 2 * geom->m_NumVertices, &dirRot);
    for (uint32_T i = 0; i < geom->m_NumVertices; ++i) {
        real64_T dotprod = collisioncodegen_dotprod(
            geom->m_Vertices + i, geom->m_Vertices + i + geom->m_NumVertices,
            geom->m_Vertices + i + 2 * geom->m_NumVertices, &dirRot);
        if (dotprod > maxdotprod) {
            maxdotprod = dotprod;
            argmax = i;
        }
    }
    ccdVec3Set(&vert, geom->m_Vertices[argmax], geom->m_Vertices[argmax + geom->m_NumVertices],
               geom->m_Vertices[argmax + 2 * geom->m_NumVertices]);
    tformvert(&vert, supportPoint, &geomquat, &geompos);
}

EXTERN_C COLLISIONCODEGEN_API ccd_support_fn
collisionGeometryStructSupport(const CollisionGeometryStruct* obj) {
    switch (obj->m_Type) {
    case BOX:
        return &boxsupport;
    case SPHERE:
        return &sphsupport;
    case MESH:
        return &convmeshsupport;
    case CAPSULE:
        return &capssupport;
    case CYLINDER:
        return &cylsupport;
    }
    return NULL;
}
