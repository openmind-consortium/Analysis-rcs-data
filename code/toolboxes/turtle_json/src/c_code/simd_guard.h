//https://stackoverflow.com/questions/6121792/how-to-check-if-a-cpu-supports-the-sse3-instruction-set

//This code has been copied and reduced to a single c header from:
//https://github.com/Mysticial/FeatureDetector

/* simd_guard.h
 * 
 * Author           : Alexander J. Yee
 * Date Created     : 04/12/2014
 * Last Modified    : 04/12/2014
 * 
 */

#pragma once
#ifndef _cpu_x86_H
#define _cpu_x86_H
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//  Dependencies
#include <stdint.h>
#include <stdbool.h>


#if defined(__x86_64__) || defined(_M_X64) || defined(__i386) || defined(_M_IX86)
#   if defined(__GNUC__) || defined(__clang__)

//Linux/Mac
//-----------------------------
//???? What is this? - is this normally already
//defined in Windows?
#define _XCR_XFEATURE_ENABLED_MASK  0

#include <cpuid.h>

void cpuid(int32_t out[4], int32_t x){
    __cpuid_count(x, 0, out[0], out[1], out[2], out[3]);
}
uint64_t xgetbv(unsigned int index){
    uint32_t eax, edx;
    __asm__ __volatile__("xgetbv" : "=a"(eax), "=d"(edx) : "c"(index));
    return ((uint64_t)edx << 32) | eax;
}

#   elif _WIN32

//Windows
//-----------------------------
#include <Windows.h>
#include <intrin.h>

__int64 xgetbv(unsigned int x){
    return _xgetbv(x);
}


void cpuid(int32_t out[4], int32_t x){
    __cpuidex(out, x, 0);
}




#   else
#       error "No cpuid intrinsic defined for compiler."
#   endif
#else
#   error "No cpuid intrinsic defined for processor architecture."
#endif


struct cpu_x86{
    //  Vendor
    bool Vendor_AMD;
    bool Vendor_Intel;

    //  OS Features
    bool OS_x64;
    bool OS_AVX;
    bool OS_AVX512;

    //  Misc.
    bool HW_MMX;
    bool HW_x64;
    bool HW_ABM;
    bool HW_RDRAND;
    bool HW_BMI1;
    bool HW_BMI2;
    bool HW_ADX;
    bool HW_PREFETCHWT1;
    bool HW_MPX;

    //  SIMD: 128-bit
    bool HW_SSE;
    bool HW_SSE2;
    bool HW_SSE3;
    bool HW_SSSE3;
    bool HW_SSE41;
    bool HW_SSE42;
    bool HW_SSE4a;
    bool HW_AES;
    bool HW_SHA;

    //  SIMD: 256-bit
    bool HW_AVX;
    bool HW_XOP;
    bool HW_FMA3;
    bool HW_FMA4;
    bool HW_AVX2;

    //  SIMD: 512-bit
    bool HW_AVX512_F;
    bool HW_AVX512_PF;
    bool HW_AVX512_ER;
    bool HW_AVX512_CD;
    bool HW_AVX512_VL;
    bool HW_AVX512_BW;
    bool HW_AVX512_DQ;
    bool HW_AVX512_IFMA;
    bool HW_AVX512_VBMI;


};

//JAH: Need to import code dependencies for this function ...

bool detect_OS_AVX(){
    //  Copied from: http://stackoverflow.com/a/22521619/922184

    bool avxSupported = false;

    int cpuInfo[4];
    cpuid(cpuInfo, 1);

    bool osUsesXSAVE_XRSTORE = (cpuInfo[2] & (1 << 27)) != 0;
    bool cpuAVXSuport = (cpuInfo[2] & (1 << 28)) != 0;

    if (osUsesXSAVE_XRSTORE && cpuAVXSuport)
    {
        uint64_t xcrFeatureMask = xgetbv(_XCR_XFEATURE_ENABLED_MASK);
        avxSupported = (xcrFeatureMask & 0x6) == 0x6;
    }

    return avxSupported;
}
 
bool detect_OS_AVX512(){
    if (!detect_OS_AVX())
        return false;

    uint64_t xcrFeatureMask = xgetbv(_XCR_XFEATURE_ENABLED_MASK);
    return (xcrFeatureMask & 0xe6) == 0xe6;
}


