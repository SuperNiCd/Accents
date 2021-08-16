%module Accents_libAccents
%include <od/glue/mod.cpp.swig>

%{

#undef SWIGLUA

#include <./VoltageVault.h>
#include <./Maths.h>
#include <./PointsEG.h>
#include <./Bitwise.h>
#include <./Tuner.h>
#include <./TunerGraphic.h>
#include <./TunerGraphicSub.h>


#define SWIGLUA

%}

%include <./VoltageVault.h>
%include <./Maths.h>
%include <./PointsEG.h>
%include <./Bitwise.h>
%include <./Tuner.h>
%include <./TunerGraphic.h>
%include <./TunerGraphicSub.h>
