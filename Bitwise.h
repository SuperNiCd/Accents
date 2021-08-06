/*
Bitwise.h
Created on: 2021-Mar-28
Joe Filbrun
*/

// Bitwise Operaton Chices
#define BITWISE_CHOICE_AONLY 1
#define BITWISE_CHOICE_BONLY 2
#define BITWISE_CHOICE_AND 3
#define BITWISE_CHOICE_OR 4
#define BITWISE_CHOICE_XOR 5
#define BITWISE_CHOICE_NAND 6
#define BITWISE_CHOICE_NOR 7
#define BITWISE_CHOICE_XNOR 8

#pragma once

#include <od/objects/Object.h>

class Bitwise : public od::Object
{
public:
  Bitwise();
   ~Bitwise();

#ifndef SWIGLUA
    virtual void process();
    od::Inlet mA{"a"};
    od::Inlet mB{"b"};
    od::Outlet mOutput{"Out"};
    od::Option mOperation{"Operation", BITWISE_CHOICE_AONLY};
#endif

protected:
    int aVal, bVal, opVal = 0;
    float outVal = 0.0f;
};