void cpu_x86__detect_host(struct cpu_x86 *s){
    
    //  OS Features
    //-------------------------------
    
    //x64 is pretty straight forward
    
    //s->OS_x64 = detect_OS_x64();
    s->OS_AVX = detect_OS_AVX();
    s->OS_AVX512 = detect_OS_AVX512();

//  Vendor    
//TODO
// // //     std::string vendor(get_vendor_string());
// // //     if (vendor == "GenuineIntel"){
// // //         Vendor_Intel = true;
// // //     }else if (vendor == "AuthenticAMD"){
// // //         Vendor_AMD = true;
// // //     }

    int info[4];
    cpuid(info, 0);
    int nIds = info[0];

    cpuid(info, 0x80000000);
    uint32_t nExIds = info[0];

    //  Detect Features
    if (nIds >= 0x00000001){
        cpuid(info, 0x00000001);
        s->HW_MMX    = (info[3] & ((int)1 << 23)) != 0;
        s->HW_SSE    = (info[3] & ((int)1 << 25)) != 0;
        s->HW_SSE2   = (info[3] & ((int)1 << 26)) != 0;
        s->HW_SSE3   = (info[2] & ((int)1 <<  0)) != 0;

        s->HW_SSSE3  = (info[2] & ((int)1 <<  9)) != 0;
        s->HW_SSE41  = (info[2] & ((int)1 << 19)) != 0;
        s->HW_SSE42  = (info[2] & ((int)1 << 20)) != 0;
        s->HW_AES    = (info[2] & ((int)1 << 25)) != 0;

        s->HW_AVX    = (info[2] & ((int)1 << 28)) != 0;
        s->HW_FMA3   = (info[2] & ((int)1 << 12)) != 0;

        s->HW_RDRAND = (info[2] & ((int)1 << 30)) != 0;
    }
    if (nIds >= 0x00000007){
        cpuid(info, 0x00000007);
        s->HW_AVX2         = (info[1] & ((int)1 <<  5)) != 0;

        s->HW_BMI1         = (info[1] & ((int)1 <<  3)) != 0;
        s->HW_BMI2         = (info[1] & ((int)1 <<  8)) != 0;
        s->HW_ADX          = (info[1] & ((int)1 << 19)) != 0;
        s->HW_MPX          = (info[1] & ((int)1 << 14)) != 0;
        s->HW_SHA          = (info[1] & ((int)1 << 29)) != 0;
        s->HW_PREFETCHWT1  = (info[2] & ((int)1 <<  0)) != 0;

        s->HW_AVX512_F     = (info[1] & ((int)1 << 16)) != 0;
        s->HW_AVX512_CD    = (info[1] & ((int)1 << 28)) != 0;
        s->HW_AVX512_PF    = (info[1] & ((int)1 << 26)) != 0;
        s->HW_AVX512_ER    = (info[1] & ((int)1 << 27)) != 0;
        s->HW_AVX512_VL    = (info[1] & ((int)1 << 31)) != 0;
        s->HW_AVX512_BW    = (info[1] & ((int)1 << 30)) != 0;
        s->HW_AVX512_DQ    = (info[1] & ((int)1 << 17)) != 0;
        s->HW_AVX512_IFMA  = (info[1] & ((int)1 << 21)) != 0;
        s->HW_AVX512_VBMI  = (info[2] & ((int)1 <<  1)) != 0;
    }
    if (nExIds >= 0x80000001){
        cpuid(info, 0x80000001);
        s->HW_x64   = (info[3] & ((int)1 << 29)) != 0;
        s->HW_ABM   = (info[2] & ((int)1 <<  5)) != 0;
        s->HW_SSE4a = (info[2] & ((int)1 <<  6)) != 0;
        s->HW_FMA4  = (info[2] & ((int)1 << 16)) != 0;
        s->HW_XOP   = (info[2] & ((int)1 << 11)) != 0;
    }
}

//     cpu_x86();
// 
//     void print() const;
//     static void print_host();
// 
//     static void cpuid(int32_t out[4], int32_t x);
//     static std::string get_vendor_string();
// 
//     static void print(const char* label, bool yes);
// 
//     static bool detect_OS_x64();
//     static bool detect_OS_AVX();
//     static bool detect_OS_AVX512();
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#endif