/*
Maths.h
Created on: 2021-Mar-13
Joe Filbrun
*/

// Maths Operaton Chices
#define MATHS_CHOICE_MIN 1
#define MATHS_CHOICE_MAX 2
#define MATHS_CHOICE_MEAN 3
#define MATHS_CHOICE_DIV 4
#define MATHS_CHOICE_INV 5
#define MATHS_CHOICE_MOD 6
#define MATHS_CHOICE_TANH 7
#define MATHS_CHOICE_ATAN 8
#define MATHS_CHOICE_INLV 9

#pragma once

#include <od/objects/Object.h>
#include <vector> 

class Maths : public od::Object
{
public:
  Maths();
   ~Maths();

#ifndef SWIGLUA
    virtual void process();
    od::Inlet mA{"a"};
    od::Inlet mB{"b"};
    od::Outlet mOutput{"Out"};
    od::Option mOperation{"Operation", MATHS_CHOICE_MIN};
#endif

    // void setVaults(int, float);
    // float getVaults(int);

protected:
  bool interleave = true;


};