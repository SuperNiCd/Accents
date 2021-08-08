%module Accents_libAccents
%include <od/glue/mod.cpp.swig>

%{

#undef SWIGLUA

#include </home/joe/Accents/VoltageVault.h>
#include </home/joe/Accents/Maths.h>
#include </home/joe/Accents/PointsEG.h>
#include </home/joe/Accents/Bitwise.h>

	
#define SWIGLUA

%}

%include </home/joe/Accents/VoltageVault.h>
%include </home/joe/Accents/Maths.h>
%include </home/joe/Accents/PointsEG.h>
%include </home/joe/Accents/Bitwise.h>
